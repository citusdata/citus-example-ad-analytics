class Impression < ActiveRecord::Base
  self.primary_keys = :impression_id, :ad_id

  acts_as_distributed partition_column: :ad_id

  belongs_to :ad, counter_cache: true, touch: true
end
