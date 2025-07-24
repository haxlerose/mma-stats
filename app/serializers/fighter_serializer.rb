# frozen_string_literal: true

class FighterSerializer
  include FightStatSerialization

  def self.for_index(fighter)
    {
      id: fighter.id,
      name: fighter.name,
      height_in_inches: fighter.height_in_inches,
      reach_in_inches: fighter.reach_in_inches,
      birth_date: fighter.birth_date
    }
  end

  def self.with_fight_details(fighter)
    new(fighter).with_fight_details
  end

  def initialize(fighter)
    @fighter = fighter
  end

  def with_fight_details
    fights_data = @fighter.fight_stats.group_by(&:fight).map do |fight, stats|
      serialize_fight_with_stats(fight, stats)
    end

    self.class.for_index(@fighter).merge(
      fights: fights_data
    )
  end

  private

  def serialize_fight_with_stats(fight, stats)
    {
      id: fight.id,
      bout: fight.bout,
      outcome: fight.outcome,
      weight_class: fight.weight_class,
      method: fight.method,
      round: fight.round,
      time: fight.time,
      referee: fight.referee,
      event: serialize_event_for_fight(fight.event),
      fight_stats: serialize_fight_stats(stats)
    }
  end

  def serialize_event_for_fight(event)
    {
      id: event.id,
      name: event.name,
      date: event.date
    }
  end

  def serialize_fight_stats(stats)
    stats.map { |stat| fight_stat_attributes(stat) }
  end

  def fight_stat_attributes(stat)
    {
      round: stat.round,
      knockdowns: stat.knockdowns
    }.merge(
      striking_attributes(stat)
    ).merge(
      grappling_attributes(stat)
    )
  end
end
