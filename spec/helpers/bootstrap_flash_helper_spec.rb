# typed: false
# frozen_string_literal: true

require "spec_helper"

describe BootstrapFlashHelper do
  describe "#bootstrap_flash" do
    it "converts notice type to success" do
      flash[:notice] = "Operation successful"
      result = helper.bootstrap_flash
      expect(result).to include("alert-success")
      expect(result).to include("Operation successful")
    end

    it "converts alert type to danger" do
      flash[:alert] = "Something went wrong"
      result = helper.bootstrap_flash
      expect(result).to include("alert-danger")
      expect(result).to include("Something went wrong")
    end

    it "converts error type to danger" do
      flash[:error] = "Error occurred"
      result = helper.bootstrap_flash
      expect(result).to include("alert-danger")
      expect(result).to include("Error occurred")
    end

    it "handles info type" do
      flash[:info] = "FYI"
      result = helper.bootstrap_flash
      expect(result).to include("alert-info")
      expect(result).to include("FYI")
    end

    it "handles warning type" do
      flash[:warning] = "Be careful"
      result = helper.bootstrap_flash
      expect(result).to include("alert-warning")
      expect(result).to include("Be careful")
    end

    it "skips blank messages" do
      flash[:notice] = ""
      result = helper.bootstrap_flash
      expect(result).to be_empty
    end

    it "ignores unsupported alert types" do
      flash[:custom] = "Custom message"
      result = helper.bootstrap_flash
      expect(result).to be_empty
    end

    it "handles multiple messages" do
      flash[:notice] = "First message"
      flash[:alert] = "Second message"
      result = helper.bootstrap_flash
      expect(result).to include("First message")
      expect(result).to include("Second message")
    end

    it "includes close button" do
      flash[:notice] = "Dismissible"
      result = helper.bootstrap_flash
      expect(result).to include("&times;")
      expect(result).to include('data-dismiss="alert"')
    end

    it "applies custom CSS class from options" do
      flash[:notice] = "Custom styled"
      result = helper.bootstrap_flash(class: "my-custom-class")
      expect(result).to include("my-custom-class")
    end
  end
end
