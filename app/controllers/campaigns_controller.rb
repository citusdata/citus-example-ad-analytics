class CampaignsController < ApplicationController
  def index
    @campaigns = Account.first.campaigns.includes(:ads)

    @impressions_by_campaign = Hash[Impression.connection.select_rows(
      %{SELECT ads.campaign_id, COUNT(*)
         FROM ads
         JOIN impressions ON (ads.id = ad_id)
        WHERE ads.campaign_id IN (#{@campaigns.map(&:id).join(',')})
        GROUP BY ads.campaign_id},
    ).map {|k,v| [k.to_i, v.to_i] }]

    @clicks_by_campaign = Hash[Click.connection.select_rows(
      %{SELECT ads.campaign_id, COUNT(*)
         FROM ads
         JOIN clicks ON (ads.id = ad_id)
        WHERE ads.campaign_id IN (#{@campaigns.map(&:id).join(',')})
        GROUP BY ads.campaign_id},
    ).map {|k,v| [k.to_i, v.to_i] }]
  end

  def show
    @campaign = Campaign.find(params[:id])
    @impressions_by_ad = Impression.joins(:ad).group(:ad_id).where(ads: { campaign_id: @campaign.id }).count
    @clicks_by_ad      = Click.joins(:ad).group(:ad_id).where(ads: { campaign_id: @campaign.id }).count
  end

  IMPRESSIONS_SQL = %(
    SELECT ads.name,
           extract(epoch from date_trunc('day', seen_at)) AS day,
           COUNT(impressions.id) AS impressions
      FROM ads
           JOIN impressions ON (ads.id = impressions.ad_id)
     WHERE ads.campaign_id = %d AND seen_at BETWEEN '%s' AND '%s'
     GROUP BY 1, 2
     ORDER BY 2
  )

  CLICKS_SQL = %(
    SELECT ads.name,
           extract(epoch from date_trunc('day', clicked_at)) AS day,
           COUNT(clicks.id) AS clicks
      FROM ads
           JOIN clicks ON (ads.id = clicks.ad_id)
     WHERE ads.campaign_id = %d AND clicked_at BETWEEN '%s' AND '%s'
     GROUP BY 1, 2
     ORDER BY 2
  )

  def data
    campaign = Campaign.find(params[:id])

    start_ts = Time.at(params['start'].to_i).utc.beginning_of_day
    end_ts   = Time.at(params['end'].to_i).utc.end_of_day

    impressions = Hash[
      Impression.connection.select_all(format(IMPRESSIONS_SQL, campaign.id, start_ts, end_ts))
      .map { |v| [[v['name'], v['day']], v['impressions'].to_i] }
    ]

    clicks = Hash[
      Click.connection.select_all(format(CLICKS_SQL, campaign.id, start_ts, end_ts))
      .map { |v| [[v['name'], v['day']], v['clicks'].to_i] }
    ]

    data = impressions.map { |k,v| [k[0], k[1].to_i, (clicks[k] || 0) / v.to_f * 100.0] }
    .group_by { |v| v[0] }
    .map { |k, v| [k, v.map {|vv| [vv[1], vv[2]] }] }

    render json: Hash[data], callback: params[:callback]
  end
end
