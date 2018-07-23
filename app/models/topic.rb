class Topic
  include Mongoid::Document
  field :tid, type: String
  field :title, type: String
  field :topic_number, type: String
  field :summary, type: String
  field :thumbnail_url, type: String
  field :viewer_url, type: String
  field :deleted, type: Mongoid::Boolean, default: false
  #embedded_in :series
  #embedded_in :store
  belongs_to :series
  belongs_to :store
  include Mongoid::Document
  include Mongoid::Timestamps
end
