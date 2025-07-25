class AddSlugToFighters < ActiveRecord::Migration[8.0]
  def change
    add_column :fighters, :slug, :string
    add_index :fighters, :slug, unique: true
  end
end
