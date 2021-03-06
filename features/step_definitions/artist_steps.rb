Given /^a signed in artist with a new song$/ do
  steps %Q{
    Given a user with songs
    When I am on the signin page
    And  I provide credentials
    And  I click a song
    And  I see the song
  }
end

Given(/^an artist on the new song page$/) do
  visit new_song_path
end

Given(/^there is a midi output available$/) do
  # result = page.evaluate_script("Midi.connect();")
  sleep(0.05) #connect is async, takes a small amount of time!
end

When(/^I set the tempo very high in order to shrink the test$/) do
  command = ":set tempo=6000"

  command.chars.each do |char|
    page.execute_script("EVENT_TRIGGERS.downKey('#{char}')")
  end

  page.execute_script("EVENT_TRIGGERS.downKey('\\r')")
end

When(/^I type the "(.*)" (command|sequence)$/) do |command, _|
  command.chars.each do |char|
    page.execute_script("EVENT_TRIGGERS.downKey('#{char}')")
  end

  page.execute_script("EVENT_TRIGGERS.downKey('\\r')")
end

When "I log the song" do
  page.execute_script("console.log(JSON.stringify(SONG_STATE))")
end

When(/I hit enter/) do
  page.execute_script("EVENT_TRIGGERS.downKey('\\r')")
end

When(/I hit escape/) do
  page.execute_script("EVENT_TRIGGERS.downKey('ESC')")
end

Then(/^I see the value of the "(.*?)" setting is (\d+)$/) do |setting_name, number|
  within 'commandLine' do
    expect(page).to have_content "#{setting_name}=#{number}"
  end
end

Then(/^I see the command result "(.*?)"$/) do |result|
  within 'commandLine' do
    expect(page).to have_content result
  end
end

Then(/^I see that section "(\d*)" is active$/) do |active_section_id|
  section = find("grids")
  expect(section['data-section-id']).to eq active_section_id
end

Then(/^I see that part "(.*?)" is active$/) do |active_part_id|
  part = find("grids part")
  expect(part['data-part-id']).to eq active_part_id
end

When(/^I move to middle C and I create a note$/) do
  type("mc")
  type("cn")
end

When(/^I move to middle A and I create a note$/) do
  type("ma")
  type("cn")
end


Then /^I hear the song \(via midi\)$/ do
  @midi_destination.collect()
  @midi_destination.expect(2)
  packets = @midi_destination.finish()
  expect(packets.count).to eq 2

  on_message = packets.first
  off_message = packets.second
  note_length = off_message[:timestamp] - on_message[:timestamp]

  expect(note_length.round).to eq 10

  expect_midi_message(on_message, on = 9, 1, 64, 80)
  expect_midi_message(off_message, off = 8, 1, 64, 80)
end

Then /^I hear the song interrupted by the space bar$/ do
  @midi_destination.collect()
  @midi_destination.expect(2)
  sleep 0.25 and steps("Then I press the space bar")
  packets = @midi_destination.finish()
  expect(packets.count).to eq 2

  on_message = packets.first
  off_message = packets.second
  note_length = off_message[:timestamp] - on_message[:timestamp]

  expect_midi_message(on_message, on = 9, 1, 64, 80)
  expect_midi_message(off_message, off = 8, 1, 64, 80)

  expect(0..500).to cover note_length.round
end

Then /^I hear the song with two notes$/ do
  @midi_destination.collect()
  @midi_destination.expect(4)
  packets = @midi_destination.finish()
  expect(packets.count).to eq 4

  on_message = packets.first
  off_message = packets.second
  note_length = off_message[:timestamp] - on_message[:timestamp]

  expect(note_length.round).to eq 10

  expect_midi_message(on_message, on = 9, 1, 64, 80)
  expect_midi_message(off_message, off = 8, 1, 64, 80)

  on_message = packets[2]
  off_message = packets[3]
  note_length = off_message[:timestamp] - on_message[:timestamp]

  expect(note_length.round).to eq 10

  expect_midi_message(on_message, on = 9, 1, 64, 80)
  expect_midi_message(off_message, off = 8, 1, 64, 80)
end

Then(/^I hear the song looped twice|I hear the song with both sections$/) do
  @midi_destination.collect()
  @midi_destination.expect(4)
  packets = @midi_destination.finish()
  expect(packets.count).to eq 4

  on_packets = packets.select {|p| p[:data][0] == 145}
  on_message = on_packets.first
  looped_on_message = on_packets.second
  distance_between_loops = looped_on_message[:timestamp] - on_message[:timestamp]

  expect(distance_between_loops.round).to eq 40
end

Then(/^I hear the each section of the song \(and the second section looped\)$/) do
  @midi_destination.collect()
  @midi_destination.expect(6)
  packets = @midi_destination.finish()
  expect(packets.count).to eq 6

  on_packets = packets.select {|p| p[:data][0] == 145}

  expect_midi_message(on_packets[0], on = 9, 1, 69, 80)
  expect_midi_message(on_packets[1], on = 9, 1, 60, 80)
  expect_midi_message(on_packets[2], on = 9, 1, 60, 80)
end

Then(/^I hear the note 20 times with 10 ms intervals$/) do
  @midi_destination.collect()
  @midi_destination.expect(40)
  packets = @midi_destination.finish()
  expect(packets.count).to eq 40

  on_packets = packets.select {|p| p[:data][0] == 145}

  timestamps = on_packets.map { |note| note[:timestamp] }
  time_differences = timestamps.each_cons(2).map {|a, b| (b - a).round}

  time_differences.each_with_index do |diff, i|
    expect(diff).to(eq(10), "The #{i}th note was out of sync")
  end
end

Then(/^I hear a note on each channel$/) do
  @midi_destination.collect()
  @midi_destination.expect(4)
  packets = @midi_destination.finish()
  expect(packets.count).to eq 4

  on_packets = packets.select {|p| (p[:data][0] >> 4) == 9}

  expect_midi_message(on_packets[0], on = 9, 2, 60, 80)
  expect_midi_message(on_packets[1], on = 9, 3, 60, 80)
end

Then(/^I hear the first part repeated (\d+) times$/) do |repititions|
  @midi_destination.collect()
  @midi_destination.expect(8)
  packets = @midi_destination.finish()
  expect(packets.count).to eq 8

  on_packets = packets.select {|p| (p[:data][0] >> 4) == 9}
  off_packets = packets.select {|p| (p[:data][0] >> 4) == 8}

  repititions.to_i.times do |i|
    expect_midi_message(on_packets[i], on = 9, 1, 60, 80)
    expect_midi_message(off_packets[i], on = 8, 1, 60, 80)
  end
end
