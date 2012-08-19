class SpreeQuoteRequestsHooks < Spree::ThemeSupport::HookListener
  # custom hooks go here
  insert_after :admin_product_form_right, 'admin/products/qty_requires_quote_form_addition'
  insert_after :admin_tabs, "admin/shared/quote_requests_tab" 
  replace :outside_cart_form, 'orders/quote_cart_form'
  replace :cart_item_price, 'orders/quote_cart_item_price'
  replace :cart_item_total, 'orders/quote_cart_item_total'
end