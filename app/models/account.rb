class Account < ActiveRecord::Base
  multi_tenant :account

  has_many :campaigns
  has_many :users
end
