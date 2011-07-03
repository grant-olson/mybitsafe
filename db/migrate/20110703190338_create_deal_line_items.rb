class CreateDealLineItems < ActiveRecord::Migration
  def self.up
    create_table :deal_line_items do |t|
      t.integer :deal_id
      t.string :tx_id
      t.string :tx_type
      t.decimal :debit
      t.decimal :credit

      t.timestamps
    end
  end

  def self.down
    drop_table :deal_line_items
  end
end
