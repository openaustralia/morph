# typed: false
# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "config/initializer for Sentry" do
  it "initializes the SDK at boot" do
    expect(Sentry.initialized?).to be true
  end

  it "stays quiet when no DSN is configured, so tests and dev never report" do
    expect(Sentry.configuration.sending_allowed?).to be false
  end

  it "tags events with the running application version" do
    expect(Sentry.configuration.release).to eq APP_VERSION.strip
  end

  it "records Rails and HTTP breadcrumbs for error context" do
    expect(Sentry.configuration.breadcrumbs_logger)
      .to contain_exactly(:active_support_logger, :http_logger)
  end
end
# rubocop:enable RSpec/DescribeClass
