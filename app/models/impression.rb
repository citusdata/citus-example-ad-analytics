class Impression < ActiveRecord::Base
  acts_as_distributed :account

  belongs_to :ad, counter_cache: true, touch: true
end
