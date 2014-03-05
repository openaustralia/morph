require 'action_view/dependency_tracker'

ActionView::DependencyTracker.register_tracker :haml, Sync::ERBTracker
ActionView::DependencyTracker.register_tracker :erb, Sync::ERBTracker
