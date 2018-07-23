class Store
  include Mongoid::Document
  field :name, type: String
  has_many :topics
end
