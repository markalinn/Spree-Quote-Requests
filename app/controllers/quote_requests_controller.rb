class QuoteRequestsController < Spree::BaseController
  respond_to :html

  helper :products


  def show
    @quote_request = QuoteRequest.find_by_number(params[:id])
  end

  def update
    @quote_request = current_quote_request
    if @quote_request.update_attributes(params[:quote_request])
      @quote_request.line_items = @quote_request.line_items.select {|li| li.quantity > 0 }
      respond_with(@quote_request) { |format| format.html { redirect_to cart_path } }
    else
      respond_with(@quote_request) 
    end
  end

  # Shows the current incomplete order from the session
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
    @quote_request && @quote_request.completed? ? "#{QuoteRequest.human_name} #{@quote_request.number}" : I18n.t(:shopping_cart)
  end
end
