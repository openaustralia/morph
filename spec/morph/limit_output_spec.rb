# typed: false
# frozen_string_literal: true

require "spec_helper"
require "morph/limit_output"

describe Morph::LimitOutput do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  def run_limit(*args)
    described_class.run(args, stdout_io: stdout, stderr_io: stderr)
  end

  it "passes through output under the limit" do
    status = run_limit("10", "echo 'hello world'")
    expect(stdout.string).to eq("hello world\n")
    expect(stderr.string).to be_empty
    expect(status).to eq(0)
  end

  it "truncates output over the limit" do
    command = "ruby -e '5.times { puts \"line\" }'"
    status = run_limit("3", command)
    expect(stdout.string.lines.count).to eq(3)
    expect(stderr.string).to include("Too many lines of output!")
    expect(status).to eq(0)
  end

  it "allows unlimited output when limit is 0" do
    command = "ruby -e '100.times { puts \"line\" }'"
    status = run_limit("0", command)
    expect(stdout.string.lines.count).to eq(100)
    expect(stderr.string).to be_empty
    expect(status).to eq(0)
  end

  it "preserves command exit status" do
    status = run_limit("10", "ruby -e 'exit 42'")
    expect(status).to eq(42)
  end

  it "handles stderr output" do
    command = "ruby -e 'STDERR.puts \"error message\"'"
    status = run_limit("10", command)
    expect(stdout.string).to be_empty
    expect(stderr.string).to eq("error message\n")
    expect(status).to eq(0)
  end

  it "exits with error when max_lines not provided" do
    status = run_limit # empty args
    expect(stderr.string).to include("Please give me the maximum number of lines")
    expect(status).not_to eq(0)
  end

  it "exits with error when command not provided" do
    status = run_limit("10")
    expect(stderr.string).to include("Please give me a command to run")
    expect(status).not_to eq(0)
  end
end
