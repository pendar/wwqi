class Item < ActiveRecord::Base
  belongs_to :owner
  belongs_to :collection
  belongs_to :format
  belongs_to :medium
  belongs_to :place
  belongs_to :period, :counter_cache => true
  belongs_to :category
  belongs_to :calendar_type
  belongs_to :creator, :class_name => "Person", :foreign_key => :creator_id

  has_many :classifications
  has_many :images
  has_many :appearances
  has_many :people, :through => :appearances
  has_many :panels
  has_many :exhibitions, :through => :panels, :order => 'panels.position'
  has_many :clips, :order => :position
  has_many :subjects, :through => :classifications, :order => 'position'
  
  # globalize2 accessors 
  translates :title, :credit, :description, :display_date, :creator_label
  globalize_accessors :fa, :en
  default_scope :include => [:translations, :category]
  
  # pagination code
  cattr_reader :per_page
  @@per_page = 25
  
  # validations
  validates :title, :presence => true, :length => { :maximum => 255, :minimum => 3 }
  validates :pages, :presence => true, :numericality => { :greater_than => 0, :less_than => 10001 }
  validates :accession_num, :presence => true, :length => { :maximum => 255, :minimum => 3 }

  def self.recently_added_ids(limit=25)
    ids = []
    months = 1
    until ids.size >= limit || months > 12 do
      ids = Item.added_since_date(months, limit)
      months += 1
    end
    return ids
  end 
  
  def self.added_since_date(months=1, limit=25)
    ids = Item.find(:all, :select => 'items.id', :conditions => ["items.publish = ? AND item_translations.locale=? AND items.created_at >= ?", 1, I18n.locale.to_s, Time.now.months_ago(months)], :order => 'items.created_at DESC', :limit => limit).map { |item| item.id }
    return ids
  end   

  def self.most_popular(limit=100)
    if @popular_items.nil? || @popular_refreshed_at > 1.day.ago
      @popular_ids = Item.most_popular_ids(limit)
      unless @popular_ids.nil? || @popular_ids.empty?
        @popular_items = Item.find(:all, :conditions => "items.id IN (#{@popular_ids.join(",")}) AND items.publish = 1 AND item_translations.locale='#{I18n.locale.to_s}'", :limit => limit)
      else
        @popular_items = []
      end  
    end
    if @popular_items.size < limit
      @popular_items += Item.find(:all, :conditions => "items.publish = 1 AND item_translations.locale='#{I18n.locale.to_s}'", :limit => (limit - @popular_items.size))
    end
    @popular_refreshed_at = DateTime.now  
    return @popular_items
  end
  
  def self.most_popular_ids(limit=100)
    return Activity.find(:all, :group => 'item_id', :select => 'count(*) count, item_id', :conditions => "item_id IS NOT NULL", :order => 'count', :limit => limit).map { |ids| ids.item_id }
  end
  
  def self.recently_viewed(limit=8)
    if @recently_viewed_items.nil? || @recently_refreshed_at > 1.minute.ago
      @recently_viewed_ids = Item.most_recent_ids(limit)
      unless @recently_viewed_ids.nil? || @recently_viewed_ids.empty?
        @recently_viewed_items = Item.find(:all, :conditions => "items.id IN (#{@recently_viewed_ids.join(",")}) AND items.publish = 1 AND item_translations.locale='#{I18n.locale.to_s}'")
      else
        @recently_viewed_items = []
      end  
    end
    if @recently_viewed_items.size < limit
      @recently_viewed_items += Item.find(:all, :conditions => "items.publish = 1 AND item_translations.locale='#{I18n.locale.to_s}'", :limit => (limit - @recently_viewed_items.size))
    end  
    @recently_refreshed_at = DateTime.now
    return @recently_viewed_items
  end

  def self.most_recent_ids(limit=8)
    return Activity.find(:all, :select => 'DISTINCT item_id', :conditions => "item_id IS NOT NULL", :order => 'created_at DESC', :limit => limit).map { |ids| ids.item_id }
  end
    
  # a convenience function for matching up item types with hard coded icon classes
  def icon_class
    return case category.parent_id
    when 1 then 'writing'
    when 2 then 'legal'
    when 3 then 'artwork'
    when 4 then 'photo'
    when 5 then 'object'
    when 6 then 'oralhistory'
    else 'object'
    end unless category_id.nil? || category.nil?
  end

  def show_date
    unless display_date.blank?
      return display_date
    else
      return sort_date.to_s
    end
  end

  # TODO: Find the right place for this special XML route
  def slides_xml_url
    return '/archive/detail/' + id.to_s + '/slides.xml'
  end

  # Library media file accessors
  def thumbnail_file_name
    return FILE_PREFIX + id.to_s + ".jpg"
  end
  
  def thumbnail_url
    return LIBRARY_URL + THUMBNAILS_DIR + thumbnail_file_name
  end
  
  def preview_file_name(index=1)
    return FILE_PREFIX + "#{self.id.to_s}_#{index.to_s}.jpg" unless index.nil?
  end

  def preview_url(index=1)
    return LIBRARY_URL + PREVIEWS_DIR + preview_file_name(index) unless index.nil?
  end
  
  def preview_urls
    file_urls = Array.new
    (1..self.pages).each do |page|
      file_urls << preview_url(page)
    end unless self.pages.nil?
    return file_urls
  end
  
  def tif_file_name(index=1)
    return FILE_PREFIX + "#{self.id.to_s}_#{index.to_s}.tif" unless index.nil?
  end
  
  def tif_url(index=1)
    return LIBRARY_URL + TIFS_DIR + tif_file_name(index) unless index.nil?
  end

  def tif_urls
    file_urls = Array.new
    (1..self.pages).each do |page|
      file_urls << tif_url(page)
    end unless self.pages.nil?
    return file_urls
  end

  def zoomify_folder_name(index=1)
    return "it_#{self.id.to_s}_#{index.to_s}_img" unless index.nil?
  end
  
  def zoomify_url(index=1)
    return LIBRARY_URL + ZOOMIFY_DIR + zoomify_folder_name(index) unless index.nil?
  end

end
