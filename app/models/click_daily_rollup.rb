class ClickDailyRollup < ActiveRecord::Base
  self.primary_keys = :ad_id, :date

  acts_as_distributed partition_column: :ad_id

  belongs_to :ad
end
