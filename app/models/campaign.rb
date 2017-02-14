class Campaign < ActiveRecord::Base
  multi_tenant :company

  has_many :ads

  def impressions
    Impression.where(ad: Ad.where(campaign_id: id).to_a)
  end

  def clicks
    Click.where(ad: Ad.where(campaign_id: id).to_a)
  end
end
