class AddUidAndCommentField < ActiveRecord::Migration
  def self.up
    add_column :deals, :user_id, :integer
    add_column :deals, :note, :string
  end

  def self.down
    remove_column :deals, :user_id
    remove_column :deals, :note
  end
end
