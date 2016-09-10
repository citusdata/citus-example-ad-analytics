class Ad < ActiveRecord::Base
  self.primary_keys = :id

  acts_as_distributed partition_column: :id

  belongs_to :campaign
  has_many :clicks, dependent: :delete_all
  has_many :impressions, dependent: :delete_all
end
