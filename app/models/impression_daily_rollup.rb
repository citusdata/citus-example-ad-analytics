class ImpressionDailyRollup < ActiveRecord::Base
  include DistributedTable
  self.primary_keys = :ad_id, :date

  belongs_to :ad
end
