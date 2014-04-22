class ConnectionLogsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    if ConnectionLogsController.key == params[:key]
      ConnectionLog.create(
        ip_address: params[:ip_address],
        method: params[:method],
        scheme: params[:scheme],
        host: params[:host],
        path: params[:path],
        request_size: params[:request_size],
        response_size: params[:response_size]
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
