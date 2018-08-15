class SeriesController < ApplicationController
  def index
    @series = Series.all.order(topic_updated_at: :desc)
  end

  def show
    @s = Series.find_by(sid: params[:id])
    @topics = Topic.where(series_id: @s._id)
  end
end
