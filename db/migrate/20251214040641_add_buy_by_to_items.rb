class AddBuyByToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :buy_by, :date
  end
end
