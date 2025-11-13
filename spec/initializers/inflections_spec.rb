# typed: false
# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "config/initializer for ActiveSupport::Inflector" do
  describe "hero/heroes pluralization required for Plan name" do
    it "pluralizes 'hero' as 'heroes'" do
      expect("hero".pluralize).to eq("heroes")
    end

    it "pluralizes 'Hero' as 'Heroes'" do
      expect("Hero".pluralize).to eq("Heroes")
    end

    it "singularizes 'heroes' as 'hero'" do
      expect("heroes".singularize).to eq("hero")
    end

    it "singularizes 'Heroes' as 'Hero'" do
      expect("Heroes".singularize).to eq("Hero")
    end
  end
end
# rubocop:enable RSpec/DescribeClass
