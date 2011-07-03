class FixupModelNames < ActiveRecord::Migration
  def self.up
    rename_column :deals, :deal_id, :uuid
  end

  def self.down
    rename_column :deals, :uuid, :deal_id
  end
end
