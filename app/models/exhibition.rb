class Exhibition < ActiveRecord::Base
  has_many :panels
  has_many :items, :through => :panels, :order => 'panels.position'
  
  translates :title, :caption, :introduction, :conclusion, :author, :display_date
  globalize_accessors :fa, :en
  default_scope :include => [:translations]
end
