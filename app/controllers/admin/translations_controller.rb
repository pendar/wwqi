class Admin::TranslationsController < Admin::AdminController

  before_filter :admin_required, :except => [:index, :show]

  # GET /translations
  # GET /translations.xml
  def index
    # paginate the items
    @page = params[:page] || 1
    @per_page = params[:per_page] || Translation.per_page || 10
    @translations = Translation.paginate(:all,  :per_page => @per_page, :page => @page, :order => 'translations.key, translations.locale')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /translations/1
  # GET /translations/1.xml
  def show
    @translation = Translation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/new
  # GET /translations/new.xml
  def new
    @translation = Translation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/1/edit
  def edit
    @translation = Translation.find(params[:id])
  end

  # POST /translations
  # POST /translations.xml
  def create
    @translation = Translation.new(params[:translation])

    respond_to do |format|
      if @translation.save
        format.html { redirect_to(admin_translation_path(@translation), :notice => 'Translation was successfully created.') }
        format.xml  { render :xml => @translation, :status => :created, :location => @translation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /translations/1
  # PUT /translations/1.xml
  def update
    @translation = Translation.find(params[:id])

    respond_to do |format|
      if @translation.update_attributes(params[:translation])
        format.html { redirect_to(admin_translation_path(@translation), :notice => 'Translation was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /translations/1
  # DELETE /translations/1.xml
  def destroy
    @translation = Translation.find(params[:id])
    @translation.destroy

    respond_to do |format|
      format.html { redirect_to(admin_translations_url) }
      format.xml  { head :ok }
    end
  end
end
