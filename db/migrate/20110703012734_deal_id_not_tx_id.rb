class DealIdNotTxId < ActiveRecord::Migration
  def self.up
    rename_column :deals, :tx_id, :deal_id
  end

  def self.down
    rename_column :deals, :deal_id, :tx_id
  end
end
