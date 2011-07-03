class TrackFees < ActiveRecord::Migration
  def self.up
    add_column :deal_line_items, :fee, :decimal
  end

  def self.down
    remove_column :deal_line_items, :fee
  end
end
