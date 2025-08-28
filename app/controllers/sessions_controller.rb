# encoding: UTF-8
class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      if ActiveModel::Type::Boolean.new.cast(params[:remember_me])
        user.remember!
        cookies.permanent.signed[:user_id] = user.id
        cookies.permanent[:remember_token] = user.remember_token
      else
        forget(user)
      end
      redirect_to root_path, notice: 'Logged-In'
    else
      flash.now[:alert] = 'Wrong email or pass'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    forget(current_user)
    session.delete(:user_id)
    redirect_to root_path, notice: 'Logged-Out'
  end

  private

  def forget(user)
    return unless user
    user.forget!
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
end
