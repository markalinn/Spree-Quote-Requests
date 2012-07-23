class AddQtyReqQuoteToVariants < ActiveRecord::Migration
  def self.up
    add_column :variants, :qty_requires_quote, :integer
  end

  def self.down
    remove_column :variants, :qty_requires_quote
  end
end
