# frozen_string_literal: true

require "test_helper"

class Api::V1::FightersControllerTest < ActionDispatch::IntegrationTest
  test "should get fighters index" do
    get api_v1_fighters_url
    assert_response :success
  end

  test "should return fighters ordered alphabetically by name" do
    # Create fighters with different names
    Fighter.create!(name: "Zion Clark")
    Fighter.create!(name: "Anderson Silva")
    Fighter.create!(name: "Michael Jordan")

    get api_v1_fighters_url
    response_data = response.parsed_body
    fighters = response_data["fighters"]

    # First fighter should be Anderson Silva (alphabetically first)
    assert_equal "Anderson Silva", fighters.first["name"]
    assert_equal "Michael Jordan", fighters.second["name"]
    assert_equal "Zion Clark", fighters.last["name"]
    
    # Should include pagination metadata
    assert_not_nil response_data["meta"]
    assert_equal 3, response_data["meta"]["total_count"]
  end

  test "should order fighters case-insensitively" do
    # Create fighters with mixed case names
    Fighter.create!(name: "AJ Dobson")
    Fighter.create!(name: "Aaron Pico")
    Fighter.create!(name: "alex smith")
    Fighter.create!(name: "ANDRE Johnson")

    get api_v1_fighters_url
    response_data = response.parsed_body
    fighters = response_data["fighters"]
    names = fighters.map { |f| f["name"] }

    # Should be ordered: Aaron Pico, AJ Dobson, alex smith, ANDRE Johnson
    expected_order = ["Aaron Pico", "AJ Dobson", "alex smith", "ANDRE Johnson"]
    assert_equal expected_order, names
  end

  test "should return fighters with correct JSON structure" do
    fighter = Fighter.create!(
      name: "Conor McGregor",
      height_in_inches: 69,
      reach_in_inches: 74,
      birth_date: Date.new(1988, 7, 14)
    )

    get api_v1_fighters_url
    response_data = response.parsed_body
    fighters = response_data["fighters"]
    first_fighter = fighters.first

    # Test that each fighter has the expected structure
    assert_includes first_fighter, "id"
    assert_includes first_fighter, "name"
    assert_includes first_fighter, "height_in_inches"
    assert_includes first_fighter, "reach_in_inches"
    assert_includes first_fighter, "birth_date"

    # Test that values are correct
    assert_equal fighter.id, first_fighter["id"]
    assert_equal "Conor McGregor", first_fighter["name"]
    assert_equal 69, first_fighter["height_in_inches"]
    assert_equal 74, first_fighter["reach_in_inches"]
    assert_equal "1988-07-14", first_fighter["birth_date"]

    # Test that we don't include timestamps in the API response
    assert_not_includes first_fighter, "created_at"
    assert_not_includes first_fighter, "updated_at"
  end

  test "should search fighters by name" do
    Fighter.create!(name: "Conor McGregor")
    Fighter.create!(name: "Nate Diaz")
    Fighter.create!(name: "Anderson Silva")

    get api_v1_fighters_url(search: "Conor")
    response_data = response.parsed_body
    fighters = response_data["fighters"]

    assert_equal 1, fighters.length
    assert_equal "Conor McGregor", fighters.first["name"]
  end

  test "should search fighters case insensitively" do
    Fighter.create!(name: "Conor McGregor")
    Fighter.create!(name: "Anderson Silva")

    get api_v1_fighters_url(search: "conor")
    response_data = response.parsed_body
    fighters = response_data["fighters"]

    assert_equal 1, fighters.length
    assert_equal "Conor McGregor", fighters.first["name"]
  end

  test "should search fighters by partial name" do
    Fighter.create!(name: "Conor McGregor")
    Fighter.create!(name: "Connor Stevens")
    Fighter.create!(name: "Anderson Silva")

    get api_v1_fighters_url(search: "Connor")
    response_data = response.parsed_body
    fighters = response_data["fighters"]

    assert_equal 1, fighters.length
    assert_equal "Connor Stevens", fighters.first["name"]
  end

  test "should maintain alphabetical order when searching" do
    Fighter.create!(name: "Zach Anderson")
    Fighter.create!(name: "Bob Anderson")
    Fighter.create!(name: "Alice Anderson")

    get api_v1_fighters_url(search: "Anderson")
    response_data = response.parsed_body
    fighters = response_data["fighters"]

    assert_equal 3, fighters.length
    assert_equal "Alice Anderson", fighters.first["name"]
    assert_equal "Bob Anderson", fighters.second["name"]
    assert_equal "Zach Anderson", fighters.last["name"]
  end

  test "should return all fighters when search is empty" do
    Fighter.create!(name: "Fighter A")
    Fighter.create!(name: "Fighter B")

    get api_v1_fighters_url(search: "")
    response_data = response.parsed_body
    fighters = response_data["fighters"]

    assert_equal 2, fighters.length
  end

  test "should get single fighter" do
    fighter = Fighter.create!(
      name: "Jon Jones",
      height_in_inches: 76,
      reach_in_inches: 84,
      birth_date: Date.new(1987, 7, 19)
    )

    get api_v1_fighter_url(fighter)
    assert_response :success
  end

  test "should include fighter's fights with event data and fight stats" do
    # Create fighter
    fighter = Fighter.create!(name: "Daniel Cormier")

    # Create events
    event1 = Event.create!(
      name: "UFC 182",
      date: Date.new(2015, 1, 3),
      location: "Las Vegas, NV"
    )
    event2 = Event.create!(
      name: "UFC 200",
      date: Date.new(2016, 7, 9),
      location: "Las Vegas, NV"
    )

    # Create fights
    fight1 = Fight.create!(
      event: event1,
      bout: "Jon Jones vs Daniel Cormier",
      outcome: "Jon Jones wins",
      weight_class: "Light Heavyweight"
    )
    fight2 = Fight.create!(
      event: event2,
      bout: "Daniel Cormier vs Anderson Silva",
      outcome: "Daniel Cormier wins",
      weight_class: "Light Heavyweight"
    )

    # Create fight stats for the fighter
    FightStat.create!(
      fight: fight1,
      fighter: fighter,
      round: 1,
      significant_strikes: 10,
      significant_strikes_attempted: 15,
      takedowns: 2,
      takedowns_attempted: 3
    )
    FightStat.create!(
      fight: fight1,
      fighter: fighter,
      round: 2,
      significant_strikes: 8,
      significant_strikes_attempted: 12,
      takedowns: 1,
      takedowns_attempted: 2
    )
    FightStat.create!(
      fight: fight2,
      fighter: fighter,
      round: 1,
      significant_strikes: 15,
      significant_strikes_attempted: 20,
      takedowns: 0,
      takedowns_attempted: 1
    )

    get api_v1_fighter_url(fighter)
    response_data = response.parsed_body
    fighter_data = response_data["fighter"]

    # Test that fighter includes fights
    assert_includes fighter_data, "fights"
    fights = fighter_data["fights"]
    assert_equal 2, fights.length

    # Test first fight structure and event data
    first_fight = fights.find { |f| f["event"]["name"] == "UFC 182" }
    assert_not_nil first_fight
    assert_equal "Jon Jones vs Daniel Cormier", first_fight["bout"]
    assert_equal "Jon Jones wins", first_fight["outcome"]
    assert_equal "Light Heavyweight", first_fight["weight_class"]

    # Test event data is included
    assert_includes first_fight, "event"
    event_data = first_fight["event"]
    assert_equal "UFC 182", event_data["name"]
    assert_equal "2015-01-03", event_data["date"]

    # Test fight stats are included
    assert_includes first_fight, "fight_stats"
    fight_stats = first_fight["fight_stats"]
    assert_equal 2, fight_stats.length

    # Test fight stats structure
    round_1_stats = fight_stats.find { |s| s["round"] == 1 }
    assert_not_nil round_1_stats
    assert_equal 10, round_1_stats["significant_strikes"]
    assert_equal 15, round_1_stats["significant_strikes_attempted"]
    assert_equal 2, round_1_stats["takedowns"]
    assert_equal 3, round_1_stats["takedowns_attempted"]
  end

  test "should return 404 for non-existent fighter" do
    get api_v1_fighter_url(99_999)
    assert_response :not_found
  end

  test "should paginate fighters with default per_page" do
    # Create 25 fighters to test pagination
    25.times do |i|
      Fighter.create!(name: "Fighter #{format('%02d', i)}")
    end

    get api_v1_fighters_url
    response_data = response.parsed_body

    assert_equal 20, response_data["fighters"].length # Default per_page
    assert_equal 1, response_data["meta"]["current_page"]
    assert_equal 2, response_data["meta"]["total_pages"]
    assert_equal 25, response_data["meta"]["total_count"]
    assert_equal 20, response_data["meta"]["per_page"]
  end

  test "should paginate fighters with custom per_page" do
    # Create 15 fighters
    15.times do |i|
      Fighter.create!(name: "Fighter #{format('%02d', i)}")
    end

    get api_v1_fighters_url(per_page: 5)
    response_data = response.parsed_body

    assert_equal 5, response_data["fighters"].length
    assert_equal 1, response_data["meta"]["current_page"]
    assert_equal 3, response_data["meta"]["total_pages"]
    assert_equal 15, response_data["meta"]["total_count"]
    assert_equal 5, response_data["meta"]["per_page"]
  end

  test "should return correct page of fighters" do
    # Create 10 fighters with predictable names
    10.times do |i|
      Fighter.create!(name: "Fighter #{format('%02d', i)}")
    end

    get api_v1_fighters_url(page: 2, per_page: 3)
    response_data = response.parsed_body

    assert_equal 3, response_data["fighters"].length
    assert_equal 2, response_data["meta"]["current_page"]
    
    # Check we have the correct fighters (alphabetically sorted)
    fighter_names = response_data["fighters"].map { |f| f["name"] }
    assert_equal ["Fighter 03", "Fighter 04", "Fighter 05"], fighter_names
  end

  test "should handle pagination with search" do
    # Create fighters with different names
    Fighter.create!(name: "Anderson Silva")
    Fighter.create!(name: "Anderson Cooper")
    Fighter.create!(name: "Silva Jones")
    Fighter.create!(name: "John Smith")
    Fighter.create!(name: "Jane Doe")

    get api_v1_fighters_url(search: "Anderson", per_page: 1)
    response_data = response.parsed_body

    assert_equal 1, response_data["fighters"].length
    assert_equal "Anderson Cooper", response_data["fighters"].first["name"]
    assert_equal 2, response_data["meta"]["total_count"] # Anderson Silva and Anderson Cooper
    assert_equal 2, response_data["meta"]["total_pages"]
  end
end
