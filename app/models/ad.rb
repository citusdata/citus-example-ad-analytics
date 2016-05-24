class Ad < ActiveRecord::Base
  include DistributedCitusTable

  belongs_to :campaign
  has_many :clicks
  has_many :impressions

  def self.with_transaction_returning_status
    puts 'YOLO'
    yield
  end
end
