class Click < ActiveRecord::Base
  include DistributedCitusTable

  belongs_to :ad
end
