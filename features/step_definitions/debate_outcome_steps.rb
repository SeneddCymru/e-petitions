Given(/^a petition "(.*?)" has been debated (\d+) days ago?$/) do |petition_action, debated_days_ago|
  @petition = FactoryBot.create(:debated_petition,
    action: petition_action,
    debated_on: debated_days_ago.days.ago.to_date,
    overview: 'Everyone was in agreement, this petition must be made law!',
    transcript_url: 'https://record.assembly.wales/Plenary/5667#A51756',
    video_url: 'http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True',
    debate_pack_url: 'https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667'
  )
  @petition.update(debate_outcome_at: debated_days_ago.days.ago)
end

Given(/^a petition "(.*?)" has been debated yesterday$/) do |petition_action|
  @petition = FactoryBot.create(:open_petition,
    action: petition_action,
    scheduled_debate_date: 1.day.ago,
    debate_state: 'debated'
  )
end

Then(/^I should see the date of the debate is (\d+) days ago$/) do |debated_days_ago|
  within :css, '.debate-outcome' do
    expect(page).to have_content("This topic was debated on #{debated_days_ago.days.ago.to_date.strftime('%-d %B %Y')}")
  end
end

Then(/^I should see links to the transcript, video and research$/) do
  within :css, '.debate-outcome' do
    expect(page).to have_link('Watch the debate', href: 'http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True')
    expect(page).to have_link('Read the transcript', href: 'https://record.assembly.wales/Plenary/5667#A51756')
    expect(page).to have_link('Find details of the petition', href: 'https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667')
  end
end

Then(/^I should see a summary of the debate outcome$/) do
  within :css, '.debate-outcome' do
    expect(page).to have_content('Everyone was in agreement, this petition must be made law!')
  end
end

Then(/^the petition should not have debate details$/) do
  @petition.reload
  expect(@petition.debate_outcome).to be_nil
end

When(/^I fill in the debate outcome details$/) do
  fill_in 'Debated on', with: '18/12/2014'
  fill_in 'Overview (English)', with: 'Lots of people spoke about it, no consensus achieved.'
  fill_in 'Transcript URL (English)', with: 'https://record.assembly.wales/Plenary/5667#A51756'
  fill_in 'Video URL (English)', with: 'http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True'
  fill_in 'Debate Pack URL (English)', with: 'https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667'
end

Then(/^the petition should have the debate details I provided$/) do
  @petition.reload
  expect(@petition.debate_outcome).to be_present
  expect(@petition.debate_outcome).to be_persisted
  expect(@petition.debate_outcome.debated_on).to eq '18/12/2014'.to_date
  expect(@petition.debate_outcome.overview).to eq 'Lots of people spoke about it, no consensus achieved.'
  expect(@petition.debate_outcome.transcript_url).to eq 'https://record.assembly.wales/Plenary/5667#A51756'
  expect(@petition.debate_outcome.video_url).to eq 'http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True'
  expect(@petition.debate_outcome.debate_pack_url).to eq 'https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667'
end

Then(/^the petition creator should have been emailed about the debate$/) do
  @petition.reload
  steps %Q(
    Then "#{@petition.creator.email}" should receive an email
    When they open the email
    Then they should see "Senedd debated your petition" in the email body
    When they follow "#{petition_url(@petition)}" in the email
    Then I should be on the petition page for "#{@petition.action}"
  )
end

Then(/^all the signatories of the petition should have been emailed about the debate$/) do
  @petition.reload
  @petition.signatures.validated.subscribed.where.not(id: @petition.creator.id).each do |signatory|
    steps %Q(
      Then "#{signatory.email}" should receive an email
      When they open the email
      Then they should see "Senedd debated the petition you signed" in the email body
      When they follow "#{petition_url(@petition)}" in the email
      Then I should be on the petition page for "#{@petition.action}"
    )
  end
end
