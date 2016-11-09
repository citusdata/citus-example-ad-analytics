class User < ActiveRecord::Base
  belongs_to :account

  devise :database_authenticatable, :registerable, :validatable
end
