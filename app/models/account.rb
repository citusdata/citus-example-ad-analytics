class Account < ActiveRecord::Base
  acts_as_distributed :account

  devise :database_authenticatable, :registerable, :validatable

  has_many :campaigns
end
