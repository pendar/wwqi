class Admin::CommentsController < Admin::AdminController
    # GET /comments
    # GET /comments.xml
    def index
        @comments = Comment.all

        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @comments }
        end
    end

    def confirm
        @comment = Comment.find(params[:id])

        respond_to do |format|
            format.html # show.html.erb
            format.xml  { render :xml => @comment }
        end
    end
    
    # GET /comments/1
    # GET /comments/1.xml
    def show
        @comment = Comment.find(params[:id])

        respond_to do |format|
            format.html # show.html.erb
            format.xml  { render :xml => @comment }
        end
    end

    # GET /comments/new
    # GET /comments/new.xml
    def new
        @comment = Comment.new

        respond_to do |format|
            format.html # new.html.erb
            format.xml  { render :xml => @comment }
        end
    end

    # GET /comments/1/edit
    def edit
        @comment = Comment.find(params[:id])
    end

    # POST /comments
    # POST /comments.xml
    def create
        @comment = Comment.new(params[:comment])

        respond_to do |format|
            if @comment.save
                if params[:public_comment] == 'true'
                    format.html { redirect_to(contact_path, :notice => 'Comment was successfully submitted.', :id => @comment) }
                    format.xml  { render :xml => @comment, :status => :created, :location => @comment }
                else
                    format.html { redirect_to(admin_comment_path(@comment), :notice => 'Comment was successfully created.') }
                    format.xml  { render :xml => @comment, :status => :created, :location => @comment }
                end
            else
                if params[:public_comment] == 'true'
                    format.html { redirect_to(contact_path, :comment => @comment) }
                    format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
                else
                    format.html { render :action => "new" }
                    format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
                end
            end
        end
    end

    # PUT /comments/1
    # PUT /comments/1.xml
    def update
        @comment = Comment.find(params[:id])

        respond_to do |format|
            if @comment.update_attributes(params[:comment])
                format.html { redirect_to(admin_comment_path(@comment), :notice => 'Comment was successfully updated.') }
                format.xml  { head :ok }
            else
                format.html { render :action => "edit" }
                format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
            end
        end
    end

    # DELETE /comments/1
    # DELETE /comments/1.xml
    def destroy
        @comment = Comment.find(params[:id])
        @comment.destroy

        respond_to do |format|
            format.html { redirect_to(admin_comments_url) }
            format.xml  { head :ok }
        end
    end
end
