class ConnectionLogsController < ApplicationController
  skip_before_filter :verify_authenticity_token

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
      domain
      ConnectionLog.create!(
        ip_address: params[:ip_address],
        domain_id: domain.id
      )

      render text: "Created"
    else
      render text: "Wrong API key", status: 401
    end
  end

  private

  def self.key
    ENV["MITMPROXY_SECRET"]
  end
end
