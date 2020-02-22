require 'factory_bot'
require 'active_support/core_ext/digest/uuid'

FactoryBot.define do
  factory :admin_user do
    sequence(:email) {|n| "admin#{n}@example.com" }
    password              "Letmein1!"
    password_confirmation "Letmein1!"
    sequence(:first_name) {|n| "AdminUser#{n}" }
    sequence(:last_name) {|n| "AdminUser#{n}" }
    force_password_reset  false
  end

  factory :sysadmin_user, :parent => :admin_user do
    role "sysadmin"
  end

  factory :moderator_user, :parent => :admin_user do
    role "moderator"
  end

  factory :petition do
    transient do
      admin_notes { nil }
      creator_name { nil }
      creator_email { nil }
      creator_attributes { {} }
      sponsors_signed nil
      sponsor_count { Site.minimum_number_of_sponsors }
    end

    sequence(:action) {|n| "Petition #{n}" }
    background "Petition background"

    after(:build) do |petition, evaluator|
      petition.creator ||= FactoryBot.build(:validated_signature, creator: true)
      petition.creator.assign_attributes(evaluator.creator_attributes)

      if evaluator.creator_name
        petition.creator.name = evaluator.creator_name
      end

      if evaluator.creator_email
        petition.creator.email = evaluator.creator_email
      end

      if evaluator.admin_notes
        petition.build_note details: evaluator.admin_notes
      end
    end

    after(:create) do |petition, evaluator|
      if petition.signature_count.zero?
        petition.increment!(:signature_count) if petition.creator.validated?
      end

      unless evaluator.sponsors_signed.nil?
        evaluator.sponsor_count.times do
          if evaluator.sponsors_signed
            FactoryBot.create(:sponsor, :validated, petition: petition, validated_at: 10.seconds.ago)
          else
            FactoryBot.create(:sponsor, :pending, petition: petition)
          end
        end

        petition.update_signature_count!
      end
    end

    trait :with_additional_details do
      additional_details "Petition additional details"
    end

    trait :scheduled_for_debate do
      scheduled_debate_date { 10.days.from_now }
    end

    trait :email_requested do
      transient do
        email_requested_for_debate_scheduled_at { nil }
        email_requested_for_debate_outcome_at { nil }
        email_requested_for_petition_email_at { nil }
      end

      after(:build) do |petition, evaluator|
        petition.build_email_requested_receipt do |r|
          r.debate_scheduled = evaluator.email_requested_for_debate_scheduled_at
          r.debate_outcome = evaluator.email_requested_for_debate_outcome_at
          r.petition_email = evaluator.email_requested_for_petition_email_at
        end
      end
    end

    trait :tagged do
      transient do
        tag_name { nil }
      end

      after(:build) do |petition, evaluator|
        if evaluator.tag_name
          tag = create(:tag, name: evaluator.tag_name)
        else
          tag = create(:tag)
        end

        petition.tags = [tag.id]
      end
    end
  end

  factory :pending_petition, :parent => :petition do
    state Petition::PENDING_STATE

    after(:build) do |petition, evaluator|
      petition.creator.state = Signature::PENDING_STATE
      petition.creator.validated_at = nil
    end
  end

  factory :validated_petition, :parent => :petition do
    state  Petition::VALIDATED_STATE
  end

  factory :sponsored_petition, :parent => :petition do
    moderation_threshold_reached_at { Time.current }
    state  Petition::SPONSORED_STATE

    trait :overdue do
      moderation_threshold_reached_at { Site.moderation_overdue_in_days.ago - 5.minutes }
    end

    trait :nearly_overdue do
      moderation_threshold_reached_at { Site.moderation_overdue_in_days.ago + 5.minutes }
    end

    trait :recent do
      moderation_threshold_reached_at { Time.current }
    end
  end

  factory :flagged_petition, :parent => :petition do
    state  Petition::FLAGGED_STATE
  end

  factory :open_petition, :parent => :sponsored_petition do
    state  Petition::OPEN_STATE
    open_at { Time.current }

    transient do
      referred { false }
    end

    after(:build) do |petition, evaluator|
      if evaluator.referred
        petition.referral_threshold_reached_at = petition.open_at + 2.month
      end
    end
  end

  factory :closed_petition, :parent => :petition do
    state      Petition::CLOSED_STATE
    open_at    { 10.days.ago }
    closed_at  { 1.day.ago }
  end

  factory :rejected_petition, :parent => :petition do
    state Petition::REJECTED_STATE

    transient do
      rejection_code { "duplicate" }
      rejection_details { nil }
    end

    after(:create) do |petition, evaluator|
      petition.create_rejection! do |r|
        r.code = evaluator.rejection_code
        r.details = evaluator.rejection_details
      end
    end
  end

  factory :hidden_petition, :parent => :petition do
    state Petition::HIDDEN_STATE
  end

  factory :referred_petition, :parent => :closed_petition do
    referral_threshold_reached_at { 1.week.ago }
  end

  factory :awaiting_debate_petition, :parent => :open_petition do
    debate_threshold_reached_at { 1.week.ago }
    debate_state 'awaiting'
  end

  factory :scheduled_debate_petition, :parent => :open_petition do
    debate_threshold_reached_at { 1.week.ago }
    scheduled_debate_date { 1.week.from_now }
    debate_state 'scheduled'
  end

  factory :debated_petition, :parent => :open_petition do
    transient do
      debated_on { 1.day.ago }
      overview { nil }
      transcript_url { nil }
      video_url { nil }
      debate_pack_url { nil }
      commons_image { nil }
    end

    debate_state 'debated'

    after(:build) do |petition, evaluator|
      debate_outcome_attributes = { petition: petition }

      debate_outcome_attributes[:debated_on] = evaluator.debated_on if evaluator.debated_on.present?
      debate_outcome_attributes[:overview] = evaluator.overview if evaluator.overview.present?
      debate_outcome_attributes[:transcript_url] = evaluator.transcript_url if evaluator.transcript_url.present?
      debate_outcome_attributes[:video_url] = evaluator.video_url if evaluator.video_url.present?
      debate_outcome_attributes[:debate_pack_url] = evaluator.debate_pack_url if evaluator.debate_pack_url.present?
      debate_outcome_attributes[:commons_image] = evaluator.commons_image if evaluator.commons_image.present?

      petition.build_debate_outcome(debate_outcome_attributes)
    end
  end

  factory :not_debated_petition, :parent => :open_petition do
    after(:create) do |petition, evaluator|
      petition.create_debate_outcome(debated: false)
    end
  end

  factory :completed_petition, :parent => :closed_petition do
    completed_at { 1.week.ago }
  end

  factory :contact do
    association :signature
    phone_number { "0300 200 6565" }
    address { "Pierhead St, Cardiff" }
  end

  factory :signature do
    sequence(:name)  {|n| "Jo Public #{n}" }
    sequence(:email) {|n| "jo#{n}@public.com" }
    postcode              "SW1A 1AA"
    location_code         "GB"
    notify_by_email       "1"
    state                 Signature::VALIDATED_STATE

    after(:build) do |signature, evaluator|
      build(:contact, signature: signature) if signature.creator?
    end

    after(:create) do |signature, evaluator|
      if signature.petition && signature.validated?
        signature.petition.increment!(:signature_count)
        signature.increment!(:number)
      end
    end
  end

  factory :pending_signature, :parent => :signature do
    state      Signature::PENDING_STATE
  end

  factory :fraudulent_signature, :parent => :signature do
    state      Signature::FRAUDULENT_STATE
  end

  factory :validated_signature, :parent => :signature do
    state                         Signature::VALIDATED_STATE
    validated_at                  { Time.current }
    seen_signed_confirmation_page true

    trait :just_signed do
      seen_signed_confirmation_page false
    end
  end

  factory :invalidated_signature, :parent => :validated_signature do
    state                         Signature::INVALIDATED_STATE
    invalidated_at                { Time.current }
  end

  sequence(:sponsor_email) { |n| "sponsor#{n}@example.com" }

  factory :sponsor, parent: :pending_signature do
    sponsor true

    trait :pending do
      state "pending"
    end

    trait :validated do
      state "validated"
    end

    trait :just_signed do
      seen_signed_confirmation_page false
    end
  end

  sequence(:constituency_id) { |n| (1234 + n).to_s }
  sequence(:mp_id) { |n| (4321 + n).to_s }
  sequence(:ons_code) { |n| '%08d' % n }

  factory :constituency do
    trait(:england) do
      ons_code{ "E#{generate(:ons_code)}" }
    end

    trait(:scotland) do
      ons_code{ "S#{generate(:ons_code)}" }
    end

    trait(:wales) do
      ons_code{ "W#{generate(:ons_code)}" }
    end

    trait(:northern_ireland) do
      ons_code{ "N#{generate(:ons_code)}" }
    end

    trait(:coventry_north_east) do
      name "Coventry North East"
      slug "coventry-north-east"
      external_id "3427"
      ons_code "E14000649"
      mp_id "4378"
      mp_name "Colleen Fletcher MP"
      mp_date "2015-05-07"
      example_postcode "CV21PH"
    end

    trait(:bethnal_green_and_bow) do
      name "Bethnal Green and Bow"
      slug "bethnal-green-and-bow"
      external_id "3320"
      ons_code "E14000555"
      mp_id "4138"
      mp_name "Rushanara Ali MP"
      mp_date "2015-05-07"
      example_postcode "E27AX"
    end

    trait(:romford) do
      name "Romford"
      slug "romford"
      external_id "3703"
      ons_code "E14000900"
      mp_id "1447"
      mp_name "Andrew Rosindell"
      mp_date "2015-05-07"
      example_postcode "RM53FZ"
    end

    trait(:sheffield_brightside_and_hillsborough) do
      name "Sheffield, Brightside and Hillsborough"
      slug "sheffield-brightside-and-hillsborough"
      external_id "3724"
      ons_code "E14000921"
      mp_id "4571"
      mp_name "Gill Furniss"
      mp_date "2016-05-05"
      example_postcode "S61AR"
    end

    trait(:london_and_westminster) do
      name "Cities of London and Westminster"
      slug "cities-of-london-and-westminster"
      external_id "3415"
      ons_code "E14000639"
      mp_id "1405"
      mp_name "Rt Hon Mark Field MP"
      mp_date "2017-06-08"
      example_postcode "SW1A1AA"
    end

    england

    name { Faker::Address.county }
    external_id { generate(:constituency_id) }
    mp_name { "#{Faker::Name.name} MP" }
    mp_id { generate(:mp_id) }
    example_postcode { Faker::Address.postcode }
  end

  factory :constituency_petition_journal do
    constituency_id "3415"
    association :petition
  end

  factory :country_petition_journal do
    location_code "GB"
    association :petition
  end

  factory :debate_outcome do
    association :petition, factory: :open_petition
    debated_on { 1.month.from_now.to_date }
    debated true

    trait :fully_specified do
      overview { 'Debate on Petition P-05-869: Declare a Climate Emergency and fit all policies with zero-carbon targets' }
      sequence(:transcript_url) { |n|
        "https://record.assembly.wales/Plenary/5667#A51756"
      }
      video_url {
        "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True"
      }
      sequence(:debate_pack_url) { |n|
        "http://www.senedd.assembly.wales/ieListDocuments.aspx?CId=401&MId=5667"
      }
    end
  end

  factory :note do
    association :petition, factory: :petition
    details "Petition notes"
  end

  factory :petition_email, class: "Petition::Email" do
    association :petition, factory: :petition
    subject "Message Subject"
    body "Message body"
    sent_by "Admin User"
  end

  factory :petition_statistics, class: "Petition::Statistics" do
    association :petition, factory: :open_petition
  end

  factory :rejection do
    association :petition, factory: :validated_petition
    code "duplicate"
  end

  factory :email_requested_receipt do
    association :petition, factory: :open_petition
  end

  factory :location do
    code { Faker::Address.country_code }
    name { Faker::Address.country }

    trait :pending do
      start_date { 3.months.from_now }
    end

    trait :expired do
      end_date { 2.years.ago }
    end
  end

  factory :feedback do
    comment "This thing is wrong"
    petition_link_or_title "Do stuff"
    email "foo@example.com"
    user_agent "Mozilla/5.0"
  end

  factory :invalidation do
    summary "Invalidation summary"
    details "Reasons for invalidation"

    trait :cancelled do
      cancelled_at { Time.current }
    end

    trait :completed do
      completed_at { Time.current }
    end

    trait :started do
      started_at { Time.current }
    end
  end

  factory :tag do
    sequence(:name) { |n| "Tag #{n}" }
  end

  factory :trending_ip do
    association :petition, factory: :open_petition
    ip_address { "127.0.0.1" }
    country_code { "GB" }
    count { 32 }
    starts_at { 1.hour.ago.at_beginning_of_hour }
  end

  factory :trending_domain do
    association :petition, factory: :open_petition
    domain { "example.com" }
    count { 32 }
    starts_at { 1.hour.ago.at_beginning_of_hour }
  end

  factory :domain do
    sequence(:name) { |n| "example-#{n}.com" }
    strip_characters { "." }
    strip_extension { "+" }
  end

  factory :language do
    translations { Hash.new }

    trait :english do
      locale { "en-GB" }
      name   { "English" }

      translations do
        { "en-GB" => { "title" => "Petitions" } }
      end
    end

    trait :welsh do
      locale { "cy-GB" }
      name   { "Welsh" }

      translations do
        { "cy-GB" => { "title" => "Deisebau" } }
      end
    end
  end
end
