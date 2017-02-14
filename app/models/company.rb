class Company < ActiveRecord::Base
  multi_tenant :company

  has_many :campaigns
  has_many :users
end
