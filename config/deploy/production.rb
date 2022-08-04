# typed: false
# frozen_string_literal: true

set :stage, :production

role :app, %w[deploy@173.255.208.251]
role :web, %w[deploy@173.255.208.251]
role :db,  %w[deploy@173.255.208.251]
