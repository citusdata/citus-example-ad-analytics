class Click < ActiveRecord::Base
  multi_tenant :company

  belongs_to :ad, counter_cache: true, touch: true
end
