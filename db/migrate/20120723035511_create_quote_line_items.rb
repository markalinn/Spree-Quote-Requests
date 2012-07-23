class CreateQuoteLineItems < ActiveRecord::Migration
  def self.up
    create_table :quote_line_items do |t|
      t.integer  "quote_request_id"
      t.integer  "variant_id"
      t.integer  "quantity",                                 :null => false
      
      t.timestamps
    end
    add_index "quote_line_items", ["quote_request_id"], :name => "index_quote_line_items_on_quote_request_id"
    add_index "quote_line_items", ["variant_id"], :name => "index_quote_line_items_on_variant_id"
  end

  def self.down
    drop_table :quote_line_items
  end
end
