class CampaignsController < ApplicationController
  def index
    @campaigns = Account.first.campaigns.includes(:ads)
    @ad_id_to_campaign = Hash[@campaigns.flat_map { |c| c.ads.map { |a| [a.id, c.id] } }]

    @impressions_by_campaign = {}
    Impression.group(:ad_id).where(ad_id: @ad_id_to_campaign.keys).count.each do |ad_id, impressions|
      campaign_id = @ad_id_to_campaign[ad_id]
      @impressions_by_campaign[campaign_id] ||= 0
      @impressions_by_campaign[campaign_id] += impressions
    end

    @clicks_by_campaign = {}
    Click.group(:ad_id).where(ad_id: @ad_id_to_campaign.keys).count.each do |ad_id, clicks|
      campaign_id = @ad_id_to_campaign[ad_id]
      @clicks_by_campaign[campaign_id] ||= 0
      @clicks_by_campaign[campaign_id] += clicks
    end
  end

  def show
    @campaign = Campaign.find(params[:id])
    @impressions_by_ad = Impression.group(:ad_id).where(ad_id: @campaign.ads.map(&:id)).count
    @clicks_by_ad      = Click.group(:ad_id).where(ad_id: @campaign.ads.map(&:id)).count
  end

  IMPRESSIONS_SQL = %(
    SELECT ad_id,
           extract(epoch from date_trunc('day', seen_at)) AS day,
           COUNT(impressions.id) AS impressions
      FROM impressions
     WHERE (%s) AND seen_at BETWEEN '%s' AND '%s'
     GROUP BY 1, 2
     ORDER BY 2
  )

  CLICKS_SQL = %(
    SELECT ad_id,
           extract(epoch from date_trunc('day', clicked_at)) AS day,
           COUNT(clicks.id) AS clicks
      FROM clicks
     WHERE (%s) AND clicked_at BETWEEN '%s' AND '%s'
     GROUP BY 1, 2
     ORDER BY 2
  )

  def data
    campaign = Campaign.find(params[:id])

    ad_id_to_name = Hash[campaign.ads.map { |a| [a.id, a.name] }]
    ads_or_sql = campaign.ads.map { |a| format('ad_id = %d', a.id) }.join(' OR ')

    start_ts = Time.at(params['start'].to_i).utc.beginning_of_day
    end_ts   = Time.at(params['end'].to_i).utc.end_of_day

    impressions = Hash[
      Impression.connection.select_all(format(IMPRESSIONS_SQL, ads_or_sql, start_ts, end_ts))
      .map { |v| [[v['ad_id'], v['day']], v['impressions'].to_i] }
    ]

    clicks = Hash[
      Click.connection.select_all(format(CLICKS_SQL, ads_or_sql, start_ts, end_ts))
      .map { |v| [[v['ad_id'], v['day']], v['clicks'].to_i] }
    ]

    data = impressions.map { |k,v| [k[0], k[1].to_i, (clicks[k] || 0) / v.to_f * 100.0] }
    .group_by { |v| ad_id_to_name[v[0].to_i] }
    .map { |k, v| [k, v.map {|vv| [vv[1], vv[2]] }] }

    render json: Hash[data], callback: params[:callback]
  end
end
