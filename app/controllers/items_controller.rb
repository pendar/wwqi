class ItemsController < ApplicationController

  before_filter :admin_required, :except => [:index, :show]

  # GET /items
  # GET /items.xml
  def index
    @page = params[:page] || 1
    @per_page = params[:per_page] || Item.per_page || 25
    @items = Item.paginate :all, :per_page => @per_page, :page => @page, :order => 'item_translations.title'

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @items }
    end
  end

  # GET /items/1
  # GET /items/1.xml
  def show
    @item = Item.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @item }
    end
  end

  # GET /items/new
  # GET /items/new.xml
  def new
    @item = Item.new
    @creator_list = creator_list
    @owner_list = owner_list
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @item }
    end
  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
    @creator_list = creator_list
    @owner_list = owner_list
  end

  # POST /items
  # POST /items.xml
  def create
    @item = Item.new(params[:item])
    @creator_list = creator_list
    @owner_list = owner_list
    respond_to do |format|
      if @item.save
        format.html { redirect_to(@item, :notice => 'Item was successfully created.') }
        format.xml  { render :xml => @item, :status => :created, :location => @item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.xml
  def update
    @item = Item.find(params[:id])
    @creator_list = creator_list
    @owner_list = owner_list
    respond_to do |format|
      if @item.update_attributes(params[:item])
        format.html { redirect_to(@item, :notice => 'Item was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    @item = Item.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to(items_url) }
      format.xml  { head :ok }
    end
  end

  private

  def creator_list
    return Person.all(:conditions => ['person_translations.locale = ?', I18n.locale.to_s], :order => 'person_translations.sort_name').map {|person| [person.name, person.id]}
  end

  def owner_list
    return Owner.all(:conditions => ['owner_translations.locale = ?', I18n.locale.to_s], :order => 'owner_translations.name').map {|owner| [owner.name, owner.id]}
  end

end
