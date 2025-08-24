# encoding: UTF-8
class User < ApplicationRecord
  has_secure_password
  has_many :xml_documents, dependent: :nullify

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true, length: { maximum: 50 }

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

  # --- API Token (Bearer) ---
  # Store only a digest of the API token
  # Columns: api_token_digest:string, api_token_generated_at:datetime

  # Issue a new API token, return the raw token (show once)
  def issue_api_token!
    raw = User.new_token
    update!(api_token_digest: User.digest(raw), api_token_generated_at: Time.current)
    raw
  end

  # Revoke API token
  def revoke_api_token!
    update!(api_token_digest: nil, api_token_generated_at: nil)
  end

  # Authenticate provided raw token, return user if valid
  def self.authenticate_api_token(raw)
    return nil if raw.blank?
    where.not(api_token_digest: nil).find_each do |user|
      begin
        return user if BCrypt::Password.new(user.api_token_digest).is_password?(raw)
      rescue BCrypt::Errors::InvalidHash
        next
      end
    end
    nil
  end
end
