class CreateReserveLineItems < ActiveRecord::Migration
  def self.up
    create_table :reserve_line_items do |t|
      t.decimal :debit
      t.decimal :credit
      t.string :note

      t.timestamps
    end
  end

  def self.down
    drop_table :reserve_line_items
  end
end
