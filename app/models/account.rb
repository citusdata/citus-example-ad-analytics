class Account < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :validatable

  has_many :campaigns
end
