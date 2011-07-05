class RemoveFee < ActiveRecord::Migration
  def self.up
    remove_column :deal_line_items, :fee
  end

  def self.down
    add_column :deal_line_items, :fee, :decimal
  end
end
