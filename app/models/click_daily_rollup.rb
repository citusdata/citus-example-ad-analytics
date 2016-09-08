class ClickDailyRollup < ActiveRecord::Base
  include FixCompositeKeyInsert

  self.primary_keys = :ad_id, :date

  belongs_to :ad
end
