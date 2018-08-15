class SeriesController < ApplicationController
  def index
    @series = Series.all.order(topic_updated_at: :desc)
  end
end
