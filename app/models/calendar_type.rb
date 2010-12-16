class CalendarType < ActiveRecord::Base
  has_many :items

  validates :name, :presence => true, :uniqueness => true
  validates :publish, :presence => true

  def self.select_list
    return self.all(:select => 'DISTINCT id, name', :order => 'name').map {|calendar_type| [calendar_type.name, calendar_type.id]}
  end
end
