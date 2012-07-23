class SpreeQuoteRequestsHooks < Spree::ThemeSupport::HookListener
  # custom hooks go here
  insert_after :admin_product_form_right, 'admin/products/qty_requires_quote_form_addition'
end