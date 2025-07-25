class PopulateFighterSlugs < ActiveRecord::Migration[8.0]
  def up
    Fighter.find_each do |fighter|
      fighter.send(:generate_slug)
      fighter.save!(validate: false)
    end
  end

  def down
    Fighter.update_all(slug: nil)
  end
end
