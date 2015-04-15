# Config for mini profiler
# https://github.com/MiniProfiler/rack-mini-profiler#configuration-options
Rack::MiniProfiler.config.start_hidden = true if Rails.env.development?
