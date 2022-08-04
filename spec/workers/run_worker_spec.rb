# typed: false
# frozen_string_literal: true

require "spec_helper"

describe RunWorker do
  let(:user) { create(:user) }

  it "calls the runner" do
    run = Run.create!(owner: user)
    runner = instance_double(Morph::Runner, synch_and_go!: nil)
    allow(Morph::Runner).to receive(:new).with(run).and_return(runner)

    described_class.new.perform(run.id)

    expect(runner).to have_received(:synch_and_go!)
  end

  it "does nothing if the run does not exist anymore" do
    described_class.new.perform(123456)
  end

  context "with no container for run 123456" do
    before do
      Morph::DockerUtils.find_all_containers_with_label_and_value(Morph::Runner.run_label_key, "123456").each(&:delete)
    end

    after do
      Morph::DockerUtils.find_all_containers_with_label_and_value(Morph::Runner.run_label_key, "123456").each(&:delete)
    end

    it "raises an exception if we already have the maximum number of running containers" do
      run = Run.create!(owner: user, id: 123456)
      allow(Morph::Runner).to receive(:available_slots).and_return(0)
      expect { described_class.new.perform(run.id) }.to raise_error RunWorker::NoRemainingSlotsError
    end

    it "does not raise an exception if we are finishing off an already running container", docker: true do
      run = Run.create!(owner: user, id: 123456)
      allow(Morph::Runner).to receive(:available_slots).and_return(0)
      Docker::Container.create(
        "Cmd" => ["ls"],
        "Image" => "openaustralia/buildstep",
        "Labels" => { Morph::Runner.run_label_key => "123456" }
      )
      expect { described_class.new.perform(run.id) }.not_to raise_error
    end
  end
end
