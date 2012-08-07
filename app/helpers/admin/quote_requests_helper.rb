module Admin::QuoteRequestsHelper

  # Renders all the txn partials that may have been specified in the extensions
  def render_txn_partials(quote_request)
    @txn_partials.inject("") do |extras, partial|
      extras += render :partial => partial, :locals => {:payment => quote_request}
    end
  end

  # Renders all the extension partials that may have been specified in the extensions
  def event_links
    links = []
    @quote_request_events.sort.each do |event|
      if @quote_request.send("can_#{event}?")
        links << button_link_to(t(event), fire_admin_quote_request_url(@quote_request, :e => event),
                                { :method => :put, :confirm => t("order_sure_want_to", :event => t(event)) })
      end
    end
    links.join('&nbsp;').html_safe
  end

end
