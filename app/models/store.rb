class Store
  include Mongoid::Document
  field :name, type: String
  field :name_en, type: String
  has_many :topics
end
