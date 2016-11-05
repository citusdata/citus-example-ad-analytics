class ImpressionDailyRollup < ActiveRecord::Base
  acts_as_distributed :account

  belongs_to :ad
end
