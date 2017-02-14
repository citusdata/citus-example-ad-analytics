class ImpressionDailyRollup < ActiveRecord::Base
  multi_tenant :company

  belongs_to :ad
end
