class CreateFightStats < ActiveRecord::Migration[8.0]
  def change
    create_table :fight_stats do |t|
      t.references :fight, null: false, foreign_key: true
      t.references :fighter, null: false, foreign_key: true
      t.integer :round
      t.integer :knockdowns
      t.integer :significant_strikes
      t.integer :significant_strikes_attempted
      t.integer :total_strikes
      t.integer :total_strikes_attempted
      t.integer :takedowns
      t.integer :takedowns_attempted
      t.integer :submission_attempts
      t.integer :reversals
      t.integer :control_time_seconds
      t.integer :head_strikes
      t.integer :head_strikes_attempted
      t.integer :body_strikes
      t.integer :body_strikes_attempted
      t.integer :leg_strikes
      t.integer :leg_strikes_attempted
      t.integer :distance_strikes
      t.integer :distance_strikes_attempted
      t.integer :clinch_strikes
      t.integer :clinch_strikes_attempted
      t.integer :ground_strikes
      t.integer :ground_strikes_attempted

      t.timestamps
    end
  end
end
