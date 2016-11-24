class ClickDailyRollup < ActiveRecord::Base
  multi_tenant :account

  belongs_to :ad
end
