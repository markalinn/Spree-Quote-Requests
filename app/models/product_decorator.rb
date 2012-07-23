Product.class_eval do

  scope :requires_quote, lambda { |*args| 
          { :conditions => ["variants.qty_requires_quote >= 0"], 
            :include => :variants_with_only_master
          } 
      } 

  def qty_requires_quote
    master.qty_requires_quote
  end

  def qty_requires_quote=(value)
    master.qty_requires_quote = value
  end


end