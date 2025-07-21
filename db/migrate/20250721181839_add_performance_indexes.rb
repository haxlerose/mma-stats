class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Index for filtering events by date (used in active fighter queries)
    add_index :events, :date unless index_exists?(:events, :date)

    # Composite index for fight_stats queries (fighter_id + fight relationship)  
    add_index :fight_stats, [:fighter_id, :fight_id] unless index_exists?(:fight_stats, [:fighter_id, :fight_id])

    # Index for fight_stats queries with event filtering
    add_index :fight_stats, :fight_id unless index_exists?(:fight_stats, :fight_id)

    # Optional: Index on fighters.name for search functionality
    add_index :fighters, :name unless index_exists?(:fighters, :name)
  end
end
