class Admin::PeopleController < Admin::AdminController

  before_filter :admin_required, :except => [:index, :show]

  # GET /people
  # GET /people.xml
  def index
    
    @collections = Collection.select_list
    @order = sort_order('person_translations.name') unless params[:c] == 'name_en' || params[:c] == 'name_fa'
    
    # look for filters
    @keyword_filter = params[:keyword_filter] unless params[:keyword_filter] == I18n.translate(:search_prompt)
    @collection_filter = params[:collection_filter]

    # unless @keyword_filter.nil? && @collection_filter.nil? && period_filer.nil? && subject_type_filter.nil?

    @query_hash = { :conditions => [], :parameters => {} }
    @query_hash = build_keyword_query(@keyword_filter, @query_hash) unless @keyword_filter.blank? || @keyword_filter == I18n.translate(:search_prompt)
    @query_hash = build_collection_query(@collection_filter, @query_hash) unless @collection_filter.nil? || @collection_filter == 'all'

    # assemble the query from the two sql injection safe parts
    @query_conditions = ''
    @query_hash[:conditions].each do |condition|
      @query_conditions += (@query_conditions.blank? ? '': ' AND ') + condition
    end

    @query = [@query_conditions, @query_hash[:parameters]]

    
    @people = Person.where(@query).order(@order)
    
    if params[:c] == 'name_en' 
      @people = @people.sort_by(&:name_en)
      @people.reverse! if params[:d] == 'down'
    elsif params[:c] == 'name_fa'
      @people = @people.sort_by(&:name_fa)
      @people.reverse! if params[:d] == 'down'
    end
    
    #cache the current search set in a session variable
    session[:admin_people_index_url] = request.fullpath

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @people }
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show
    @person = Person.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new
    @person = Person.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/1/edit
  def edit
    @person = Person.find(params[:id])
  end

  # POST /people
  # POST /people.xml
  def create
    @person = Person.new(params[:person])

    respond_to do |format|
      if @person.save
        format.html { redirect_to(admin_person_path(@person), :notice => 'Person was successfully created.') }
        format.xml  { render :xml => @person, :status => :created, :location => @person }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.xml
  def update
    @person = Person.find(params[:id])

    respond_to do |format|
      if @person.update_attributes(params[:person])
        format.html { redirect_to(admin_person_path(@person), :notice => 'Person was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml
  def destroy
    @person = Person.find(params[:id])
    @person.destroy

    respond_to do |format|
      format.html { redirect_to(admin_people_url) }
      format.xml  { head :ok }
    end
  end
  
  
  private

  def build_keyword_query(filter_value, query_hash)
    additional_query = ''
    filter_value = filter_value.lstrip
    filter_value = filter_value.length > 256 ? filter_value[0..255] : filter_value
    filter_value = filter_value.upcase #locale insensitive
    filter_value = "%#{filter_value}%"
    # ucase if it English
    if I18n.locale == :en
      additional_query += "CONCAT_WS('|', UPPER(person_translations.name), UPPER(person_translations.sort_name), UPPER(people.loc_name), CONCAT('ID',people.id)) LIKE :keyword" unless filter_value.blank?
    else
      additional_query += "CONCAT_WS('|',person_translations.name, person_translations.sort_name, people.loc_name, people.id) LIKE :keyword" unless filter_value.blank?
    end

    query_hash[:conditions] << additional_query
    query_hash[:parameters][:keyword] = filter_value
    return query_hash
  end
  
  def build_collection_query(filter_value, query_hash)
    additional_query = ''
    begin
      @collection = Collection.find_by_id(filter_value.to_i)
      @appearance_ids = []
      # now gather the items
      @collection.items.each do |item|
        @appearance_ids += item.appearances.map { |a| a.person_id } 
        Rails.logger.info "@appearance_ids: " + @appearance_ids.join(",")
      end
      unless @appearance_ids.empty?
        additional_query += "people.id IN (#{@appearance_ids.uniq.sort.join(",")})"
        flash[:error] = nil
      else
        flash[:error] = "No people were found to be linked to items in that collection."
      end
    rescue StandardError => error
      flash[:error] = "A problem was encountered searching for collection id #{filter_value}: #{error}."
    ensure
      query_hash[:conditions] << additional_query unless additional_query.blank?
      return query_hash
    end
  end
end
