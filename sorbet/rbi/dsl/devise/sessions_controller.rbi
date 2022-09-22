# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Devise::SessionsController`.
# Please instead update this file by running `bin/tapioca dsl Devise::SessionsController`.

class Devise::SessionsController
  sig { returns(HelperProxy) }
  def helpers; end

  module HelperMethods
    include ::Ransack::Helpers::FormHelper
    include ::ActionDispatch::Routing::PolymorphicRoutes
    include ::ActionDispatch::Routing::UrlFor
    include ::GeneratedUrlHelpersModule
    include ::GeneratedPathHelpersModule
    include ::ActionView::Helpers::NumberHelper
    include ::ActionView::Helpers::CaptureHelper
    include ::ActionView::Helpers::OutputSafetyHelper
    include ::ActionView::Helpers::TagHelper
    include ::ActionView::Helpers::TextHelper
    include ::ActionView::Helpers::UrlHelper
    include ::ActionView::Helpers::AssetUrlHelper
    include ::ActionView::Helpers::AssetTagHelper
    include ::ActionView::Helpers::DateHelper
    include ::ActionView::Helpers::SanitizeHelper
    include ::Kernel
    include ::ApplicationHelper
    include ::BootstrapFlashHelper
    include ::ERB::Util
    include ::StaticHelper
    include ::DocumentationHelper
    include ::OwnersHelper
    include ::RunsHelper
    include ::ScrapersHelper
    include ::SearchHelper
    include ::SupportersHelper
    include ::UsersHelper
    include ::RenderSync::ConfigHelper
    include ::FontAwesome::Rails::IconHelper
    include ::DeviseHelper
  end

  class HelperProxy < ::ActionView::Base
    include HelperMethods
  end
end
