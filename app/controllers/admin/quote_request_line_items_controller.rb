class Admin::QuoteRequestLineItemsController < Admin::BaseController

  before_filter :load_quote_request
  before_filter :load_quote_request_line_item, :only => [:destroy, :update]

  respond_to :html

  def create
    variant = Variant.find(params[:quote_request_line_item][:variant_id])
    @quote_request_line_item = @quote_request.add_variant(variant, params[:quote_request_line_item][:quantity].to_i)

    if @quote_request.save
      respond_with(@quote_request_line_item) do |format| 
        format.html { render :partial => "admin/quote_requests/form", :locals => {:quote_request => @quote_request.reload}, :layout => false }
      end
    else
      #TODO Handle failure gracefully, patches welcome.
    end
  end

  def destroy
    if @quote_request_line_item.destroy
      respond_with(@quote_request_line_item) do |format| 
        format.html { render :partial => "admin/quote_requests/form", :locals => {:quote_request => @quote_request.reload}, :layout => false }
      end
    else
      respond_with(@quote_request_line_item) do |format| 
        format.html { render :partial => "admin/quote_requests/form", :locals => {:quote_request => @quote_request.reload}, :layout => false }
      end
    end
  end

  def new
    respond_with do |format| 
      format.html { render :action => :new, :layout => false }
    end
  end

  def update
    if @quote_request_line_item.update_attributes(params[:quote_request_line_item])
      respond_with(@quote_request_line_item) do |format| 
        format.html { render :partial => "admin/quote_requests/form", :locals => {:quote_request => @quote_request.reload}, :layout => false}
      end
    else
      respond_with(@quote_request_line_item) do |format| 
        format.html { render :partial => "admin/quote_requests/form", :locals => {:quote_request => @quote_request.reload}, :layout => false}
      end
    end
  end


  def load_quote_request
    @quote_request = quote_request.find_by_number! params[:quote_request_id]
  end

  def load_quote_request_line_item
    @quote_request_line_item = @quote_request.quote_request_line_items.find params[:id]
  end

end
