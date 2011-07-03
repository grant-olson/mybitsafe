class CreateDeals < ActiveRecord::Migration
  def self.up
    create_table :deals do |t|
      t.string :tx_id
      t.string :release_address

      t.timestamps
    end
  end

  def self.down
    drop_table :deals
  end
end
