class CreateFights < ActiveRecord::Migration[8.0]
  def change
    create_table :fights do |t|
      t.references :event, null: false, foreign_key: true
      t.string :bout
      t.string :outcome
      t.string :weight_class
      t.string :method
      t.integer :round
      t.string :time
      t.string :time_format
      t.string :referee
      t.text :details

      t.timestamps
    end
  end
end
