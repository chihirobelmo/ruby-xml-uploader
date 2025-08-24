module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_bearer!
    attr_reader :current_api_user
    helper_method :current_api_user if respond_to?(:helper_method)
  end

  private

  def authenticate_bearer!
    token = bearer_token_from_header
    unless token && (@current_api_user = User.authenticate_api_token(token))
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def bearer_token_from_header
    auth = request.headers['Authorization']
    return nil if auth.blank?
    scheme, value = auth.to_s.split(' ', 2)
    return value if scheme&.casecmp('Bearer')&.zero?
    nil
  end
end
