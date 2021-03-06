require 'spec_helper'

describe OauthController, :type => :controller do
  let(:shop) { 'test-store-1234' }
  let(:uid) { 'uid-123' }
  let(:organization) { create(:organization, uid: uid) }

  describe 'request_omniauth' do
    before { allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:current_organization).and_return(organization) }

    subject { get :request_omniauth, provider: 'shopify', shop: shop }

    context 'when not admin' do
      before { allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin).and_return(false) }
      it { expect(subject).to redirect_to(root_url) }
    end

    context 'when admin' do
      before { allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin).and_return(true) }

      it { expect(subject).to redirect_to("http://test.host/auth/shopify?state=#{uid}&shop=#{shop}.myshopify.com") }

      context 'shop is blank' do
        let(:shop) { '' }
        it 'flash an error' do
          subject
          expect(flash[:error]).to eql('My shopify store url is required')
        end
      end
    end
  end

  describe 'create_omniauth' do
    let(:user) { Maestrano::Connector::Rails::User.new(email: 'lla@mail.com', tenant: 'default') }

    before { allow_any_instance_of(OauthController).to receive(:is_same_currency).and_return(true) }

    subject { get :create_omniauth, provider: 'shopify', state: uid }

    context 'when no organization does not exist' do
      it 'does nothing' do
        expect(Maestrano::Connector::Rails::External).to_not receive(:fetch_user)
        subject
      end
    end

    context 'when organization does not exist for this tenant' do
      let(:organization) { create(:organization, tenant: 'lala', uid: uid) }

      it 'does nothing' do
        expect(Maestrano::Connector::Rails::External).to_not receive(:fetch_user)
        subject
      end
    end

    context 'when organization is found' do
      let!(:organization) { create(:organization, tenant: 'default', uid: uid) }

      context 'when not admin' do
        before { allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin?).and_return(false)}

        it 'does nothing' do
          expect(Maestrano::Connector::Rails::External).to_not receive(:fetch_user)
          subject
        end
      end

      context 'when admin' do

        let(:stub_response)     { OpenStruct.new(uid: 'test', credentials: {'token' => '123'})}

        before do
          allow(request).to receive(:env).and_return( {'omniauth.params' => {'state' => 'org-123'}, 'omniauth.auth' => stub_response})
          allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin).and_return(true)
          allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:current_organization).and_return(organization)
          allow(Maestrano::Connector::Rails::External).to receive(:fetch_user).and_return({'locale' => 'a', 'timezone' => 'b'})
          allow(Maestrano::Connector::Rails::External).to receive(:fetch_company).and_return({'Name' => 'lala', 'Id' => 'idd'})
        end

        it 'Updates the orgnization with the OAuth credentials' do
          expect(organization).to receive(:from_omniauth)

          allow(Shopify::Webhooks::WebhooksManager).to receive(:queue_create_webhooks).and_return('Created')
          subject
        end

        context 'When webhooks cannot be created' do

          it 'Recues the error and logs the failure to the console' do
            expect(organization).to receive(:from_omniauth)

            allow(Shopify::Webhooks::WebhooksManager).to receive(:queue_create_webhooks).and_raise(Shopify::Webhooks::WebhooksManager::CreationFailed.new 'TEST')

            expect(Rails.logger).to receive(:warn).with("uid=\"uid-123\", org_uid=\"\", tenant=\"default\", message=\"Webhooks could not be created: TEST\"")

            subject
          end
        end
      end
    end
  end

  describe 'destroy_omniauth' do
    let(:organization) { create(:organization, oauth_uid: 'oauth_uid') }
    subject { get :destroy_omniauth, organization_id: id }

    before { allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:current_organization).and_return(organization) }

    context 'when no organization is found' do
      let(:id) { 5 }

      it { expect { subject }.to_not change { organization.oauth_uid } }
    end

    context 'when organization is found' do
      let(:id) { organization.id }
      let(:user) { Maestrano::Connector::Rails::User.new(email: 'lla@mail.com', tenant: 'default') }
      before { allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:current_user).and_return(user)}

      context 'when not admin' do
        before { allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin?).and_return(false)}

        it { expect { subject }.to_not change { organization.oauth_uid } }
      end

      context 'when admin' do
        before { allow_any_instance_of(Maestrano::Connector::Rails::SessionHelper).to receive(:is_admin?).and_return(true)}

        it do
          subject
          organization.reload
          expect(organization.oauth_uid).to be_nil
        end
      end
    end
  end
end
