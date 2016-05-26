class Click < ActiveRecord::Base
  include DistributedCitusTable

  belongs_to :ad

  # acts_as_distributed through: :ad
end
