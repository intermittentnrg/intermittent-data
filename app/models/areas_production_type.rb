class AreasProductionType < ActiveRecord::Base
  belongs_to :area
  belongs_to :source_area, class_name: 'Area'
  belongs_to :production_type
  has_many :generation
  has_many :capacity
  has_many :unit
end
