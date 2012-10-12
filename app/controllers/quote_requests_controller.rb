class QuoteRequestsController < Spree::BaseController
  
  respond_to :html

  helper :products

  def new
    session["user_return_to"] = new_quote_request_path
    @quote_request = QuoteRequest.new
    @quote_request.bill_address = Address.new
    @quote_request.ship_address = Address.new
    @country = Country.find(Spree::Config[:default_country_id]) rescue Spree::Country.first
    @states = @country.states.all(:order => 'name')
  end

  def create
    @quote_request = QuoteRequest.new(params[:quote_request])
    @country = Country.find(Spree::Config[:default_country_id]) rescue Spree::Country.first
    @states = @country.states.all(:order => 'name')

    respond_to do |format|
      if @quote_request.save
        #Copy across the line items from the current order
        current_order.line_items.each do |line_item|
          quote_line_item = @quote_request.quote_line_items.new
          quote_line_item.variant_id = line_item.variant_id
          quote_line_item.quantity = line_item.quantity
          quote_line_item.save
        end
        format.html { redirect_to(quote_request_url(@quote_request.number)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def show
    @quote_request = QuoteRequest.find_by_number(params[:id])
  end

  def update
    @quote_request = QuoteRequest.find_by_number(params[:id])
    respond_to do |format|
      if @quote_request.update_attributes(params[:quote_request])
        format.html { redirect_to(quote_request_path(@quote_request.number)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # Shows the current incomplete quote from the session
  def edit
    @quote_request = current_quote_request(true)
  end

  # Adds a new item to the order (creating a new order if none already exists)
  #
  # Parameters can be passed using the following possible parameter configurations:
  #
  # * Single variant/quantity pairing
  # +:variants => {variant_id => quantity}+
  #
  # * Multiple products at once
  # +:products => {product_id => variant_id, product_id => variant_id}, :quantity => quantity +
  # +:products => {product_id => variant_id, product_id => variant_id}}, :quantity => {variant_id => quantity, variant_id => quantity}+
  def populate
    @quote_request = current_quote_request(true)

    params[:products].each do |product_id,variant_id|
      quantity = params[:quantity].to_i if !params[:quantity].is_a?(Hash)
      quantity = params[:quantity][variant_id].to_i if params[:quantity].is_a?(Hash)
      @quote_request.add_variant(Variant.find(variant_id), quantity) if quantity > 0
    end if params[:products]

    params[:variants].each do |variant_id, quantity|
      quantity = quantity.to_i
      @quote_request.add_variant(Variant.find(variant_id), quantity) if quantity > 0
    end if params[:variants]

    respond_with(@quote_request) { |format| format.html { redirect_to cart_path } }
  end

  def empty
    if @quote_request = current_quote_request
      @quote_request.line_items.destroy_all
    end
    
    respond_with(@quote_request) { |format| format.html { redirect_to cart_path } }
  end

  def accurate_title
    I18n.t(:quote_request)
  end
end
