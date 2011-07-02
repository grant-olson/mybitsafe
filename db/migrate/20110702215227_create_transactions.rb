class CreateTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.string :tx_id
      t.string :release_address

      t.timestamps
    end
  end

  def self.down
    drop_table :transactions
  end
end
