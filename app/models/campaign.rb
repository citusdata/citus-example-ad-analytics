class Campaign < ActiveRecord::Base
  acts_as_distributed :account
  self.primary_key = :id

  has_many :ads

  def impressions
    Impression.where(ad: Ad.where(campaign_id: id).to_a)
  end

  def clicks
    Click.where(ad: Ad.where(campaign_id: id).to_a)
  end
end
