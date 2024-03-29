# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Admin::SidekiqController`.
# Please instead update this file by running `bin/tapioca dsl Admin::SidekiqController`.

class Admin::SidekiqController
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
    include ::ActiveAdmin::ViewHelpers::ActiveAdminApplicationHelper
    include ::ActiveAdmin::ViewHelpers::AutoLinkHelper
    include ::ActiveAdmin::ViewHelpers::BreadcrumbHelper
    include ::ActiveAdmin::ViewHelpers::DisplayHelper
    include ::MethodOrProcHelper
    include ::ActiveAdmin::ViewHelpers::SidebarHelper
    include ::ActiveAdmin::ViewHelpers::FormHelper
    include ::ActiveAdmin::ViewHelpers::TitleHelper
    include ::ActiveAdmin::ViewHelpers::ViewFactoryHelper
    include ::ActiveAdmin::ViewHelpers::FlashHelper
    include ::ActiveAdmin::ViewHelpers::ScopeNameHelper
    include ::ActiveAdmin::Filters::ViewHelper
    include ::ActiveAdmin::ViewHelpers
  end

  class HelperProxy < ::ActionView::Base
    include HelperMethods
  end
end
