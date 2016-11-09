class Account < ActiveRecord::Base
  acts_as_distributed :account

  has_many :campaigns
  has_many :users
end
