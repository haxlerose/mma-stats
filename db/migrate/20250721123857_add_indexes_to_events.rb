class AddIndexesToEvents < ActiveRecord::Migration[8.0]
  def change
    # Index for ORDER BY date DESC in Events API
    add_index :events, :date, order: :desc, name: "idx_events_date_desc"
  end
end
