# typed: false
# frozen_string_literal: true

require "spec_helper"

describe OwnersHelper do
  describe "#owner_image" do
    let(:user) { create(:user, nickname: "test-user", gravatar_url: "https://gravatar.com/avatar/test") }
    let(:organization) { create(:organization, nickname: "test-org", gravatar_url: "https://gravatar.com/avatar/org") }

    it "generates image tag with correct size" do
      result = helper.owner_image(user, size: 50)
      expect(result).to include("https://gravatar.com/avatar/test")
      expect(result).to include('width="50"')
      expect(result).to include('height="50"')
    end

    it "adds img-circle class for users" do
      result = helper.owner_image(user, size: 50)
      expect(result).to include("img-circle")
    end

    it "does not add img-circle class for organizations" do
      result = helper.owner_image(organization, size: 50)
      expect(result).not_to include("img-circle")
    end

    it "adds tooltip by default" do
      result = helper.owner_image(user, size: 50)
      expect(result).to include("has-tooltip")
      expect(result).to include('data-placement="bottom"')
      expect(result).to include('data-container="body"')
    end

    it "does not add tooltip when show_tooltip is false" do
      result = helper.owner_image(user, size: 50, show_tooltip: false)
      expect(result).not_to include("has-tooltip")
      expect(result).not_to include("data-placement")
    end

    it "uses custom tooltip text when provided" do
      result = helper.owner_image(user, size: 50, tooltip_text: "Custom tooltip")
      expect(result).to include('data-title="Custom tooltip"')
      expect(result).to include('data-html="false"')
    end

    it "uses owner_tooltip_content when no custom tooltip provided" do
      user.name = "Test User"
      result = helper.owner_image(user, size: 50)
      expect(result).to include("Test User")
      expect(result).to include("test-user")
      expect(result).to include('data-html="true"')
    end

    it "sets alt text to owner nickname" do
      result = helper.owner_image(user, size: 50)
      expect(result).to include('alt="test-user"')
    end

    it "returns nil when owner has no gravatar_url" do
      user.gravatar_url = nil
      result = helper.owner_image(user, size: 50)
      expect(result).to be_nil
    end
  end

  describe "#owner_tooltip_content" do
    let(:owner) { create(:user, nickname: "test-user") }

    it "includes name and nickname when name is present" do
      owner.name = "Test User"
      result = helper.owner_tooltip_content(owner)
      expect(result).to include("<h4>Test User</h4>")
      expect(result).to include("<h5>test-user</h5>")
    end

    it "includes only nickname when name is absent" do
      owner.name = nil
      result = helper.owner_tooltip_content(owner)
      expect(result).to eq("<h4>test-user</h4>")
    end

    it "escapes HTML in name" do
      owner.name = "<script>alert('xss')</script>"
      result = helper.owner_tooltip_content(owner)
      expect(result).not_to include("<script>")
      expect(result).to include("&lt;script&gt;")
    end

    it "escapes HTML in nickname" do
      owner.nickname = "<script>alert('xss')</script>"
      result = helper.owner_tooltip_content(owner)
      expect(result).not_to include("<script>alert")
      expect(result).to include("&lt;script&gt;")
    end
  end
end
