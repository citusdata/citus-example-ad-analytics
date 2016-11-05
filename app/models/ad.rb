class Ad < ActiveRecord::Base
  acts_as_distributed :account

  belongs_to :campaign
  has_many :clicks, dependent: :delete_all
  has_many :impressions, dependent: :delete_all
end
