Then(/^I see a cursor in the top left corner$/) do
  expect(cursor).to have_a_position_of(0, 60)
end

When /^I press the space bar$/ do
  GC.disable
  page.execute_script("EVENT_TRIGGERS.downKey(' ')")
end

When(/^I press '(\w)'$/) do |char|
  page.execute_script("EVENT_TRIGGERS.downKey('#{char}')")
end

Then /^I see the cursor has moved (down|up|right|left)$/ do |direction|
  positions = {
    down: {start: 0, pitch: 59},
    up: {start: 0, pitch: 60},
    right: {start: 96, pitch: 60},
    left: {start: 0, pitch: 60}
  }

  position = positions[direction.to_sym]
  expect(cursor).to have_a_position_of(position[:start], position[:pitch])
end

Then /^I see that the cursor has not moved$/ do
  expect(cursor).to have_a_position_of(0, 0)
end

Then(/^I see a new note$/) do
  expect(page).to have_selector("note[data-start='0'][data-pitch='59']")
end

Then(/^I see only one note$/) do
  expect(page).to have_selector("note", count: 1)
end

Then(/^I see a note at beat (\d*) and pitch (\d*)$/) do |beat, pitch|
  notes = all('note').map {|n| {beat: n['data-start'].to_i, pitch: n['data-pitch'].to_i}}

  expect(notes).to include({beat: beat.to_i * 96, pitch: pitch.to_i})
end

Then(/^I see the cursor at beat (\d*) and pitch (\d*)$/) do |beat, pitch|
  expect(cursor).to have_a_position_of(beat.to_i * 96, pitch)
end

Then(/^I see a note with length "(.*?)"$/) do |length|
  note = page.find('note')
  expect(note['data-length']).to eq length
end

Then(/^I see "(\d*)" notes with length "(.*?)"$/) do |note_count, length|
  selector = "note[data-length='#{length}']"
  expect(page).to have_selector(selector, count: note_count.to_i)
end

Then(/^I see a new note with pitch "(\d*)"$/) do |pitch|
  expect(page).to have_selector("note[data-pitch='#{pitch}']")
end

Then(/^I see the cursor is at middle c$/) do
  expect(cursor).to have_a_position_of(0, 60)
end

Then(/^I see the cursor is at middle d$/) do
  expect(cursor).to have_a_position_of(0, 62)
end

When(/^I type a sequence then I see the cursor at the right pitch:$/) do |table|
  table.hashes.each do |row|
    type(row[:sequence])
    expect(cursor).to have_a_position_of(0, row[:midipitch])
  end
end
