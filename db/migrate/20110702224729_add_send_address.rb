class AddSendAddress < ActiveRecord::Migration
  def self.up
    add_column :transactions, :send_address, :string
  end

  def self.down
    remove_column :transactions, :send_address
  end
end
