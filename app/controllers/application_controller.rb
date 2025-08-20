class ApplicationController < ActionController::Base
    # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
    allow_browser versions: :modern
    helper_method :current_user, :user_signed_in?

    private

    def current_user
      return @current_user if defined?(@current_user)

      if session[:user_id]
        @current_user = User.find_by(id: session[:user_id])
      elsif cookies.signed[:user_id] && cookies[:remember_token]
        user = User.find_by(id: cookies.signed[:user_id])
        if user&.authenticated_remember?(cookies[:remember_token])
          session[:user_id] = user.id
          @current_user = user
        end
      end
      @current_user
    end

    def user_signed_in?
      current_user.present?
    end

    def require_login
      unless user_signed_in?
        redirect_to login_path, alert: 'ログインしてください'
      end
    end
end
