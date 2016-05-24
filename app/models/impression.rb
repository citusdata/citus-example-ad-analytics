class Impression < ActiveRecord::Base
  include DistributedCitusTable

  belongs_to :ad
end
