class CampaignsController < ApplicationController
  def index
  end

  def show
    @campaign = Campaign.find(params[:id])
  end
end
