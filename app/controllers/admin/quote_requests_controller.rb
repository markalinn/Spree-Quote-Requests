class Admin::QuoteRequestsController < Admin::BaseController
  require 'spree/gateway_error'
  before_filter :initialize_txn_partials
  before_filter :initialize_quote_request_events
  before_filter :load_quote_request, :only => [:fire, :resend, :history, :user]

  respond_to :html

  def index
    params[:search] ||= {}
    params[:search][:completed_at_is_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
    @show_only_completed = params[:search][:completed_at_is_not_null].present?
    params[:search][:meta_sort] ||= @show_only_completed ? 'completed_at.desc' : 'created_at.desc'

    @search = QuoteRequest.metasearch(params[:search])

    if !params[:search][:created_at_greater_than].blank?
      params[:search][:created_at_greater_than] = Time.zone.parse(params[:search][:created_at_greater_than]).beginning_of_day rescue ""
    end

    if !params[:search][:created_at_less_than].blank?
      params[:search][:created_at_less_than] = Time.zone.parse(params[:search][:created_at_less_than]).end_of_day rescue ""
    end

    if @show_only_completed
      params[:search][:completed_at_greater_than] = params[:search].delete(:created_at_greater_than)
      params[:search][:completed_at_less_than] = params[:search].delete(:created_at_less_than)
    end

    @quote_requests = QuoteRequest.metasearch(params[:search]).paginate(
                                   :include  => [:user],
                                   :per_page => Spree::Config[:orders_per_page],
                                   :page     => params[:page])

    respond_with(@quote_requests)
  end

  def show
    load_quote_request
    respond_with(@quote_request)
  end

  def new
    @quote_request = QuoteRequest.create
    respond_with(@quote_request)
  end

  def edit
    load_quote_request
    respond_with(@quote_request)
  end

  def update
    return_path = nil
    load_quote_request
    if @quote_request.update_attributes(params[:quote_request]) && @quote_request.line_items.present?
      unless @quote_request.complete?
      
        if params[:quote_request].key?(:email)
          shipping_method = @quote_request.available_shipping_methods(:front_end).first
          if shipping_method
            @quote_request.shipping_method = shipping_method
            @quote_request.create_shipment!
            return_path = edit_admin_quote_request_shipment_path(@quote_request, @quote_request.shipment)
          else
            flash[:error] = t('errors.messages.no_shipping_methods_available')
            return_path = user_admin_quote_request_path(@quote_request)
          end
        else
          return_path = user_admin_quote_request_path(@quote_request)
        end
        
      else
        return_path = admin_quote_request_path(@quote_request)
      end
    else
      @quote_request.errors.add(:line_items, t('errors.messages.blank'))
    end
    
    respond_with(@quote_request) do |format|
      format.html do
        if return_path
          redirect_to return_path
        else
          render :action => :edit
        end
      end
    end
  end


  def fire
    # TODO - possible security check here but right now any admin can before any transition (and the state machine
    # itself will make sure transitions are not applied in the wrong state)
    event = params[:e]
    if @quote_request.send("#{event}")
      flash.notice = t('quote_request_updated')
    else
      flash[:error] = t('cannot_perform_operation')
    end
  rescue Spree::GatewayError => ge
    flash[:error] = "#{ge.message}"
  ensure
    respond_with(@quote_request) { |format| format.html { redirect_to :back } }
  end

  def resend
    QuoteRequestMailer.confirm_email(@quote_request, true).deliver
    flash.notice = t('quote_request_email_resent')

    respond_with(@quote_request) { |format| format.html { redirect_to :back } }
  end

  def user
    @quote_request.build_bill_address(:country_id => Spree::Config[:default_country_id]) if @quote_request.bill_address.nil?
    @quote_request.build_ship_address(:country_id => Spree::Config[:default_country_id]) if @quote_request.ship_address.nil?
  end

  private

  def load_quote_request
    @quote_request ||= QuoteRequest.find_by_number(params[:id]) if params[:id]
    @quote_request
  end

  # Allows extensions to add new forms of payment to provide their own display of transactions
  def initialize_txn_partials
    @txn_partials = []
  end

  # Used for extensions which need to provide their own custom event links on the quote_request details view.
  def initialize_quote_request_events
    @quote_request_events = %w{cancel resume}
  end

end
