class ApplicationController < ActionController::API
before_action :authorize_request
 include ActionController::Cookies 
 
def authorize_request
  token = cookies.signed[:jwt] || request.headers['Authorization']&.split(' ')&.last
  Rails.logger.info "Token received: #{token.inspect}"
  decoded = JsonWebToken.decode(token)
  Rails.logger.info "Decoded: #{decoded.inspect}"
  @current_user = User.find(decoded[:user_id]) if decoded
rescue => e
  Rails.logger.error e.message
  render json: { error: "Unauthorized" }, status: :unauthorized
end


end
