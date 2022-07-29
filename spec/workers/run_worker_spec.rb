# frozen_string_literal: true

require "spec_helper"

describe RunWorker do
  it "calls the runner" do
    run = Run.create!
    runner = double
    expect(Morph::Runner).to receive(:new).with(run).and_return(runner)
    expect(runner).to receive(:synch_and_go!)

    described_class.new.perform(run.id)
  end

  it "does nothing if the run does not exist anymore" do
    described_class.new.perform(123456)
  end

  context do
    before do
      Morph::DockerUtils.find_all_containers_with_label_and_value(Morph::Runner.run_label_key, "123456").each(&:delete)
    end

    after do
      Morph::DockerUtils.find_all_containers_with_label_and_value(Morph::Runner.run_label_key, "123456").each(&:delete)
    end

    it "raises an exception if we already have the maximum number of running containers" do
      run = Run.create!(id: 123456)
      expect(Morph::Runner).to receive(:available_slots).and_return(0)
      expect { described_class.new.perform(run.id) }.to raise_error RunWorker::NoRemainingSlotsError
    end

    it "does not raise an exception if we are finishing off an already running container", docker: true do
      run = Run.create!(id: 123456)
      expect(Morph::Runner).to receive(:available_slots).and_return(0)
      Docker::Container.create(
        "Cmd" => ["ls"],
        "Image" => "openaustralia/buildstep",
        "Labels" => { Morph::Runner.run_label_key => "123456" }
      )
      expect { described_class.new.perform(run.id) }.not_to raise_error
    end
  end
end
