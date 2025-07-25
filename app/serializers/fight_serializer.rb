# frozen_string_literal: true

class FightSerializer
  include FightStatSerialization

  def self.with_full_details(fight)
    new(fight).with_full_details
  end

  def initialize(fight)
    @fight = fight
  end

  def with_full_details
    basic_attrs = %i[id bout outcome weight_class method round time referee]
    @fight.as_json(only: basic_attrs).merge(
      event: serialize_event,
      fighters: serialize_fighters,
      fight_stats: serialize_fight_stats
    )
  end

  private

  def serialize_event
    @fight.event.as_json(only: %i[id name date location])
  end

  def serialize_fighters
    @fight.fighters.map do |fighter|
      fighter.as_json(
        only: %i[id
                 slug
                 name
                 height_in_inches
                 reach_in_inches
                 birth_date]
      )
    end
  end

  def serialize_fight_stats
    @fight.fight_stats.map { |stat| build_stat_attributes(stat) }
  end

  def build_stat_attributes(stat)
    {
      fighter_id: stat.fighter.id,
      fighter_slug: stat.fighter.slug,
      fighter_name: stat.fighter.name,
      round: stat.round,
      knockdowns: stat.knockdowns
    }.merge(
      striking_attributes(stat)
    ).merge(
      grappling_attributes(stat)
    )
  end
end
