# encoding: UTF-8
module Api
  class TokensController < ApplicationController
    protect_from_forgery with: :null_session

    # POST /api/token
    # Params: { email, password }
    # Returns: { token: "..." }
    def create
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        token = user.issue_api_token!
        render json: { token: token }, status: :created
      else
        render json: { error: 'Invalid credentials' }, status: :unauthorized
      end
    end

    # DELETE /api/token
    # Requires Bearer auth; revokes token
    def destroy
      user = authenticate_by_bearer
  return if performed?
      user.revoke_api_token!
      head :no_content
    end

    private

    def authenticate_by_bearer
      auth = request.headers['Authorization']
      scheme, value = auth.to_s.split(' ', 2)
      unless scheme&.casecmp('Bearer')&.zero? && (user = User.authenticate_api_token(value))
        render json: { error: 'Unauthorized' }, status: :unauthorized and return
      end
      user
    end
  end
end
