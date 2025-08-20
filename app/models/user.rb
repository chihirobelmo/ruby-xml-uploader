# encoding: UTF-8
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true

  # Remember me helpers
  attr_accessor :remember_token

  def self.new_token
    SecureRandom.urlsafe_base64(32)
  end

  def self.digest(token)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(token, cost: cost)
  end

  def remember!
    self.remember_token = User.new_token
    update!(remember_digest: User.digest(remember_token))
  end

  def forget!
    update!(remember_digest: nil)
  end

  def authenticated_remember?(token)
    return false if remember_digest.blank?
    BCrypt::Password.new(remember_digest).is_password?(token)
  end
end
