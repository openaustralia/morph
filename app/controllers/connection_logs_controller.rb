class ConnectionLogsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
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
  end
end
