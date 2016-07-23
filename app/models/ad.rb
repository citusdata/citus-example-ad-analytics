class Ad < ActiveRecord::Base
  include PostgresCopyFromClient
  self.primary_keys = :id

  belongs_to :campaign
  has_many :clicks, dependent: :delete_all
  has_many :impressions, dependent: :delete_all
end
