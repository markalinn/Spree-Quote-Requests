class AddStateToQuoteRequests < ActiveRecord::Migration
  def self.up
    add_column :quote_requests, :state, :string
  end

  def self.down
    remove_column :quote_requests, :state
  end
end
