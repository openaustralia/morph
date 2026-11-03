# typed: false
# frozen_string_literal: true

require "spec_helper"

describe RunWorker do
  let(:user) { create(:user) }

  it "calls the runner" do
    run = Run.create!(owner: user)
    runner = instance_double(Morph::Runner, synch_and_go_with_logging!: nil)
    allow(Morph::Runner).to receive(:new).with(run).and_return(runner)

    described_class.new.perform(run.id)

    expect(runner).to have_received(:synch_and_go_with_logging!)
  end

  it "does nothing if the run does not exist anymore" do
    described_class.new.perform(123456)
  end

  it "starts the run and does not re-enqueue it when one slot is free" do
    run = Run.create!(owner: user)
    runner = instance_double(Morph::Runner, container_for_run: nil, synch_and_go_with_logging!: nil)
    allow(Morph::Runner).to receive(:new).with(run).and_return(runner)
    allow(Morph::Runner).to receive(:available_slots).and_return(1)
    described_class.jobs.clear

    described_class.new.perform(run.id)

    expect(runner).to have_received(:synch_and_go_with_logging!)
    expect(described_class.jobs).to be_empty
  end

  context "with no container for run 123456" do
    before do
      Morph::DockerUtils.find_all_containers_with_label_and_value(Morph::Runner.run_label_key, "123456").each(&:delete)
    end

    after do
      Morph::DockerUtils.find_all_containers_with_label_and_value(Morph::Runner.run_label_key, "123456").each(&:delete)
    end

    context "when we already have the maximum number of running containers" do
      let(:run) { Run.create!(owner: user, id: 123456) }

      before do
        allow(Morph::Runner).to receive(:available_slots).and_return(0)
        described_class.jobs.clear
      end

      it "does not raise, so the retry and dead sets do not fill" do
        expect { described_class.new.perform(run.id) }.not_to raise_error
      end

      it "does not start the run" do
        runner = instance_double(Morph::Runner, container_for_run: nil, synch_and_go_with_logging!: nil)
        allow(Morph::Runner).to receive(:new).with(run).and_return(runner)
        described_class.new.perform(run.id)
        expect(runner).not_to have_received(:synch_and_go_with_logging!)
      end

      it "puts the same run back on the queue to try again shortly" do
        described_class.new.perform(run.id)
        expect(described_class.jobs.map { |j| [j["args"], j["at"]] }).to match(
          [[[run.id], be_within(5).of(Time.now.to_f + described_class::RETRY_DELAY)]]
        )
      end
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
