# typed: false
# frozen_string_literal: true

require "spec_helper"
require "open3"

describe "lib/morph/limit_output.rb" do # rubocop:disable RSpec/DescribeClass
  let(:script_path) { Rails.root.join("lib/morph/limit_output.rb") }

  it "passes through output under the limit" do
    stdout, stderr, status = Open3.capture3(
      "ruby", script_path.to_s, "10", "echo 'hello world'"
    )
    expect(stdout).to eq("hello world\n")
    expect(stderr).to be_empty
    expect(status.exitstatus).to eq(0)
  end

  it "truncates output over the limit" do
    command = "ruby -e '5.times { puts \"line\" }'"
    stdout, stderr, status = Open3.capture3(
      "ruby", script_path.to_s, "3", command
    )
    expect(stdout.lines.count).to eq(3)
    expect(stderr).to include("Too many lines of output!")
    expect(status.exitstatus).to eq(0)
  end

  it "allows unlimited output when limit is 0" do
    command = "ruby -e '100.times { puts \"line\" }'"
    stdout, stderr, status = Open3.capture3(
      "ruby", script_path.to_s, "0", command
    )
    expect(stdout.lines.count).to eq(100)
    expect(stderr).to be_empty
    expect(status.exitstatus).to eq(0)
  end

  it "preserves command exit status" do
    _stdout, _stderr, status = Open3.capture3(
      "ruby", script_path.to_s, "10", "ruby -e 'exit 42'"
    )
    expect(status.exitstatus).to eq(42)
  end

  it "handles stderr output" do
    command = "ruby -e 'STDERR.puts \"error message\"'"
    stdout, stderr, status = Open3.capture3(
      "ruby", script_path.to_s, "10", command
    )
    expect(stdout).to be_empty
    expect(stderr).to eq("error message\n")
    expect(status.exitstatus).to eq(0)
  end

  it "exits with error when max_lines not provided" do
    _, stderr, status = Open3.capture3(
      "ruby", script_path.to_s
    )
    expect(stderr).to include("Please give me the maximum number of lines")
    expect(status.exitstatus).not_to eq(0)
  end

  it "exits with error when command not provided" do
    _, stderr, status = Open3.capture3(
      "ruby", script_path.to_s, "10"
    )
    expect(stderr).to include("Please give me a command to run")
    expect(status.exitstatus).not_to eq(0)
  end
end
