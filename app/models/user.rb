# encoding: UTF-8
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
end
