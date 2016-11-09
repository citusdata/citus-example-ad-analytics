class AccountEmail < ActiveRecord::Base
  has_one :account

  validates :email, presence: true, uniqueness: true
end
