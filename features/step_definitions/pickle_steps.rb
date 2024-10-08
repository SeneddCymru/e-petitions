Given(/^a sysadmin user exists with first_name: "([^"]*)", last_name: "([^"]*)", email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |first_name, last_name, email, password, password_confirmation|
  @user = FactoryBot.create(:sysadmin_user, first_name: first_name, last_name: last_name, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with first_name: "([^"]*)", last_name: "([^"]*)", email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |first_name, last_name, email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)"$/) do |email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, email: email, password: password, password_confirmation: password_confirmation)
end

Given(/^a moderator user exists with email: "([^"]*)", password: "([^"]*)", password_confirmation: "([^"]*)", force_password_reset: true$/) do |email, password, password_confirmation|
  @user = FactoryBot.create(:moderator_user, email: email, password: password, password_confirmation: password_confirmation, force_password_reset: true)
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)"$/) do |email, first_name, last_name|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email)
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)", failed_login_count: (\d+)$/) do |email, first_name, last_name, failed_login_count|
  @user = FactoryBot.create(:moderator_user, first_name: first_name, last_name: last_name, email: email, failed_login_count: failed_login_count)
end

Given(/^(\d+) moderator users exist$/) do |number|
  number.times do |count|
    FactoryBot.create(:moderator_user)
  end
end

Given(/^(\d+) petitions exist with state: "([^"]*)"$/) do |number, state|
  number.times do |count|
    FactoryBot.create(:petition, state: state)
  end
end

When(/^a moderator user should exist with email: "([^"]*)", failed_login_count: "([^"]*)"$/) do |email, failed_login_count|
  expect(AdminUser.where(email: email, failed_login_count: failed_login_count)).to exist
end

Given(/^a moderator user exists with email: "([^"]*)", first_name: "([^"]*)", last_name: "([^"]*)", failed_login_count: "([^"]*)"$/) do |email, first_name, last_name, failed_login_count|
  @user = FactoryBot.create(:moderator_user, email: email, first_name: first_name, last_name: last_name, failed_login_count: failed_login_count)
end

Then(/^a admin user should not exist with email: "([^"]*)"$/) do |email|
  expect(AdminUser.where(email: email)).not_to exist
end

Given(/^an open petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:open_petition, action: action)
end

Given(/^a referred petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:referred_petition, action: action)
end

Given(/^a rejected petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:rejected_petition, action: action)
end

Given(/^a hidden petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:hidden_petition, action: action)
end

Then(/^a validated signature should exist with name: "([^"]*)", location_code: "([^"]*)", postcode: "([^"]*)"$/) do |name, location_code, postcode|
  expect(Signature.where(name: name, location_code: location_code, postcode: postcode)).to exist
end

Given(/^a sponsored petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:sponsored_petition, action: action)
end

Then(/^a petition should exist with action: "([^"]*)", state: "([^"]*)"$/) do |action, state|
  expect(Petition.where(action: action, state: state)).to exist
end

Then('a petition exists with state: {string}, action_en: {string}, action_cy: {string}, closed_at: {string}') do |state, action_en, action_cy, closed_at|
  expect(Petition.where(state: state, action_en: action_en, action_cy: action_cy, closed_at: closed_at)).to exist
end

Then(/^a signature exists with state: "([^"]*)", name: "([^"]*)", email: "([^"]*)", postcode: "([^"]*)"$/) do |state, name, email, postcode|
  expect(Signature.where(state: state, name: name, email: email, postcode: postcode)).to exist
end

Then(/^a contact exists with address: "([^"]*)", phone_number: "([^"]*)"$/) do |address, phone_number|
  @contact = FactoryBot.create(:contact, address: address, phone_number: phone_number)
end

Given(/^a tag exists with name: "([^"]*)"$/) do |name|
  @tag = FactoryBot.create(:tag, name: name)
end

Given(/^an sponsored petition exists with action: "([^"]*)"$/) do |action|
  @petition = FactoryBot.create(:sponsored_petition, action: action)
end

Given(/^an open petition exists with action_en: "([^"]*)", background_en: "([^"]*)", action_cy: "([^"]*)", background_cy: "([^"]*)"$/) do |action_en, background_en, action_cy, background_cy|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, action_cy: action_cy, background_en: background_en, background_cy: background_cy)
end

Given('a closed petition exists with action: {string}') do |action|
  @petition = FactoryBot.create(:closed_petition, action: action)
end

Given(/^an open petition exists with action: "([^"]*)", background: "([^"]*)"$/) do |action, background|
  @petition = FactoryBot.create(:open_petition, action: action, background: background)
end

Given(/^a pending petition exists with action_en: "([^"]*)", action_cy: "([^"]*)"$/) do |action_en, action_cy|
  @petition = FactoryBot.create(:pending_petition, action_en: action_en, action_cy: action_cy)
end

Given(/^a validated petition exists with action_en: "([^"]*)", action_cy: "([^"]*)"$/) do |action_en, action_cy|
  @petition = FactoryBot.create(:validated_petition, action_en: action_en, action_cy: action_cy)
end

Given('an open petition exists with action_en: {string}, additional_details: {string}, action_cy: {string}, additional_details_cy: {string}, closed_at: {timestamp}') do |action_en, additional_details, action_cy, additional_details_cy, closed_at|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, additional_details: additional_details, action_cy: action_cy, additional_details_cy: additional_details_cy, closed_at: closed_at)
end

Given('an open petition exists with action_en: {string}, background: {string}, action_cy: {string}, background_cy: {string}, closed_at: {timestamp}') do |action_en, background, action_cy, background_cy, closed_at|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, background: background, action_cy: action_cy, background_cy: background_cy, closed_at: closed_at)
end

Given('an open petition exists with action_en: {string}, action_cy: {string}, closed_at: {timestamp}') do |action_en, action_cy, closed_at|
  @petition = FactoryBot.create(:open_petition, action_en: action_en, action_cy: action_cy, closed_at: closed_at)
end

Given('a referred petition exists with action_en: {string}, action_cy: {string}, closed_at: {timestamp}') do |action_en, action_cy, closed_at|
  @petition = FactoryBot.create(:referred_petition, action_en: action_en, action_cy: action_cy, closed_at: closed_at)
end

Given(/^a rejected petition exists with action_en: "([^"]*)", action_cy: "([^"]*)"$/) do |action_en, action_cy|
  @petition = FactoryBot.create(:rejected_petition, action_en: action_en, action_cy: action_cy)
end

Given(/^a hidden petition exists with action_en: "([^"]*)", action_cy: "([^"]*)"$/) do |action_en, action_cy|
  @petition = FactoryBot.create(:hidden_petition, action_en: action_en, action_cy: action_cy)
end

Then(/^a petition should exist with action_en: "([^"]*)", action_cy: nil, state: "([^"]*)", locale: "([^"]*)"$/) do |action_en, state, locale|
  expect(Petition.where(action_en: action_en, action_cy: nil, state: state, locale: locale)).to exist
end

Then(/^a petition should exist with action_cy: "([^"]*)", action_en: nil, state: "([^"]*)", locale: "([^"]*)"$/) do |action_cy, state, locale|
  expect(Petition.where(action_en: nil, action_cy: action_cy, state: state, locale: locale)).to exist
end

Then(/^a signature should exist with email: "([^"]*)", state: "([^"]*)"$/) do |email, state|
  expect(Signature.where(email: email, state: state)).to exist
end

Then(/^a petition should not exist with action: "([^"]*)", state: "([^"]*)"$/) do |action, state|
  expect(Petition.where(action: action, state: state)).not_to exist
end

Then(/^a signature should not exist with email: "([^"]*)", state: "([^"]*)"$/) do |email, state|
  expect(Signature.where(email: email, state: state)).not_to exist
end

Given(/^(\d+) open petitions exist with action: "([^"]*)"$/) do |number, action|
  number.times do |count|
    FactoryBot.create(:open_petition, action: action)
  end
end

Given(/^an open petition exists with action: "([^"]*)", additional_details: "([^"]*)"$/) do |action, additional_details|
  @petition = FactoryBot.create(:open_petition, action: action, additional_details: additional_details)
end

Then(/^a feedback should not exist with comment: "([^"]*)"$/) do |comment|
  expect(Feedback.where(comment: comment)).not_to exist
end
