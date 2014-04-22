class ConnectionLogsController < ApplicationController
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
  end
end
