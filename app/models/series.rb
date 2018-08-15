class Series
  include Mongoid::Document
  field :sid, type: String
  field :original_sid, type: String
  field :title, type: String
  field :author, type: String
  field :summary, type: String
  field :thumbnail_url, type: String
  field :topic_updated_at, type: DateTime
  field :deleted, type: Mongoid::Boolean, default: false
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :topics
end
