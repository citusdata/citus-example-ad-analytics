class CampaignsController < ApplicationController
  def index
  end

  def show
    @campaign = Campaign.find(params[:id])
  end

  def stats
    @campaign = Campaign.find(params[:id])

    start_ts = Time.at(params['start'].to_i).utc.beginning_of_day
    end_ts   = Time.at(params['end'].to_i).utc.end_of_day

    impressions_by_day = Impression.where(seen_at: start_ts..end_ts, ad_id: @campaign.ad_ids)
                         .order("2").group("extract(epoch from date_trunc('day', seen_at))").count

    clicks_by_day = Click.where(clicked_at: start_ts..end_ts, ad_id: @campaign.ad_ids)
                    .order("2").group("extract(epoch from date_trunc('day', clicked_at))").count

    ctr_by_day = {}
    impressions_by_day.each do |day, impressions|
      ctr_by_day[day] = (clicks_by_day[day] || 0) / impressions.to_f * 100
    end

    data = {
      "Impressions" => impressions_by_day.to_a,
      "Clicks" => clicks_by_day.to_a,
      "Click-Through Rate" => ctr_by_day.to_a,
    }
    render json: data, callback: params[:callback]
  end
end
