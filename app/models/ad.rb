class Ad < ActiveRecord::Base
  include DistributedTable
  self.primary_key = :id

  belongs_to :campaign
  has_many :clicks
  has_many :impressions
end
