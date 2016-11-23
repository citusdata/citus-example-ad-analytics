class CampaignsController < ApplicationController
  def index
    @campaigns = current_account.campaigns.includes(:ads)

    # Load historic COUNT from the roll-up tables
    #
    # Everything thats older than today is assumed to be rolled-up
    @impressions_by_campaign = Hash[Impression.connection.select_rows(
      %{SELECT ads.campaign_id, SUM(count)
         FROM ads
         JOIN impression_daily_rollups idr ON (ads.id = ad_id AND ads.account_id = idr.account_id)
        WHERE ads.campaign_id IN (#{@campaigns.map(&:id).join(',')})
              AND ads.account_id = #{current_account.id}
              AND date < now()::date
        GROUP BY ads.campaign_id},
    ).map {|k,v| [k.to_i, v.to_i] }]

    # Load count of recent data from the actual live table
    Impression.connection.select_rows(
      %{SELECT ads.campaign_id, COUNT(*)
         FROM ads
         JOIN impressions i ON (ads.id = ad_id AND ads.account_id = i.account_id)
        WHERE ads.campaign_id IN (#{@campaigns.map(&:id).join(',')})
              AND ads.account_id = #{current_account.id}
              AND seen_at > now()::date
        GROUP BY ads.campaign_id}).each do |campaign_id, recent_count|
      @impressions_by_campaign[campaign_id.to_i] ||= 0
      @impressions_by_campaign[campaign_id.to_i] += recent_count.to_i
    end

    @clicks_by_campaign = Hash[Click.connection.select_rows(
      %{SELECT ads.campaign_id, SUM(count)
         FROM ads
         JOIN click_daily_rollups cdr ON (ads.id = ad_id AND ads.account_id = cdr.account_id)
        WHERE ads.campaign_id IN (#{@campaigns.map(&:id).join(',')})
              AND ads.account_id = #{current_account.id}
              AND date < now()::date
        GROUP BY ads.campaign_id},
    ).map {|k,v| [k.to_i, v.to_i] }]

    Click.connection.select_rows(
      %{SELECT ads.campaign_id, COUNT(*)
         FROM ads
         JOIN clicks c ON (ads.id = ad_id AND ads.account_id = c.account_id)
        WHERE ads.campaign_id IN (#{@campaigns.map(&:id).join(',')})
              AND ads.account_id = #{current_account.id}
              AND clicked_at > now()::date
        GROUP BY ads.campaign_id}).each do |campaign_id, recent_count|
      @clicks_by_campaign[campaign_id.to_i] ||= 0
      @clicks_by_campaign[campaign_id.to_i] += recent_count.to_i
    end
  end

  def show
    @campaign = Campaign.find(params[:id])

    # Load historic COUNT from the roll-up tables
    #
    # Everything thats older than today is assumed to be rolled-up
    @impressions_by_ad = Hash[Impression.connection.select_rows(
      %{SELECT ad_id, SUM(count)
         FROM ads
         JOIN impression_daily_rollups idr ON (ads.id = ad_id AND ads.account_id = idr.account_id)
        WHERE ads.campaign_id = #{@campaign.id}
              AND ads.account_id = #{current_account.id}
              AND date < now()::date
        GROUP BY ad_id},
    ).map {|k,v| [k, v.to_i] }]

    # Load count of recent data from the actual live table
    Impression.connection.select_rows(
      %{SELECT ad_id, COUNT(*)
         FROM ads
         JOIN impressions i ON (ads.id = ad_id AND ads.account_id = i.account_id)
        WHERE ads.campaign_id = #{@campaign.id}
              AND seen_at > now()::date
        GROUP BY ad_id}).each do |ad_id, recent_count|
      @impressions_by_ad[ad_id] ||= 0
      @impressions_by_ad[ad_id] += recent_count.to_i
    end

    @clicks_by_ad = Hash[Click.connection.select_rows(
      %{SELECT ad_id, SUM(count)
         FROM ads
         JOIN click_daily_rollups cdr ON (ads.id = ad_id AND ads.account_id = cdr.account_id)
        WHERE ads.campaign_id = #{@campaign.id}
              AND ads.account_id = #{current_account.id}
              AND date < now()::date
        GROUP BY ad_id},
    ).map {|k,v| [k, v.to_i] }]

    Click.connection.select_rows(
      %{SELECT ad_id, COUNT(*)
         FROM ads
         JOIN clicks c ON (ads.id = ad_id AND ads.account_id = c.account_id)
        WHERE ads.campaign_id = #{@campaign.id}
              AND ads.account_id = #{current_account.id}
              AND clicked_at > now()::date
        GROUP BY ad_id}).each do |ad_id, recent_count|
      @clicks_by_ad[ad_id] ||= 0
      @clicks_by_ad[ad_id] += recent_count.to_i
    end
  end

  CTR_SQL = %(
    SELECT ads.name,
           extract(epoch from idr.date) AS day,
           CASE WHEN idr.count > 0 THEN COALESCE(cdr.count, 0) / idr.count::float
           ELSE NULL
           END AS ctr
      FROM ads
           JOIN impression_daily_rollups idr ON (idr.ad_id = ads.id AND idr.account_id = ads.account_id)
           JOIN click_daily_rollups cdr ON (idr.ad_id = cdr.ad_id AND idr.date = cdr.date AND cdr.account_id = ads.account_id)
     WHERE ads.campaign_id = %d AND idr.date BETWEEN '%s' AND '%s'
           AND ads.account_id = %d
     ORDER BY 2
  )

  def data
    campaign = Campaign.find(params[:id])

    start_ts = Time.at(params['start'].to_i).utc.beginning_of_day
    end_ts   = Time.at(params['end'].to_i).utc.end_of_day

    data = Hash[
      Impression.connection.select_all(format(CTR_SQL, campaign.id, start_ts, end_ts, current_account.id))
      .map { |v| [v['name'], v['day'].to_i, v['ctr'].to_f * 100] }
      .group_by { |v| v[0] }
      .map { |k, v| [k, v.map {|vv| [vv[1], vv[2]] }] }
    ]

    render json: Hash[data], callback: params[:callback]
  end
end
