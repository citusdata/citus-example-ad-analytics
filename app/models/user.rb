class User < ActiveRecord::Base
  belongs_to :company

  devise :database_authenticatable, :registerable, :validatable
end
