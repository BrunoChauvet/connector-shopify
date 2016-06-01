require 'spec_helper'

describe Maestrano::Connector::Rails::External do

  describe 'class methods' do
    subject { Maestrano::Connector::Rails::External }

    describe 'creates a shopify client' do
      it { expect(subject.external_name).to eql('Shopify') }
    end

    describe 'get_client' do
      let(:organization) { create(:organization) }

      it 'creates a restforce client' do
        expect(ShopifyClient).to receive(:new)
        subject.get_client(organization)
      end
    end

  end

end