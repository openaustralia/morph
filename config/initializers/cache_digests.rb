Rails.application.config.to_prepare do
  require 'action_view/dependency_tracker'

  ActionView::DependencyTracker.register_tracker :haml, RenderSync::ERBTracker
  ActionView::DependencyTracker.register_tracker :erb, RenderSync::ERBTracker
end
