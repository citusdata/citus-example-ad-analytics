class AdsController < ApplicationController
  def show
    @ad = Ad.find(params[:id])
  end
end
