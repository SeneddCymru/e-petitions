require 'rails_helper'

RSpec.describe NotifyJob, type: :job, notify: false do
  let(:success) do
    {
      status: 200,
      headers: {
        "Content-Type" => "application/json"
      },
      body: "{}"
    }
  end

  let(:notify_url) do
    "https://api.notifications.service.gov.uk/v2/notifications/email"
  end

  def notify_request(args)
    request = {
      email_address: args[:email_address],
      template_id: args[:template_id],
      reference: args[:reference],
      personalisation: args[:personalisation].merge(
        moderation_threshold: Site.formatted_threshold_for_moderation,
        referral_threshold: Site.formatted_threshold_for_referral,
        debate_threshold: Site.formatted_threshold_for_debate
      )
    }

    a_request(:post, notify_url).with(body: request.to_json)
  end

  shared_examples_for "a notify job" do
    describe "error handling" do
      around do |example|
        freeze_time { example.run }
      end

      context "when there is a deserialization error" do
        let(:model) { arguments.first.class }
        let(:exception_class) { ActiveJob::DeserializationError }

        before do
          allow(model).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")

          perform_enqueued_jobs {
            described_class.perform_later(*arguments)
          }
        end

        it "doesn't reschedule the job" do
          expect {
            described_class.perform_now(*arguments)
          }.not_to have_enqueued_job(described_class)
        end
      end

      context "when GOV.UK Notify is down" do
        let(:exception_class) { Net::OpenTimeout }

        before do
          stub_request(:post, notify_url).to_timeout
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for an hour later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(1.hour.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 500 error" do
        let(:exception_class) { Notifications::Client::ServerError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 500,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "Exception", message: "Internal server error" }
            ]}.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for an hour later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(1.hour.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 400 error" do
        let(:exception_class) { Notifications::Client::BadRequestError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 400,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "BadRequestError", message: "Can't send to this recipient using a team-only API key" }
            ]}.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 403 error" do
        let(:exception_class) { Notifications::Client::AuthError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 403,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "AuthError", message: "Invalid token: API key not found" }
            ]}.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning a 404 error" do
        let(:exception_class) { Notifications::Client::NotFoundError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 404,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "NotFoundError", message: "Not Found" }
            ]}.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when GOV.UK Notify is returning an unknown 4XX error" do
        let(:exception_class) { Notifications::Client::ClientError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 408,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "RequestTimeoutError", message: "Request Timeout" }
            ]}.to_json
          )
        end

        it "notifies Appsignal of the error" do
          expect(Appsignal).to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 24 hours later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(24.hours.from_now)
        end
      end

      context "when the rate limit is exceeded" do
        let(:exception_class) { Notifications::Client::RateLimitError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 429,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "RateLimitError", message: "Exceeded rate limit for key type LIVE of 3000 requests per 60 seconds" }
            ]}.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for 5 minutes later" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(5.minutes.from_now)
        end
      end

      context "when the daily message limit is exceeded" do
        let(:exception_class) { Notifications::Client::RateLimitError }

        before do
          stub_request(:post, notify_url).to_return(
            status: 429,
            headers: {
              "Content-Type" => "application/json"
            },
            body: { errors: [
              { error: "TooManyRequestsError", message: "Exceeded send limits (250,000) for today" }
            ]}.to_json
          )
        end

        it "doesn't notify Appsignal of the error" do
          expect(Appsignal).not_to receive(:send_exception).with(an_instance_of(exception_class), nil, "email")
          described_class.perform_now(*arguments)
        end

        it "reschedules the job for midnight" do
          expect {
            described_class.perform_now(*arguments)
          }.to have_enqueued_job(described_class).with(*arguments).at(Date.tomorrow.beginning_of_day)
        end
      end
    end
  end

  describe "subclasses" do
    let(:easter) { false }
    let(:christmas) { false }
    let(:moderation_queue) { 5 }

    before do
      stub_request(:post, notify_url).to_return(success)

      allow(Holiday).to receive(:easter?).and_return(easter)
      allow(Holiday).to receive(:christmas?).and_return(christmas)

      allow(Petition).to receive_message_chain(:in_moderation, :count).and_return(moderation_queue)
      allow(Site).to receive(:threshold_for_moderation_delay).and_return(10)
    end

    describe GatherSponsorsForPetitionEmailJob do
      let(:signature) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:pending_petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :pending_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and it's not a holiday" do
          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the English template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "3ed42402-0038-4304-b910-08eaa4ec580b",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the English moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "0e0cbb33-2546-45b8-8445-cd7281cd2f44",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Easter" do
          let(:easter) { true }

          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the English Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "3f08c4ae-f37b-4bc0-a96e-5495d4048411",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the English moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "0e0cbb33-2546-45b8-8445-cd7281cd2f44",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Christmas" do
          let(:christmas) { true }

          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the English Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "17729e9f-859c-43f4-a0c1-2d82823d54b8",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the English moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "0e0cbb33-2546-45b8-8445-cd7281cd2f44",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Do stuff",
                  content: "Because of reasons\n\nHere's some more reasons",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :pending_petition,
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and it's not a holiday" do
          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the Gaelic template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "2b58dfc1-4d92-4e98-82b8-2674036071df",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Dèan stuth",
                  content: "Air sgàth adhbharan\n\nSeo beagan a bharrachd adhbharan",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the Gaelic moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "d9d30b35-9e57-421c-9421-b5c234f314ed",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Dèan stuth",
                  content: "Air sgàth adhbharan\n\nSeo beagan a bharrachd adhbharan",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Easter" do
          let(:easter) { true }

          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the Gaelic Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "c277d917-d95a-4724-952c-e55f3577a6ad",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Dèan stuth",
                  content: "Air sgàth adhbharan\n\nSeo beagan a bharrachd adhbharan",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the Gaelic moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "d9d30b35-9e57-421c-9421-b5c234f314ed",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Dèan stuth",
                  content: "Air sgàth adhbharan\n\nSeo beagan a bharrachd adhbharan",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Christmas" do
          let(:christmas) { true }

          context "and there are no moderation delays" do
            it "sends an email via GOV.UK Notify with the Gaelic Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "6b082ec8-af7d-4333-98a9-9ca71bfc9950",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Dèan stuth",
                  content: "Air sgàth adhbharan\n\nSeo beagan a bharrachd adhbharan",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end

          context "and there are moderation delays" do
            let(:moderation_queue) { 15 }

            it "sends an email via GOV.UK Notify with the Gaelic moderation delay template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "d9d30b35-9e57-421c-9421-b5c234f314ed",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  action: "Dèan stuth",
                  content: "Air sgàth adhbharan\n\nSeo beagan a bharrachd adhbharan",
                  creator: "Charlie",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}/sponsors/new?token=#{petition.sponsor_token}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}/luchd-taic/ur?token=#{petition.sponsor_token}"
                }
              )).to have_been_made
            end
          end
        end
      end
    end

    describe PetitionAndEmailConfirmationForSponsorEmailJob do
      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:pending_petition) }
        let(:signature) { FactoryBot.create(:pending_signature, sponsor: true, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :sponsored_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :pending_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "43eec5b3-3630-45bb-8a0f-38dbad99d3e6",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Do stuff",
                content: "Because of reasons\n\nHere's some more reasons",
                creator: "Charlie",
                url_en: "https://petitions.parliament.scot/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/luchd-taic/#{signature.id}/dearbhaich?token=#{signature.perishable_token}"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Gaelic" do
          let(:signature) do
            FactoryBot.create(
              :pending_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "gd-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "d807f6ff-700d-4785-a41e-4572d3dd9dfa",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Do stuff",
                content: "Because of reasons\n\nHere's some more reasons",
                creator: "Charlie",
                url_en: "https://petitions.parliament.scot/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/luchd-taic/#{signature.id}/dearbhaich?token=#{signature.perishable_token}"
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :sponsored_petition,
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :pending_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "43eec5b3-3630-45bb-8a0f-38dbad99d3e6",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Dèan stuth",
                content: "Air sgàth adhbharan\n\nSeo beagan a bharrachd adhbharan",
                creator: "Charlie",
                url_en: "https://petitions.parliament.scot/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/luchd-taic/#{signature.id}/dearbhaich?token=#{signature.perishable_token}"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Gaelic" do
          let(:signature) do
            FactoryBot.create(
              :pending_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "gd-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "d807f6ff-700d-4785-a41e-4572d3dd9dfa",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Dèan stuth",
                content: "Air sgàth adhbharan\n\nSeo beagan a bharrachd adhbharan",
                creator: "Charlie",
                url_en: "https://petitions.parliament.scot/sponsors/#{signature.id}/verify?token=#{signature.perishable_token}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/luchd-taic/#{signature.id}/dearbhaich?token=#{signature.perishable_token}"
              }
            )).to have_been_made
          end
        end
      end
    end

    describe EmailDuplicateSponsorEmailJob do
      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:validated_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :validated_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              email_count: 1,
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "3a7e8201-52c5-4dc9-a349-7e2235312147",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Do stuff"
              }
            )).to have_been_made
          end

          it "increments the signature email_count" do
            expect {
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end
            }.to change {
              signature.reload.email_count
            }.from(1).to(2)
          end
        end

        context "and the sponsor signed in Gaelic" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "gd-GB",
              email_count: 1,
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "5cca1ad8-1214-41b0-8abe-bf982463dc01",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Do stuff",
              }
            )).to have_been_made
          end

          it "increments the signature email_count" do
            expect {
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end
            }.to change {
              signature.reload.email_count
            }.from(1).to(2)
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :validated_petition,
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              email_count: 1,
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "3a7e8201-52c5-4dc9-a349-7e2235312147",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Dèan stuth"
              }
            )).to have_been_made
          end

          it "increments the signature email_count" do
            expect {
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end
            }.to change {
              signature.reload.email_count
            }.from(1).to(2)
          end
        end

        context "and the sponsor signed in Gaelic" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "gd-GB",
              email_count: 1,
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "5cca1ad8-1214-41b0-8abe-bf982463dc01",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                action: "Dèan stuth"
              }
            )).to have_been_made
          end

          it "increments the signature email_count" do
            expect {
              perform_enqueued_jobs do
                described_class.perform_later(signature)
              end
            }.to change {
              signature.reload.email_count
            }.from(1).to(2)
          end
        end
      end
    end

    describe EmailConfirmationForSignerEmailJob do
      let(:petition) { FactoryBot.create(:open_petition, action_en: "Do stuff", action_gd: "Dèan stuth") }
      let(:constituency) { FactoryBot.create(:constituency, :glasgow_provan) }

      it_behaves_like "a notify job" do
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the signature was created in Englsh" do
        let(:signature) { FactoryBot.create(:pending_signature, email: "suzie@example.com", locale: "en-GB", petition: petition) }

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "suzie@example.com",
            template_id: "d1f5e610-5455-41ec-b71d-776c61ad9cac",
            reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
            personalisation: {
              action_en: "Do stuff",
              action_gd: "Dèan stuth",
              url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/verify?token=#{signature.perishable_token}",
              url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/dearbhaich?token=#{signature.perishable_token}"
            }
          )).to have_been_made
        end

        it "increments the signature email_count" do
          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.email_count
          }.from(0).to(1)
        end

        it "sets the constituency_id" do
          expect(Constituency).to receive(:find_by_postcode).with("G340BX").and_return(constituency)

          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.constituency_id
          }.from(nil).to("S16000147")
        end
      end

      context "when the signature was created in Gaelic" do
        let(:signature) { FactoryBot.create(:pending_signature, email: "suzie@example.com", locale: "gd-GB", petition: petition) }

        it "sends an email via GOV.UK Notify with the Gaelic template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "suzie@example.com",
            template_id: "b79b908a-5b2f-4577-a03e-d8c625a2e280",
            reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
            personalisation: {
              action_en: "Do stuff",
              action_gd: "Dèan stuth",
              url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/verify?token=#{signature.perishable_token}",
              url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/dearbhaich?token=#{signature.perishable_token}"
            }
          )).to have_been_made
        end

        it "increments the signature email_count" do
          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.email_count
          }.from(0).to(1)
        end

        it "sets the constituency_id" do
          expect(Constituency).to receive(:find_by_postcode).with("G340BX").and_return(constituency)

          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.constituency_id
          }.from(nil).to("S16000147")
        end
      end
    end

    describe EmailDuplicateSignaturesEmailJob do
      let(:petition) { FactoryBot.create(:open_petition, action_en: "Do stuff", action_gd: "Dèan stuth") }

      it_behaves_like "a notify job" do
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the signature was created in English" do
        let(:signature) { FactoryBot.create(:validated_signature, email: "suzie@example.com", locale: "en-GB", email_count: 1, petition: petition) }

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "suzie@example.com",
            template_id: "ba9c3050-cc8b-410b-b3d2-30c692ffb91c",
            reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
            personalisation: {
              action_en: "Do stuff",
              action_gd: "Dèan stuth",
              url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}"
            }
          )).to have_been_made
        end

        it "increments the signature email_count" do
          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.email_count
          }.from(1).to(2)
        end
      end

      context "when the signature was created in Gaelic" do
        let(:signature) { FactoryBot.create(:validated_signature, email: "suzie@example.com", locale: "gd-GB", email_count: 1, petition: petition) }

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "suzie@example.com",
            template_id: "a3997c4b-8f4e-4013-abcb-fdbbbb6f5950",
            reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
            personalisation: {
              action_en: "Do stuff",
              action_gd: "Dèan stuth",
              url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}"
            }
          )).to have_been_made
        end

        it "increments the signature email_count" do
          expect {
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end
          }.to change {
            signature.reload.email_count
          }.from(1).to(2)
        end
      end
    end

    describe NotifyCreatorThatPetitionIsPublishedEmailJob do
      let(:signature) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:open_petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :open_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "f23547af-65d8-4d9d-82cb-6f247112217e",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              creator: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}"
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :open_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Gaelic template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "a18a2bbf-df46-4f7f-8202-dcfe2c9ba188",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              creator: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}"
            }
          )).to have_been_made
        end
      end
    end

    describe NotifySponsorThatPetitionIsPublishedEmailJob do
      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:open_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, sponsor: true, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :open_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "f622a170-c0cf-42ca-aef6-66deb7f25611",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                sponsor: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Gaelic" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "gd-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "0ad7a912-1444-49c9-b915-f4969f24376f",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                sponsor: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}"
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :open_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "f622a170-c0cf-42ca-aef6-66deb7f25611",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                sponsor: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Gaelic" do
          let(:signature) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "gd-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "0ad7a912-1444-49c9-b915-f4969f24376f",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                sponsor: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}"
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifyCreatorThatPetitionWasRejectedEmailJob do
      let(:signature) { petition.creator }
      let(:rejection) { petition.rejection }
      let(:rejection_code) { "duplicate" }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:rejected_petition) }
        let(:arguments) { [signature, rejection] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            state,
            rejection_code: rejection_code,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the petition was published" do
          let(:state) { :rejected_petition }

          it "sends an email via GOV.UK Notify with the English rejection template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "13846021-76c3-41d1-8f6d-a452fc763c67",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action: "Do stuff",
                content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                content_gd: "Tha athchuinge ann mu thràth mun chùis seo. Chan urrainn dhuinn gabhail ri athchuinge ùr nuair a tha fear againn mu chùis glè choltach mu thràth, no ma tha Comataidh nan Athchuingean air beachdachadh air fear sa bhliadhna a dh ’fhalbh.",
                url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                standards_url_en: "https://petitions.parliament.scot/help#standards",
                standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards",
                new_petition_url_en: "https://petitions.parliament.scot/petitions/check",
                new_petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/thoir-suil"
              }
            )).to have_been_made
          end
        end

        context "and the petition was hidden" do
          let(:state) { :hidden_petition }
          let(:rejection_code) { "offensive" }

          it "sends an email via GOV.UK Notify with the English hidden rejection template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "925889ef-245f-4f41-adbc-2378d079d1c6",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action: "Do stuff",
                content_en: "It’s offensive, nonsense, a joke, or an advert.",
                content_gd: "Tha e oilbheumach, neoni, fealla-dhà no sanas.",
                url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                standards_url_en: "https://petitions.parliament.scot/help#standards",
                standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards",
                new_petition_url_en: "https://petitions.parliament.scot/petitions/check",
                new_petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/thoir-suil"
              }
            )).to have_been_made
          end
        end

        context "and the petition failed to get enough signatures" do
          let(:state) { :rejected_petition }
          let(:rejection_code) { "insufficient" }

          it "sends an email via GOV.UK Notify with the English insufficient template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "6297d459-b8be-4872-82e5-1cb1e52921c5",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action_en: "Do stuff", action_gd: "Dèan stuth",
                content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in Parliament.",
                content_gd: "Cha do chruinnich e ainmean-sgrìobhte gu leòr airson an cur gu Comataidh nan Athchuingean.\n\nFeumaidh athchuingean co-dhiù 50 ainm-sgrìobhte fhaighinn mus tèid beachdachadh orra anns a ’Phàrlamaid.",
                url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                standards_url_en: "https://petitions.parliament.scot/help#standards",
                standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards",
                new_petition_url_en: "https://petitions.parliament.scot/petitions/check",
                new_petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/thoir-suil"
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            state,
            rejection_code: rejection_code,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the petition was published" do
          let(:state) { :rejected_petition }

          it "sends an email via GOV.UK Notify with the Gaelic rejection template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "506fd5ab-379f-4a0d-9913-b151abad69a9",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action: "Dèan stuth",
                content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                content_gd: "Tha athchuinge ann mu thràth mun chùis seo. Chan urrainn dhuinn gabhail ri athchuinge ùr nuair a tha fear againn mu chùis glè choltach mu thràth, no ma tha Comataidh nan Athchuingean air beachdachadh air fear sa bhliadhna a dh ’fhalbh.",
                url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                standards_url_en: "https://petitions.parliament.scot/help#standards",
                standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards",
                new_petition_url_en: "https://petitions.parliament.scot/petitions/check",
                new_petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/thoir-suil"
              }
            )).to have_been_made
          end
        end

        context "and the petition was hidden" do
          let(:state) { :hidden_petition }
          let(:rejection_code) { "offensive" }

          it "sends an email via GOV.UK Notify with the Gaelic hidden rejection template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "111a4136-365b-48ee-bf2f-be60e5798bdc",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action: "Dèan stuth",
                content_en: "It’s offensive, nonsense, a joke, or an advert.",
                content_gd: "Tha e oilbheumach, neoni, fealla-dhà no sanas.",
                url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                standards_url_en: "https://petitions.parliament.scot/help#standards",
                standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards",
                new_petition_url_en: "https://petitions.parliament.scot/petitions/check",
                new_petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/thoir-suil"
              }
            )).to have_been_made
          end
        end

        context "and the petition failed to get enough signatures" do
          let(:state) { :rejected_petition }
          let(:rejection_code) { "insufficient" }

          it "sends an email via GOV.UK Notify with the Gaelic insufficient template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, rejection)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "61bf3c20-decd-4aa6-88e0-9df929b4dae8",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                creator: "Charlie", action_en: "Do stuff", action_gd: "Dèan stuth",
                content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in Parliament.",
                content_gd: "Cha do chruinnich e ainmean-sgrìobhte gu leòr airson an cur gu Comataidh nan Athchuingean.\n\nFeumaidh athchuingean co-dhiù 50 ainm-sgrìobhte fhaighinn mus tèid beachdachadh orra anns a ’Phàrlamaid.",
                url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                standards_url_en: "https://petitions.parliament.scot/help#standards",
                standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards",
                new_petition_url_en: "https://petitions.parliament.scot/petitions/check",
                new_petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/thoir-suil"
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifySponsorThatPetitionWasRejectedEmailJob do
      let(:rejection) { petition.rejection }
      let(:rejection_code) { "duplicate" }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:rejected_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, sponsor: true, petition: petition) }
        let(:arguments) { [signature, rejection] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            state,
            rejection_code: rejection_code,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the petition was published" do
          let(:state) { :rejected_petition }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "f9e6a3f3-7eb0-4ab9-baa2-0f517d1e51c8",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Do stuff",
                  content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                  content_gd: "Tha athchuinge ann mu thràth mun chùis seo. Chan urrainn dhuinn gabhail ri athchuinge ùr nuair a tha fear againn mu chùis glè choltach mu thràth, no ma tha Comataidh nan Athchuingean air beachdachadh air fear sa bhliadhna a dh ’fhalbh.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "2386c97c-307f-4d40-ad48-9e44e2eaecd7",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Do stuff",
                  content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                  content_gd: "Tha athchuinge ann mu thràth mun chùis seo. Chan urrainn dhuinn gabhail ri athchuinge ùr nuair a tha fear againn mu chùis glè choltach mu thràth, no ma tha Comataidh nan Athchuingean air beachdachadh air fear sa bhliadhna a dh ’fhalbh.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and the petition was hidden" do
          let(:state) { :hidden_petition }
          let(:rejection_code) { "offensive" }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English hidden rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "350b544c-47ef-4559-8d73-c374ec7db8d7",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Do stuff",
                  content_en: "It’s offensive, nonsense, a joke, or an advert.",
                  content_gd: "Tha e oilbheumach, neoni, fealla-dhà no sanas.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic hidden rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "59a256a3-e0e8-4bc7-923a-142a42410ea9",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Do stuff",
                  content_en: "It’s offensive, nonsense, a joke, or an advert.",
                  content_gd: "Tha e oilbheumach, neoni, fealla-dhà no sanas.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and the petition failed to get enough signatures" do
          let(:state) { :rejected_petition }
          let(:rejection_code) { "insufficient" }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English insufficient template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "87e8900d-5f1a-4366-9d40-c424173c4806",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action_en: "Do stuff", action_gd: "Dèan stuth",
                  content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in Parliament.",
                  content_gd: "Cha do chruinnich e ainmean-sgrìobhte gu leòr airson an cur gu Comataidh nan Athchuingean.\n\nFeumaidh athchuingean co-dhiù 50 ainm-sgrìobhte fhaighinn mus tèid beachdachadh orra anns a ’Phàrlamaid.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic insufficient template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "6cd02568-0627-4932-a81d-23bf543840da",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action_en: "Do stuff", action_gd: "Dèan stuth",
                  content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in Parliament.",
                  content_gd: "Cha do chruinnich e ainmean-sgrìobhte gu leòr airson an cur gu Comataidh nan Athchuingean.\n\nFeumaidh athchuingean co-dhiù 50 ainm-sgrìobhte fhaighinn mus tèid beachdachadh orra anns a ’Phàrlamaid.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            state,
            rejection_code: rejection_code,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the petition was published" do
          let(:state) { :rejected_petition }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "f9e6a3f3-7eb0-4ab9-baa2-0f517d1e51c8",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Dèan stuth",
                  content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                  content_gd: "Tha athchuinge ann mu thràth mun chùis seo. Chan urrainn dhuinn gabhail ri athchuinge ùr nuair a tha fear againn mu chùis glè choltach mu thràth, no ma tha Comataidh nan Athchuingean air beachdachadh air fear sa bhliadhna a dh ’fhalbh.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "2386c97c-307f-4d40-ad48-9e44e2eaecd7",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Dèan stuth",
                  content_en: "There’s already a petition about this issue. We cannot accept a new petition when we already have one about a very similar issue, or if the Petitions Committee has considered one in the last year.",
                  content_gd: "Tha athchuinge ann mu thràth mun chùis seo. Chan urrainn dhuinn gabhail ri athchuinge ùr nuair a tha fear againn mu chùis glè choltach mu thràth, no ma tha Comataidh nan Athchuingean air beachdachadh air fear sa bhliadhna a dh ’fhalbh.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and the petition was hidden" do
          let(:state) { :hidden_petition }
          let(:rejection_code) { "offensive" }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English hidden rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "350b544c-47ef-4559-8d73-c374ec7db8d7",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Dèan stuth",
                  content_en: "It’s offensive, nonsense, a joke, or an advert.",
                  content_gd: "Tha e oilbheumach, neoni, fealla-dhà no sanas.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic hidden rejection template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "59a256a3-e0e8-4bc7-923a-142a42410ea9",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action: "Dèan stuth",
                  content_en: "It’s offensive, nonsense, a joke, or an advert.",
                  content_gd: "Tha e oilbheumach, neoni, fealla-dhà no sanas.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and the petition failed to get enough signatures" do
          let(:state) { :rejected_petition }
          let(:rejection_code) { "insufficient" }

          context "and the sponsor signed in English" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English insufficient template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "87e8900d-5f1a-4366-9d40-c424173c4806",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action_en: "Do stuff", action_gd: "Dèan stuth",
                  content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in Parliament.",
                  content_gd: "Cha do chruinnich e ainmean-sgrìobhte gu leòr airson an cur gu Comataidh nan Athchuingean.\n\nFeumaidh athchuingean co-dhiù 50 ainm-sgrìobhte fhaighinn mus tèid beachdachadh orra anns a ’Phàrlamaid.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:signature) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic insufficient template" do
              perform_enqueued_jobs do
                described_class.perform_later(signature, rejection)
              end

              expect(notify_request(
                email_address: "suzie@example.com",
                template_id: "6cd02568-0627-4932-a81d-23bf543840da",
                reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
                personalisation: {
                  sponsor: "Suzie", action_en: "Do stuff", action_gd: "Dèan stuth",
                  content_en: "It did not collect enough signatures to be referred to the Petitions Committee.\n\nPetitions need to receive at least 50 signatures before they can be considered in Parliament.",
                  content_gd: "Cha do chruinnich e ainmean-sgrìobhte gu leòr airson an cur gu Comataidh nan Athchuingean.\n\nFeumaidh athchuingean co-dhiù 50 ainm-sgrìobhte fhaighinn mus tèid beachdachadh orra anns a ’Phàrlamaid.",
                  url_en: "https://petitions.parliament.scot/petitions/#{'PP%04d' % petition.id}",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PP%04d' % petition.id}",
                  standards_url_en: "https://petitions.parliament.scot/help#standards",
                  standards_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end
      end
    end

    describe SponsorSignedEmailBelowThresholdEmailJob do
      let(:creator) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:rejected_petition) }
        let(:sponsor) { FactoryBot.create(:validated_signature, sponsor: true, petition: petition) }
        let(:arguments) { [creator, sponsor] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :pending_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:sponsor) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(creator, sponsor)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "112c46d3-980e-4d56-83e8-06bb98a57871",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                sponsor_count_en: "You have 1 supporter so far",
                sponsor_count_gd: "You have 1 supporter so far",
                url_en: "https://petitions.parliament.scot/help#standards",
                url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Gaelic" do
          let(:sponsor) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "gd-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(creator, sponsor)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "112c46d3-980e-4d56-83e8-06bb98a57871",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                sponsor_count_en: "You have 1 supporter so far",
                sponsor_count_gd: "You have 1 supporter so far",
                url_en: "https://petitions.parliament.scot/help#standards",
                url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :pending_petition,
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the sponsor signed in English" do
          let(:sponsor) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "en-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(creator, sponsor)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "71f415b2-6488-4dc5-aa47-91ebaad41faf",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                sponsor: "Suzie", creator: "Charlie", action: "Dèan stuth",
                sponsor_count_en: "You have 1 supporter so far",
                sponsor_count_gd: "You have 1 supporter so far",
                url_en: "https://petitions.parliament.scot/help#standards",
                url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
              }
            )).to have_been_made
          end
        end

        context "and the sponsor signed in Gaelic" do
          let(:sponsor) do
            FactoryBot.create(
              :validated_signature,
              name: "Suzie",
              email: "suzie@example.com",
              locale: "gd-GB",
              sponsor: true,
              petition: petition
            )
          end

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(creator, sponsor)
            end

            expect(notify_request(
              email_address: "charlie@example.com",
              template_id: "71f415b2-6488-4dc5-aa47-91ebaad41faf",
              reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
              personalisation: {
                sponsor: "Suzie", creator: "Charlie", action: "Dèan stuth",
                sponsor_count_en: "You have 1 supporter so far",
                sponsor_count_gd: "You have 1 supporter so far",
                url_en: "https://petitions.parliament.scot/help#standards",
                url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
              }
            )).to have_been_made
          end
        end
      end
    end

    describe SponsorSignedEmailOnThresholdEmailJob do
      let(:creator) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:rejected_petition) }
        let(:sponsor) { FactoryBot.create(:validated_signature, sponsor: true, petition: petition) }
        let(:arguments) { [creator, sponsor] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :validated_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and it's not a holiday" do
          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "3949e09a-19fe-46de-b7cc-cd25c6e1360e",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "3949e09a-19fe-46de-b7cc-cd25c6e1360e",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Easter" do
          let(:easter) { true }

          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "cb8144c1-3d7c-417b-9add-261fe4253d24",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "cb8144c1-3d7c-417b-9add-261fe4253d24",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Christmas" do
          let(:christmas) { true }

          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "13feeec9-d539-4548-a1cf-13254a51af1c",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the English Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "13feeec9-d539-4548-a1cf-13254a51af1c",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Do stuff",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :validated_petition,
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and it's not a holiday" do
          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "20cb31ed-5758-4fd4-9d0d-69fe6c1f4818",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Dèan stuth",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "20cb31ed-5758-4fd4-9d0d-69fe6c1f4818",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Dèan stuth",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Easter" do
          let(:easter) { true }

          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "8c18ec4e-c6a5-4939-bbdd-19fbb1e392d3",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Dèan stuth",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic Easter template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "8c18ec4e-c6a5-4939-bbdd-19fbb1e392d3",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Dèan stuth",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end

        context "and it's Christmas" do
          let(:christmas) { true }

          context "and the sponsor signed in English" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "en-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "a41374bb-235b-4203-8ed2-076961c7554c",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Dèan stuth",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end

          context "and the sponsor signed in Gaelic" do
            let(:sponsor) do
              FactoryBot.create(
                :validated_signature,
                name: "Suzie",
                email: "suzie@example.com",
                locale: "gd-GB",
                sponsor: true,
                petition: petition
              )
            end

            it "sends an email via GOV.UK Notify with the Gaelic Christmas template" do
              perform_enqueued_jobs do
                described_class.perform_later(creator, sponsor)
              end

              expect(notify_request(
                email_address: "charlie@example.com",
                template_id: "a41374bb-235b-4203-8ed2-076961c7554c",
                reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
                personalisation: {
                  sponsor: "Suzie", creator: "Charlie", action: "Dèan stuth",
                  url_en: "https://petitions.parliament.scot/help#standards",
                  url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#standards"
                }
              )).to have_been_made
            end
          end
        end
      end
    end

    describe FeedbackEmailJob do
      let(:feedback) do
        FactoryBot.create(
          :feedback,
          comment: "This is a test",
          petition_link_or_title: "https://petitions.parliament.scot/petitions/10000",
          email: "suzie@example.com",
          user_agent: "Mozilla/5.0"
        )
      end

      it_behaves_like "a notify job" do
        let(:arguments) { [feedback] }
      end

      it "sends an email via GOV.UK Notify to the feedback address" do
        perform_enqueued_jobs do
          described_class.perform_later(feedback)
        end

        json = {
          email_address: "petitionscommittee@parliament.scot",
          template_id: "18fe5489-1e5b-4741-b840-5a1dddd97983",
          reference: feedback.to_gid_param,
          personalisation: {
            comment: "This is a test",
            link_or_title: "https://petitions.parliament.scot/petitions/10000",
            email: "suzie@example.com",
            user_agent: "Mozilla/5.0"
          }
        }.to_json

        expect(a_request(:post, notify_url).with(body: json)).to have_been_made
      end

      context "when feedback sending is disabled" do
        before do
          allow(Site).to receive(:disable_feedback_sending?).and_return(true)
        end

        around do |example|
          freeze_time { example.run }
        end

        it "doesn't send an email via GOV.UK Notify to the feedback address" do
          described_class.perform_now(feedback)

          expect(a_request(:post, notify_url)).not_to have_been_made
        end

        it "reschedules the job" do
          expect {
            described_class.perform_now(feedback)
          }.to have_enqueued_job(described_class).with(feedback).on_queue("high_priority").at(1.hour.from_now)
        end
      end
    end

    describe EmailCreatorAboutOtherBusinessEmailJob do
      let(:signature) { petition.creator }

      let(:email) do
        FactoryBot.create(
          :petition_email,
          petition: petition,
          subject_en: "The Petitions committee will be discussing this petition",
          subject_gd: "Bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo",
          body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Parliament.",
          body_gd: "Air 21 Iuchar, bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo gus faicinn am bu chòir a moladh airson deasbad sa Phàrlamaid.",
        )
      end

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:referred_petition) }
        let(:arguments) { [signature, email] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, email)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "1b64c2cc-d9f0-49ef-920e-34716aff1fc2",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
              subject_en: "The Petitions committee will be discussing this petition",
              subject_gd: "Bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo",
              body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Parliament.",
              body_gd: "Air 21 Iuchar, bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo gus faicinn am bu chòir a moladh airson deasbad sa Phàrlamaid.",
              unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Gaelic template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, email)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "e62c1f63-ea30-4d91-86a2-4e290c13fb0c",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
              subject_en: "The Petitions committee will be discussing this petition",
              subject_gd: "Bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo",
              body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Parliament.",
              body_gd: "Air 21 Iuchar, bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo gus faicinn am bu chòir a moladh airson deasbad sa Phàrlamaid.",
              unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end
    end

    describe EmailSignerAboutOtherBusinessEmailJob do
      let(:email) do
        FactoryBot.create(
          :petition_email,
          petition: petition,
          subject_en: "The Petitions committee will be discussing this petition",
          subject_gd: "Bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo",
          body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Parliament.",
          body_gd: "Air 21 Iuchar, bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo gus faicinn am bu chòir a moladh airson deasbad sa Phàrlamaid.",
        )
      end

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:referred_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature, email] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, email)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "180c8aed-726a-46cf-aef6-2a0a34906cb4",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                subject_en: "The Petitions committee will be discussing this petition",
                subject_gd: "Bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo",
                body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Parliament.",
                body_gd: "Air 21 Iuchar, bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo gus faicinn am bu chòir a moladh airson deasbad sa Phàrlamaid.",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Gaelic" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "gd-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, email)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "61647c95-10f3-445b-aa38-1cbe436663b6",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                subject_en: "The Petitions committee will be discussing this petition",
                subject_gd: "Bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo",
                body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Parliament.",
                body_gd: "Air 21 Iuchar, bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo gus faicinn am bu chòir a moladh airson deasbad sa Phàrlamaid.",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :referred_petition,
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, email)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "180c8aed-726a-46cf-aef6-2a0a34906cb4",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                subject_en: "The Petitions committee will be discussing this petition",
                subject_gd: "Bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo",
                body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Parliament.",
                body_gd: "Air 21 Iuchar, bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo gus faicinn am bu chòir a moladh airson deasbad sa Phàrlamaid.",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Gaelic" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "gd-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, email)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "61647c95-10f3-445b-aa38-1cbe436663b6",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                subject_en: "The Petitions committee will be discussing this petition",
                subject_gd: "Bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo",
                body_en: "On the 21st July, the Petitions committee will be discussing this petition to see whether to recommend it for a debate in Parliament.",
                body_gd: "Air 21 Iuchar, bidh comataidh nan Athchuingean a ’deasbad na h-athchuinge seo gus faicinn am bu chòir a moladh airson deasbad sa Phàrlamaid.",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifyCreatorOfDebateScheduledEmailJob do
      let(:signature) { petition.creator }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:scheduled_debate_petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :scheduled_debate_petition,
            debate_threshold_reached_at: "2020-06-30T20:30:00Z",
            scheduled_debate_date: "2020-07-07",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "eedd584c-1ea0-40cb-81d5-df30b9dc4a59",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
              debate_date_en: "7 July 2020", debate_date_gd: "7 dhen Iuchar 2020",
              unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :scheduled_debate_petition,
            debate_threshold_reached_at: "2020-06-30T20:30:00Z",
            scheduled_debate_date: "2020-07-07",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Gaelic template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "1915c783-3b72-4a77-91b2-abb67e44bd07",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
              debate_date_en: "7 July 2020", debate_date_gd: "7 dhen Iuchar 2020",
              unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end
    end

    describe NotifySignerOfDebateScheduledEmailJob do
      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:scheduled_debate_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :scheduled_debate_petition,
            debate_threshold_reached_at: "2020-06-30T20:30:00Z",
            scheduled_debate_date: "2020-07-07",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "3e998aef-a6cf-45f2-b3af-80ddf2375ddd",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                debate_date_en: "7 July 2020", debate_date_gd: "7 dhen Iuchar 2020",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Gaelic" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "gd-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "73de5200-a8a7-47f1-a6c7-b2a90c2ba419",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                debate_date_en: "7 July 2020", debate_date_gd: "7 dhen Iuchar 2020",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :scheduled_debate_petition,
            debate_threshold_reached_at: "2020-06-30T20:30:00Z",
            scheduled_debate_date: "2020-07-07",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "3e998aef-a6cf-45f2-b3af-80ddf2375ddd",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                debate_date_en: "7 July 2020", debate_date_gd: "7 dhen Iuchar 2020",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Gaelic" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "gd-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "73de5200-a8a7-47f1-a6c7-b2a90c2ba419",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                debate_date_en: "7 July 2020", debate_date_gd: "7 dhen Iuchar 2020",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifyCreatorOfNegativeDebateOutcomeEmailJob do
      let(:signature) { petition.creator }
      let(:outcome) { petition.debate_outcome }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:not_debated_petition) }
        let(:arguments) { [signature, outcome] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :not_debated_petition,
            overview_en: "Because it was no longer relevant",
            overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, outcome)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "a86c7fc5-dc56-4cbc-93cb-7ed289f76938",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              overview_en: "Because it was no longer relevant",
              overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
              petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
              petitions_committee_url_en: "https://petitions.parliament.scot/help#petitions-committee",
              petitions_committee_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#petitions-committee",
              unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :not_debated_petition,
            overview_en: "Because it was no longer relevant",
            overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Gaelic template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, outcome)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "374a45ab-b871-423f-a0cb-6a3bd090dc19",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              overview_en: "Because it was no longer relevant",
              overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
              petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
              petitions_committee_url_en: "https://petitions.parliament.scot/help#petitions-committee",
              petitions_committee_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#petitions-committee",
              unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end
    end

    describe NotifySignerOfNegativeDebateOutcomeEmailJob do
      let(:outcome) { petition.debate_outcome }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:not_debated_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature, outcome] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :not_debated_petition,
            overview_en: "Because it was no longer relevant",
            overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "918ff0be-d33e-4ad5-ad9c-da2f339e8070",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                overview_en: "Because it was no longer relevant",
                overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                petitions_committee_url_en: "https://petitions.parliament.scot/help#petitions-committee",
                petitions_committee_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#petitions-committee",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Gaelic" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "gd-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "4ef93900-6278-433e-9a11-36700c57da29",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                overview_en: "Because it was no longer relevant",
                overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                petitions_committee_url_en: "https://petitions.parliament.scot/help#petitions-committee",
                petitions_committee_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#petitions-committee",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :not_debated_petition,
            overview_en: "Because it was no longer relevant",
            overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "918ff0be-d33e-4ad5-ad9c-da2f339e8070",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                overview_en: "Because it was no longer relevant",
                overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                petitions_committee_url_en: "https://petitions.parliament.scot/help#petitions-committee",
                petitions_committee_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#petitions-committee",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Gaelic" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "gd-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "4ef93900-6278-433e-9a11-36700c57da29",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                overview_en: "Because it was no longer relevant",
                overview_gd: "Oherwydd nad oedd yn berthnasol mwyach",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                petitions_committee_url_en: "https://petitions.parliament.scot/help#petitions-committee",
                petitions_committee_url_gd: "https://athchuingean.parlamaid-alba.scot/cuideachadh#petitions-committee",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end
    end

    describe NotifyCreatorOfPositiveDebateOutcomeEmailJob do
      let(:signature) { petition.creator }
      let(:outcome) { petition.debate_outcome }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:debated_petition) }
        let(:arguments) { [signature, outcome] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :debated_petition,
            overview_en: "Parliament came to the conclusion that this was a good idea",
            overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
            transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
            debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the English template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, outcome)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "be4a7709-d813-4257-ab45-fda327aef2d9",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              overview_en: "Parliament came to the conclusion that this was a good idea",
              overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
              transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
              transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
              video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
              video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
              debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
              debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
              petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
              unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :debated_petition,
            overview_en: "Parliament came to the conclusion that this was a good idea",
            overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
            transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
            debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        it "sends an email via GOV.UK Notify with the Gaelic template" do
          perform_enqueued_jobs do
            described_class.perform_later(signature, outcome)
          end

          expect(notify_request(
            email_address: "charlie@example.com",
            template_id: "031cf660-43e3-4d8b-91ea-1e7ce2ddc140",
            reference: "d85a62b0-efb6-51a2-9087-a10881e6728e",
            personalisation: {
              name: "Charlie",
              action_en: "Do stuff", action_gd: "Dèan stuth",
              overview_en: "Parliament came to the conclusion that this was a good idea",
              overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
              transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
              transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
              video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
              video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
              debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
              debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
              petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
              petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
              unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
              unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
            }
          )).to have_been_made
        end
      end
    end

    describe NotifySignerOfPositiveDebateOutcomeEmailJob do
      let(:outcome) { petition.debate_outcome }

      it_behaves_like "a notify job" do
        let(:petition) { FactoryBot.create(:debated_petition) }
        let(:signature) { FactoryBot.create(:validated_signature, petition: petition) }
        let(:arguments) { [signature, outcome] }
      end

      context "when the petition was created in English" do
        let(:petition) do
          FactoryBot.create(
            :debated_petition,
            overview_en: "Parliament came to the conclusion that this was a good idea",
            overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
            transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
            debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "en-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "en-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "d2777d25-c434-4196-8ed5-54460b71f7c9",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                overview_en: "Parliament came to the conclusion that this was a good idea",
                overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
                transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
                debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Gaelic" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "gd-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "fc58c0b6-217b-4d3b-9a9f-2537bb16f636",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                overview_en: "Parliament came to the conclusion that this was a good idea",
                overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
                transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
                debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end

      context "when the petition was created in Gaelic" do
        let(:petition) do
          FactoryBot.create(
            :debated_petition,
            overview_en: "Parliament came to the conclusion that this was a good idea",
            overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
            transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
            video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
            debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
            debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
            action_en: "Do stuff",
            background_en: "Because of reasons",
            additional_details_en: "Here's some more reasons",
            action_gd: "Dèan stuth",
            background_gd: "Air sgàth adhbharan",
            additional_details_gd: "Seo beagan a bharrachd adhbharan",
            locale: "gd-GB",
            creator_name: "Charlie",
            creator_email: "charlie@example.com",
            creator_attributes: {
              locale: "gd-GB"
            }
          )
        end

        context "and the signature was created in English" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "en-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the English template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "d2777d25-c434-4196-8ed5-54460b71f7c9",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                overview_en: "Parliament came to the conclusion that this was a good idea",
                overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
                transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
                debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end

        context "and the signature was created in Gaelic" do
          let(:signature) { FactoryBot.create(:validated_signature, name: "Suzie", email: "suzie@example.com", locale: "gd-GB", petition: petition) }

          it "sends an email via GOV.UK Notify with the Gaelic template" do
            perform_enqueued_jobs do
              described_class.perform_later(signature, outcome)
            end

            expect(notify_request(
              email_address: "suzie@example.com",
              template_id: "fc58c0b6-217b-4d3b-9a9f-2537bb16f636",
              reference: "a87bda8d-19ac-5df8-ac83-075f189db982",
              personalisation: {
                name: "Suzie",
                action_en: "Do stuff", action_gd: "Dèan stuth",
                overview_en: "Parliament came to the conclusion that this was a good idea",
                overview_gd: "Thàinig a ’Phàrlamaid chun cho-dhùnadh gur e deagh bheachd a bha seo",
                transcript_url_en: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                transcript_url_gd: "https://www.parliament.scot/S5_BusinessTeam/Chamber_Minutes_20210127.pdf",
                video_url_en: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                video_url_gd: "https://www.scottishparliament.tv/meeting/public-petitions-committee-january-27-2021",
                debate_pack_url_en: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
                debate_pack_url_gd: "http://www.parliament.scot/S5_PublicPetitionsCommittee/Reports/PPCS052020R2.pdf",
                petition_url_en: "https://petitions.parliament.scot/petitions/#{'PE%04d' % petition.pe_number_id}",
                petition_url_gd: "https://athchuingean.parlamaid-alba.scot/athchuingean/#{'PE%04d' % petition.pe_number_id}",
                unsubscribe_url_en: "https://petitions.parliament.scot/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}",
                unsubscribe_url_gd: "https://athchuingean.parlamaid-alba.scot/ainmean-sgriobhte/#{signature.id}/di-chlaradh?token=#{signature.unsubscribe_token}",
              }
            )).to have_been_made
          end
        end
      end
    end
  end
end
