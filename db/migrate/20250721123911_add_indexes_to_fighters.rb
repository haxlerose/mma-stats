class AddIndexesToFighters < ActiveRecord::Migration[8.0]
  def change
    # Index for alphabetical ordering with LOWER(name)
    add_index :fighters, "LOWER(name)", name: "idx_fighters_name_lower"
    
    # Index for regular name lookups (imports, etc.)
    add_index :fighters, :name, name: "idx_fighters_name"
    
    # Enable pg_trgm extension for GIN trigram index
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
    
    # GIN trigram index for ILIKE search patterns
    add_index :fighters, :name, using: :gin, opclass: :gin_trgm_ops, 
              name: "idx_fighters_name_gin"
  end
end
