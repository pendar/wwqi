class ArchiveController < ApplicationController

  # application constants
  LIBRARY_URL = "http://library.qajarwomen.org/"
  def index
    @genres = Subject.where(["subjects.publish=? AND subjects.subject_type_id = ? AND subject_translations.locale=?", true, 8, I18n.locale.to_s]).order('subject_translations.name')
    @periods = Period.find(:all, :conditions => ['period_translations.locale=?', I18n.locale.to_s], :order => 'start_at')
    @collections = Collection.where(['publish=? AND private=? AND collection_translations.locale=?', true, false, I18n.locale.to_s]).order('collection_translations.sort_name')
    @subjects = Subject.where(['publish=? AND subject_type_id = ? AND subject_translations.locale=?', true, 7, I18n.locale.to_s]).order('subject_translations.name')
    @people = Person.where(['publish=? AND person_translations.locale=?', true, I18n.locale.to_s]).order('person_translations.name')
    @places = Place.where(['publish=? AND place_translations.locale=?', true, I18n.locale.to_s]).order('place_translations.name')

    @recently_viewed_items = Item.recently_viewed(8)
    @my_archive_ids = my_archive_from_cookie
    #cache the current search set in a session variable
    session[:archive_url] = request.fullpath
    session[:current_items] = nil
  end

  def collections
    @collections = Collection.where(['publish=? AND private=? AND collection_translations.locale=?', true, false, I18n.locale.to_s]).order('collection_translations.sort_name')
  end

  def subjects
    @filter_letter = params[:filter_letter]
    @filter_letter = @filter_letter[0] if !@filter_letter.nil? && @filter_letter.length > 1
    if @filter_letter.blank?
      @subjects = Subject.includes("classifications").select('DISTINCT subjects.id').where(['subjects.publish=? AND subject_type_id = ? AND subject_translations.locale=? AND classifications.id IS NOT NULL', true, 7, I18n.locale.to_s]).order('subject_translations.name')
    else
      @subjects = Subject.includes("classifications").select('DISTINCT subjects.id').where(['subjects.publish=? AND subject_type_id = ? AND subject_translations.locale=? AND classifications.id IS NOT NULL AND SUBSTRING(subject_translations.name,1,1) = ?', true, 7, I18n.locale.to_s,@filter_letter]).order('subject_translations.name')   
    end
    @valid_initials = @subjects.map { |s| s.name[0].upcase }.uniq
    @alphabet = I18n.locale == :en ? ALPHABET_EN : ALPHABET_FA 
    @filter_letter = params[:filter_letter]
  end

  def places
    @places = Place.where(['publish=? AND place_translations.locale=?', true, I18n.locale.to_s]).order('place_translations.name')
  end

  def people
    @people = Person.where(['publish=? AND person_translations.locale=?', true, I18n.locale.to_s]).order('person_translations.name')
  end

  def genres
    @genres = Subject.where(['publish=? AND subject_translations.locale=? AND subject_type_id = ?', true, I18n.locale.to_s, 8]).order('subject_translations.name')
  end

  def browser
    logger.info 'browser'
    @genres = Subject.where(["subjects.publish=? AND subjects.subject_type_id = ? AND subject_translations.locale=?", true, 8, I18n.locale.to_s]).order('subject_translations.name')
    @people = Person.where(["people.publish = ? AND person_translations.locale = ?", true, I18n.locale.to_s]).order('person_translations.sort_name')
    @collections = Collection.where(['collections.publish=?', true]).order('collection_translations.sort_name, collection_translations.name')
    @periods = Period.where(['periods.publish=?',true]).order('periods.position')
    @places = Place.where(["places.publish=? AND place_translations.locale = ?", true, I18n.locale.to_s])
    @subjects = Subject.where(["subjects.publish=? AND subjects.subject_type_id = ? AND subject_translations.locale=?", true, 7, I18n.locale.to_s]).order('subject_translations.name')

    #grab filter categories
    @collection_filter = params[:collection_filter]
    @translation_filter = params[:translation_filter]
    @period_filter = params[:period_filter]
    @person_filter = params[:person_filter]
    @subject_filter = params[:subject_filter]
    @subject_type_filter = params[:subject_type_filter]
    @place_filter = params[:place_filter]
    @keyword_filter = { :values => [ params[:keyword_filter] ],
      :fields => [ 'everything' ],
      :operators => [ ]  }
    @most_popular_filter = params[:most_popular_filter]
    @recent_additions_filter = params[:recent_additions_filter]
    @staff_favorites_filter = params[:staff_favorites_filter]
    @my_archive_ids = my_archive_from_cookie
    @my_archive_filter = params[:my_archive] == 'true' ? @my_archive_ids : nil
    @repository_filter = params[:repository_filter]
    @year_range_filter = {:start_year => params[:start_year_filter].to_i, :end_year => params[:end_year_filter].to_i }
    @boolean_keyword_filter = { :values => [ params[:value_1], params[:value_2], params[:value_3] ],
      :fields => [ params[:field_1], params[:field_2], params[:field_3] ],
      :operators => [ '', params[:operator_1], params[:operator_2] ]  }

    #grab view mode, using session or default of list if not present or junky
    @view_mode = ['list','grid'].include?(params[:view_mode]) ? params[:view_mode] : session[:view_mode] || 'list'

    #grab the sort mode
    @sort_mode = ['alpha_asc','alpha_dsc','date_asc','date_dsc'].include?(params[:sort_mode]) ? params[:sort_mode] : (session[:sort_mode].blank? ? 'alpha_asc' : session[:sort_mode])
    @order = build_order_query(@sort_mode)

    # paginate the items
    @page = params[:page] || 1
    @per_page = @view_mode == 'slideshow' ? 12 : params[:per_page] || Item.per_page || 10

    @query_hash = { :conditions => ['items.publish=:publish','item_translations.locale=:locale'], :parameters => {:publish => 1, :locale => I18n.locale.to_s } }

    @collection_filter_label = I18n.translate(:all)
    @period_filter_label = I18n.translate(:all)
    @subject_filter_label = I18n.translate(:all)

    @query_hash = build_medium_query(@medium_filter, @query_hash) unless @medium_filter.nil? || @medium_filter == 'all'
    @query_hash = build_collection_query(@collection_filter, @query_hash) unless @collection_filter.nil? || @collection_filter[0] == 'all'
    @query_hash = build_repository_query(@repository_filter, @query_hash) unless @repository_filter.nil? || @repository_filter[0] == 'all'
    @query_hash = build_period_query(@period_filter, @query_hash) unless @period_filter.nil? || @period_filter[0] == 'all'
    @query_hash = build_person_query(@person_filter, @query_hash) unless @person_filter.nil? || @person_filter == 'all'
    @query_hash = build_subject_query(@subject_filter, @query_hash) unless @subject_filter.nil? || @subject_filter[0] == 'all'
    @query_hash = build_place_query(@place_filter, @query_hash) unless @place_filter.nil? || @place_filter == 'all'
    @query_hash = build_subject_type_query(@subject_type_filter, @query_hash) unless @subject_type_filter.nil? || @subject_type_filter[0] == 'all'
    @query_hash = build_boolean_keyword_query(@keyword_filter, @query_hash) unless @keyword_filter[:values][0].blank? || @keyword_filter[:values][0] == I18n.translate(:search_prompt)
    @query_hash = build_most_popular_query(@most_popular_filter, @query_hash) unless @most_popular_filter.blank?
    @query_hash = build_recent_additions_query(@recent_additions_filter, @query_hash) unless @recent_additions_filter.blank?
    @query_hash = build_staff_favorites_query(@query_hash) unless @staff_favorites_filter.blank?
    @query_hash = build_translation_query(@translation_filter, @query_hash) unless @translation_filter.blank?
    @query_hash = build_my_archive_query(@my_archive_filter, @query_hash) unless @my_archive_filter.nil? || @my_archive_filter.empty?
    @query_hash = build_year_range_query(@year_range_filter, @query_hash) unless @year_range_filter.nil? || (@year_range_filter[:start_year] == 0 && @year_range_filter[:end_year] == 0)
    @query_hash = build_boolean_keyword_query(@boolean_keyword_filter, @query_hash) unless @boolean_keyword_filter[:values][0].blank? && @boolean_keyword_filter[:values][1].blank? && @boolean_keyword_filter[:values][2].blank?

    # assemble the query from the two sql injection safe parts
    @query_conditions = ''
    @query_hash[:conditions].each do |condition|
      @query_conditions += (@query_conditions.blank? ? '': ' AND ') + condition
    end

    @query = [@query_conditions, @query_hash[:parameters]]

    @items = Item.paginate :conditions => @query, :per_page => @per_page, :page => @page, :order => @order
    @items_full_set = Item.find(:all, :select => 'id', :conditions => @query, :order => @order)

    #cache the current search set in a session variable
    session[:archive_url] = request.fullpath
    session[:current_items] = items_set(@items_full_set)
    session[:view_mode] = @view_mode
    session[:sort_mode] = @sort_mode
  end

  def detail
    @return_url = (session[:archive_url].nil?) ? '/archive' : session[:archive_url]
    @my_archive_ids = my_archive_from_cookie

    begin
      @item = Item.find_by_id(params[:id])

      #check if there is a current results set (i.e. something from the browser)
      unless session[:current_items].nil? || session[:current_items].length < 1 || !session[:current_items].include?(@item.id)
        @items = Item.find(session[:current_items], :order => 'item_translations.title')
      else
        @sort_mode = ['alpha_asc','alpha_dsc','date_asc','date_dsc'].include?(params[:sort_mode]) ? params[:sort_mode] : session[:sort_mode] || 'alpha_asc'
        @order = build_order_query(@sort_mode)
        @items = Item.find(:all, :conditions => "items.publish=1 AND item_translations.locale = '#{I18n.locale.to_s}'", :order => @order )
      end
    rescue StandardError => error
      flash[:error] = 'Item with id number ' + params[:id].to_s + ' was not found or your item set was invalid. Reload the collections page.'
    @error = true
    end

    respond_to do |format|
      unless @error
        format.html
        format.xml  { render :xml => @item }
      else
        redirect_to @return_url
      end
    end
  end

  def advanced_search
    @fields = [ [I18n.translate(:everything), 'everything'],
      [I18n.translate(:title), 'title'],
      [I18n.translate(:accession_num), 'accession_num'],
      [I18n.translate(:description), 'description'],
      [I18n.translate(:transcript), 'transcript'],
      [I18n.translate(:credit), 'credit'],
      [I18n.translate(:item_id), 'item id'] ]
    @operators = [ [I18n.translate(:operator_and), "AND"], [I18n.translate(:operator_or), "OR"], [I18n.translate(:operator_not), "AND NOT"] ]
    @collections = Collection.where(['publish=?',true]).map { |c| [c.name, c.id]}.sort
    @genres = Subject.genres.where(['publish=?',true]).map { |s| [s.name, s.id]}.sort
    @repositories = Repository.where(['publish=?',true]).map { |r| [r.name, r.id]}.sort
  end

  def download
    @error = false
    begin
      @item = Item.find_by_id(params[:id])
      @file_to_send = @item.zip_path
      unless File.exists?(@file_to_send)
      #create a zip file if it is the first time
      zip_them_all = ZipThemAll.new(@file_to_send, @item.preview_paths)
      zip_them_all.zip
      end
      send_file @file_to_send, :type => "application/zip"
    rescue => error
      flash[:error] = error.message
    @error = true
    end
  end

  def forget

    id_to_forget = params[:id].to_i

    unless id_to_forget.nil?
      my_ids = my_archive_from_cookie
      my_ids.delete(id_to_forget)
      unless my_archive_to_cookie(my_ids)
        flash[:notice] = "Item could not be removed from My Archive."
      end
    else
      flash[:error] = "No item id to forget from My Archive."
    end

    respond_to do |format|
      format.html { redirect_to archive_detail_path(:id => id_to_forget) }
    end

  end

  def remember

    id_to_remember = params[:id].to_i

    unless id_to_remember.nil?
      my_ids = my_archive_from_cookie
      my_ids << id_to_remember
      unless my_archive_to_cookie(my_ids)
        flash[:notice] = "Item could not be saved to My Archive. Is you browser set to accept cookies?"
      end
    else
      flash[:error] = "No item id to remember in My Archive."
    end

    respond_to do |format|
      format.html { redirect_to archive_detail_path(:id => id_to_remember) }
    end

  end

  # zoomify requires a custom XML file for its gallery viewer
  def slides
    @id = params[:id]
    @item = Item.find(@id)
    begin
      @slides = @item.images.where(['publish=?', true]).order('position')
    rescue => error
      flash[:error] = error.message
    ensure
    # no slides found so create some
      if @slides.empty?
      @slides = @item.create_images
      end
    end
    unless @id.nil? || @slides.nil? || @slides.empty?
      respond_to do |format|
        format.xml
      end
    else
      flash[:error] = 'Unable to locate process slides for id number ' + params[:id].to_s + '.'
    end
  end

  private

  def items_set(items)
    return items.map { |i| i.id }
  end

  def build_medium_query(filter_value, query_hash)
    additional_query = ''
    begin
      @category = Category.find_by_id(filter_value.to_i)
      additional_query += 'category_id IN (' + @category.query_ids.join(',') + ')'
    rescue StandardError => error
      flash[:error] = "A problem was encountered searching for medium id #{filter_value}: #{error}."
    else
      flash[:error] = nil
    ensure
    query_hash[:conditions] << additional_query unless additional_query.blank?
    return query_hash
    end
  end

  def build_repository_query(filter_value, query_hash)
    if filter_value.kind_of?(Array)
    ids = filter_value
    else
      ids = [filter_value]
    end
    ids_to_find = ids.map { |id| id.to_i }.sort

    item_ids = Passport.where(['repository_id IN (?)', ids_to_find]).map { |p| p.item_id }.uniq.sort

    query_hash[:conditions] << 'items.id IN (:repository_item_ids)'
    query_hash[:parameters][:repository_item_ids] = item_ids unless item_ids.blank?
    return query_hash
  end

  def build_collection_query(filter_value, query_hash)
    if filter_value.kind_of?(Array)
    ids = filter_value
    else
      ids = [filter_value]
    end
    ids_to_find = ids.map { |id| id.to_i }.sort

    if ids_to_find.length == 1
    @collection_filter_label = Collection.find(ids_to_find[0].to_i).name
    else
    @collection_filter_label = I18n.translate(:multiple)
    end

    query_hash[:conditions] << 'collection_id IN (:collection_ids)'
    query_hash[:parameters][:collection_ids] = ids_to_find unless ids_to_find.blank?
    return query_hash
  end

  def build_subject_query(filter_value, query_hash)
    additional_query = ''

    if filter_value.kind_of?(Array)
      ids_to_find = filter_value.map { |id| id.to_i }.sort
      if ids_to_find.length == 1
      @subject_filter_label = Subject.find(ids_to_find[0].to_i).name
      else
      @subject_filter_label = I18n.translate(:multiple)
      end
    else
      ids_to_find = [filter_value.to_i]
    end

    begin
      selected_subjects = Subject.find(ids_to_find)
      item_ids = []
      selected_subjects.each do |subject|
        item_ids += subject.items.map { |p| p.id }
      end

      unless item_ids.empty?
        additional_query += "items.id IN (#{item_ids.join(",")})"
      else
      # if the person has no items, we should kill search
        flash[:error] = "No items found. Showing all."
      end
    rescue StandardError => error
      flash[:error] = "A problem was encountered searching for subject id #{filter_value}: #{error}."
    ensure
    query_hash[:conditions] << additional_query unless additional_query.blank?
    return query_hash
    end
  end

  def build_place_query(filter_value, query_hash)
    additional_query = ''
    begin
      @place = Place.find_by_id(filter_value.to_i)
      @ids = @place.items.map { |p| p.id }
      unless @ids.empty?
        additional_query += "items.id IN (#{@ids.join(",")})"
      else
        flash[:error] = "No items found. Showing all."
      end
    rescue StandardError => error
      flash[:error] = "A problem was encountered searching for place id #{filter_value}: #{error}."
    else
      flash[:error] = nil
    ensure
    query_hash[:conditions] << additional_query unless additional_query.blank?
    return query_hash
    end
  end

  def build_staff_favorites_query(query_hash)
    query_hash[:conditions] << "items.favorite = 1"
    return query_hash
  end

  def build_person_query(filter_value,query_hash)
    additional_query = ''
    begin
      @person = Person.find_by_id(filter_value.to_i)
      @ids = @person.items.map { |p| p.id }
      unless @ids.empty?
        additional_query += "items.id IN (#{@ids.join(",")})"
      else
        flash[:error] = "No items found. Showing all."
      end
    rescue StandardError => error
      flash[:error] = "A problem was encountered searching for person id #{filter_value}: #{error}."
    else
      flash[:error] = nil
    ensure
    query_hash[:conditions] << additional_query unless additional_query.blank?
    return query_hash
    end
  end

  def build_period_query(filter_value, query_hash)

    if filter_value.kind_of?(Array)
    ids = filter_value
    else
      ids = [filter_value]
    end

    ids_to_find = ids.map { |id| id.to_i }.sort

    if ids_to_find.length == 1
    @period_filter_label = Period.find(ids_to_find[0].to_i).title
    else
    @period_filter_label = I18n.translate(:multiple)
    end

    begin
      periods = Period.find(ids_to_find)
      if periods.size == 1
        date_ranges = "(sort_year BETWEEN '#{periods[0].start_at.strftime("%Y")}' AND '#{periods[0].end_at.strftime("%Y")}')"
      else
        date_ranges = ''
        periods.each_with_index do |period, index|
          date_ranges += "(sort_year BETWEEN '#{period.start_at.strftime("%Y")}' AND '#{period.end_at.strftime("%Y")}')"
          if index + 1 != periods.size
            date_ranges += " OR "
          end
        end
      end
      query_hash[:conditions] << date_ranges

    rescue StandardError => error
      flash[:error] = "A problem was encountered searching for period ids #{filter_value}: #{error}."
    else
      flash[:error] = nil
    ensure
    return query_hash
    end
  end

  def build_year_range_query(filter_value, query_hash)

    start_year = (!filter_value[:start_year].nil?  && filter_value[:start_year] > 0 && filter_value[:start_year] < 3000) ? filter_value[:start_year] : 0
    end_year = (!filter_value[:end_year].nil?  && filter_value[:end_year] > 0  && filter_value[:end_year] < 3000) ? filter_value[:end_year] : 0

    end_year = 0 unless filter_value[:end_year] >= start_year

    if start_year > 0 && end_year > 0
      date_ranges = "(sort_year BETWEEN '#{start_year}' AND '#{end_year}')"
    elsif start_year > 0
      date_ranges = "(sort_year > '#{start_year}')"
    elsif end_year > 0
      date_ranges = "(sort_year < '#{end_year}')"
    else
      date_ranges = ''
    end

    query_hash[:conditions] << date_ranges unless date_ranges.blank?
    return query_hash
  end

  def build_most_popular_query(filter_value, query_hash)
    additional_query = ''
    begin
      @ids = Item.most_popular_ids(50)
      unless @ids.empty?
        additional_query += "items.id IN (#{@ids.join(",")})"
      else
      # if the most popular returns no items, we should kill search
        flash[:error] = "No items found. Showing all."
      end
    rescue StandardError => error
      flash[:error] = "A problem was encountered searching for most popular items: #{error}."
    ensure
    query_hash[:conditions] << additional_query unless additional_query.blank?
    return query_hash
    end
  end

  def build_recent_additions_query(filter_value, query_hash)
    additional_query = ''
    if filter_value == 'true'
      begin
        @ids = Item.recently_added_ids(50)
        unless @ids.empty?
          additional_query += "items.id IN (#{@ids.join(",")})"
        else
        # if the most popular returns no items, we should kill search
          flash[:error] = "No items found. Showing all."
        end
      rescue StandardError => error
        flash[:error] = "A problem was encountered searching for recent additions."
      ensure
      query_hash[:conditions] << additional_query unless additional_query.blank?
      end
    end
    return query_hash
  end

  def build_subject_type_query(filter_value, query_hash)

    #check if the value is an array, or make it one
    subject_type_ids = filter_value.kind_of?(Array) ? filter_value : [filter_value]

    #turn parameter strings into proper integers for id finding
    ids_to_find = subject_type_ids.map { |id| id.to_i }.uniq.sort

    # initialize the query string
    additional_query = ''

    begin

    # get the request subjects types
      subject_types = SubjectType.find(ids_to_find)

      logger.info "subject_types.size: " + subject_types.size.to_s

      # harvest their items by looping through them
      classifications = []

      subject_types.each do |subject_type|
        classifications += subject_type.classifications(:select => 'item_id')
      end

      logger.info "classifictions.size " + classifications.size.to_s

      item_ids = classifications.map { |i| i.item_id }.uniq.sort
      logger.info "item_ids: " + item_ids.to_s

      unless item_ids.empty?
        additional_query += "items.id IN (#{item_ids.join(",")})"
        logger.info "additional_query: " + additional_query
      else
      # if the subject type has no items, we should kill search
        additional_query += "items.id IS NULL"
        flash[:error] = "No items found. Showing all."
      end

      # build the label needed for the filter display
      @subject_type_filter_label = subject_type_ids.length == 1 ? subject_types[0].name : I18n.translate(:multiple)

    rescue StandardError => error
      flash[:error] = "A problem was encountered searching for subject type #{filter_value.to_s}: #{error}."
    else
      flash[:error] = nil
    ensure
    query_hash[:conditions] << additional_query unless additional_query.blank?
    return query_hash
    end
  end

  def clean_keyword(filter_value)
    filter_value = filter_value.lstrip
    filter_value = filter_value.length > 256 ? filter_value[0..255] : filter_value
    filter_value = filter_value.upcase #locale insensitive
    filter_value = "%#{filter_value}%"
    return filter_value
  end

  def build_boolean_keyword_query(filter_value, query_hash)
    additional_query = ''
    keywords = []

    # turn keyword fields into word arrays and git rid of little words
    filter_value[:values].each_with_index do |value, index|
      # first find any quoted phrases
      keywords[index] = value.scan(/'(.+?)'|"(.+?)"|([^ ]+)/).flatten.compact.reject { |k| k == "" || k.nil? || k.length<3 }.map { |k| clean_keyword(k) } unless value.blank?
    end

    # assemble the query by field for each keyword set
    keywords.each_with_index do |values, outer_index|

    # take each keyword and build a field specific query for it
      field = filter_value[:fields][outer_index]
      outer_operator = filter_value[:operators][outer_index]

      # initialize the subqueries
      subqueries = []

      # cycle through the inner keywords with an assumed AND
      values.each_with_index do |value, inner_index|

        unless value.blank?

          # test for AND requirement
          inner_operator = inner_index > 0 ? ' OR ' : ''

          subqueries << case field
            when 'everything' then "#{inner_operator}CONCAT_WS('|', UPPER(item_translations.title), UPPER(item_translations.description), UPPER(item_translations.credit), UPPER(accession_num), CONCAT('ID',items.id)) LIKE :keyword_#{outer_index}_#{inner_index}"
            when 'title' then "#{inner_operator}UPPER(item_translations.title) LIKE :keyword_#{outer_index}_#{inner_index}"
            when 'description' then "#{inner_operator}UPPER(item_translations.description) LIKE :keyword_#{outer_index}_#{inner_index}"
            when 'transcript' then "#{inner_operator}UPPER(item_translations.transcript) LIKE :keyword_#{outer_index}_#{inner_index}"
            when 'accession_num' then "#{inner_operator}UPPER(items.accession_num) LIKE :keyword_#{outer_index}_#{inner_index}"
            when 'credit' then "#{inner_operator}UPPER(item_translations.credit) LIKE :keyword_#{outer_index}_#{inner_index}"
            when 'item_id' then "#{inner_operator}CONCAT('|',items.id,'|') LIKE :keyword_#{outer_index}_#{inner_index}"
          else "#{inner_operator}UPPER(title) LIKE :keyword_#{outer_index}_#{inner_index}"
          end

          #store the parameter in a unique key
          query_hash[:parameters]["keyword_#{outer_index}_#{inner_index}".to_sym] = value

        end

      end

      additional_query += " #{outer_operator} #{subqueries.join(' ')}" unless subqueries.empty?

    end

    query_hash[:conditions] << additional_query
    return query_hash
  end

  def build_keyword_query(filter_value, query_hash)
    additional_query = ''
    filter_value = filter_value.lstrip
    filter_value = filter_value.length > 256 ? filter_value[0..255] : filter_value
    filter_value = filter_value.upcase #locale insensitive
    filter_value = "%#{filter_value}%"
    # ucase if it English
    if I18n.locale == :en
      additional_query += "CONCAT_WS('|', UPPER(item_translations.title), UPPER(item_translations.description), UPPER(accession_num), CONCAT('ID',items.id)) LIKE :keyword" unless filter_value.blank?
    else
      additional_query += "CONCAT_WS('|',item_translations.title, item_translations.description, accession_num, items.id) LIKE :keyword" unless filter_value.blank?
    end

    query_hash[:conditions] << additional_query
    query_hash[:parameters][:keyword] = filter_value
    return query_hash
  end

  def build_order_query(sort_mode)
    additional_sort = ''
    additional_sort += case sort_mode
      when 'alpha_asc' then 'item_translations.locale, item_translations.title'
      when 'alpha_dsc' then 'item_translations.locale, item_translations.title DESC'
      when 'date_asc' then 'items.sort_year, items.sort_month, items.sort_day'
      when 'date_dsc' then 'items.sort_year DESC, items.sort_month DESC, items.sort_day DESC'
    else 'item_translations.locale, item_translations.title'
    end
    return additional_sort
  end

  def build_my_archive_query(filter_value, query_hash)
    query_hash[:conditions] << "items.id IN (:my_archive_ids)"
    query_hash[:parameters][:my_archive_ids] = filter_value.sort
    return query_hash
  end

  def build_translation_query(filter_value, query_hash)
    if filter_value == "true"
      query_hash[:conditions] << "Length(item_translations.transcript) > 0"
    else
      query_hash[:conditions] << "Length(item_translations.transcript) = 0"
    end
    return query_hash
  end

end
