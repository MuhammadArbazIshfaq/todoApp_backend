class AuthController < ApplicationController
  include ActionController::Cookies
  skip_before_action :authorize_request, only: [:signup, :login]

def signup
    user = User.new(user_params)
   if user.save
  token = JsonWebToken.encode(user_id: user.id)
  cookies.signed[:jwt] = {
    value: token,
    httponly: true,
    secure: Rails.env.production?, # only true in production with HTTPS
    same_site: :strict
  }
  render json: { message: "Signup successful", user: user }, status: :created
else
  render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
end

  end

 def login
  user = User.find_by(email: params[:email])
  if user&.authenticate(params[:password])
    token = JsonWebToken.encode(user_id: user.id)

    # ✅ Set HttpOnly cookie instead of returning token
    cookies.signed[:jwt] = {
      value: token,
      httponly: true,                 # Not accessible by JS
      secure: Rails.env.production?,  # Only HTTPS in production
      same_site: :lax,                # Protects against CSRF
      expires: 24.hours.from_now
    }

    render json: { message: "Logged in successfully", user: user }, status: :ok
  else
    render json: { error: "Invalid email or password" }, status: :unauthorized
  end
end


  private

  def user_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
end
