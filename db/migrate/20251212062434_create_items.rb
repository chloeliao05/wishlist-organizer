class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :url
      t.decimal :price
      t.string :currency
      t.string :image_url
      t.text :notes
      t.string :priority
      t.string :status

      t.timestamps
    end
  end
end
