class Subject < ActiveRecord::Base
  translates :name
  belongs_to :subject_type
  
  has_many :classifications
  has_many :items, :through => :classifications, :order => :position

  validates :name, :presence => true, :length =>{:maximum => 256}
  validates :publish, :presence => true

  default_scope :include => :translations

  # pagination code
  cattr_reader :per_page
  @@per_page = 50

  def self.select_list
    return self.all(:conditions => ['subject_translations.locale = ?', I18n.locale.to_s], :select => 'DISTINCT id, subject_translations.name', :order => 'subject_translations.name').map {|subject| [subject.name, subject.id]}
  end
end
