class AddUidAndCommentField < ActiveRecord::Migration
  def self.up
    add_column :transactions, :user_id, :integer
    add_column :transactions, :note, :string
  end

  def self.down
    remove_column :transactions, :user_id
    remove_column :transactions, :note
  end
end
