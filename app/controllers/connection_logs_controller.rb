# typed: false
# frozen_string_literal: true

class ConnectionLogsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    if ConnectionLogsController.key == params[:key]

      domain = Domain.find_by(name: params[:host])
      if domain.nil?
        # In case another thread has created a record between the find above and
        # the create below we put an extra guard around it
        begin
          domain = Domain.create!(name: params[:host])
        rescue ActiveRecord::RecordNotUnique
          domain = Domain.find_by(name: params[:host])
        end
        UpdateDomainWorker.perform_async(domain.id)
      end

      ConnectionLog.create!(
        ip_address: params[:ip_address],
        domain_id: domain.id
      )

      render plain: "Created"
    else
      render plain: "Wrong API key", status: :unauthorized
    end
  end

  def self.key
    ENV.fetch("MITMPROXY_SECRET", nil)
  end
end
