class CreateQuoteRequests < ActiveRecord::Migration
  def self.up
    create_table :quote_requests do |t|
      t.integer :user_id
      t.string :number,           :limit => 15
      t.decimal :item_total, :precision => 8, :scale => 2, :default => 0.0, :null => false
      t.decimal :total, :precision => 8, :scale => 2, :default => 0.0, :null => false
      t.integer :bill_address_id
      t.integer :ship_address_id
      t.string :email
      t.text :special_instructions
      
      t.timestamps
    end
    
    add_index "quote_requests", ["number"], :name => "index_quote_requests_on_number"
  end

  def self.down
    drop_table :quote_requests
  end
end
