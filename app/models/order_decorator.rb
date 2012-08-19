Order.class_eval do

  def requires_quote
    result = false
    line_items.each do |line_item|
      if line_item.variant.qty_requires_quote.to_i > 0
        result = true
        break
      end
    end
    return result
  end

end