class Click < ActiveRecord::Base
  multi_tenant :account

  belongs_to :ad, counter_cache: true, touch: true
end
