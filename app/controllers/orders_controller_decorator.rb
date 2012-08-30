OrdersController.class_eval do
  
  after_filter :display_quote_message

  def display_quote_message
    if current_order.requires_quote
      flash.notice = "* QUOTE REQUIRED - 1 or more Items in your cart requires that you submit a request for a quote."
    end
  end

end