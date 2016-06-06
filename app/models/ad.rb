class Ad < ActiveRecord::Base
  belongs_to :campaign
  has_many :clicks
  has_many :impressions
end
