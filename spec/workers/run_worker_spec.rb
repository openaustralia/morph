require 'spec_helper'

describe RunWorker do
  it 'should call the runner' do
    run = Run.create!
    runner = double
    expect(Morph::Runner).to receive(:new).with(run).and_return(runner)
    expect(runner).to receive(:synch_and_go!)

    RunWorker.new.perform(run.id)
  end

  it 'should do nothing if the run does not exist anymore' do
    RunWorker.new.perform(123456)
  end
end
