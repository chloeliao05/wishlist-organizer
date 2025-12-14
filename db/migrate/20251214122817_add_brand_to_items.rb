class AddBrandToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :brand, :string
  end
end
