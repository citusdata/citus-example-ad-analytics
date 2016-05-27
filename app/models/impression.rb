class Impression < ActiveRecord::Base
  include DistributedTable
  self.primary_keys = :id, :ad_id

  belongs_to :ad
end
