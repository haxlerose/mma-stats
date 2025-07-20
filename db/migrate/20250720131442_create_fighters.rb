class CreateFighters < ActiveRecord::Migration[8.0]
  def change
    create_table :fighters do |t|
      t.string :name, null: false
      t.integer :height_in_inches
      t.integer :reach_in_inches
      t.date :birth_date

      t.timestamps
    end
  end
end
