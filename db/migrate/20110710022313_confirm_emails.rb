class ConfirmEmails < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.confirmable
    end
  end

  def self.down
  end
end
