class AddSendAddress < ActiveRecord::Migration
  def self.up
    add_column :deals, :send_address, :string
  end

  def self.down
    remove_column :deals, :send_address
  end
end
