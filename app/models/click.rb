class Click < ActiveRecord::Base
  include PostgresCopyFromClient
  include FixCompositeKeyInsert

  self.primary_keys = :click_id, :ad_id

  belongs_to :ad, counter_cache: true, touch: true
end
