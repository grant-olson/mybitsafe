class MysqlDoesntLikeDecimal < ActiveRecord::Migration
  def self.up
    change_column :deal_line_items, :debit, :float
    change_column :deal_line_items, :credit, :float

    change_column :reserve_line_items, :debit, :float
    change_column :reserve_line_items, :credit, :float
    
    change_column :rake_line_items, :debit, :float
    change_column :rake_line_items, :credit, :float
    
  end

  def self.down
    change_column :deal_line_items, :debit, :decimal
    change_column :deal_line_items, :credit, :decimal

    change_column :reserve_line_items, :debit, :decimal
    change_column :reserve_line_items, :credit, :decimal
    
    change_column :rake_line_items, :debit, :decimal
    change_column :rake_line_items, :credit, :decimal
    
  end
end
