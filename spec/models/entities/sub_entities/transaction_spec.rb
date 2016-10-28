require 'spec_helper'

describe Entities::SubEntities::Transaction do

  describe 'class methods' do
    subject { Entities::SubEntities::Transaction }

    it { expect(subject.entity_name).to eql('Transaction') }
    it { expect(subject.external?).to eql(true) }
    it { expect(subject.object_name_from_external_entity_hash({'id' => 'ABC'})).to eql('ABC') }
    it { expect(subject.last_update_date_from_external_entity_hash({'created_at' => Time.new(1985, 9, 17).iso8601})).to eql(Time.new(1985, 9, 17)) }
  end

  describe 'instance methods' do
    let(:organization) { create(:organization) }
    let(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
    let(:external_client) { Maestrano::Connector::Rails::External.get_client(organization) }
    let(:opts) { {} }
    subject { Entities::SubEntities::Transaction.new(organization, connec_client, external_client, opts) }

    describe 'mapping to connec!' do
      let(:transaction) {
        {
            'id' => '1',
            'order_id' => 'N11003',
            'created_at' => '2016-06-12 23:26:26',
            'currency' => 'AUD',
            'amount' => 155.00,
            'customer' => {
                'id' => 'USER-ID'
            }
        }
      }

      describe 'payment' do
        let(:connec_payment) {
          {
              'id' => [{'id' => '1', 'provider' => organization.oauth_provider, 'realm' => organization.oauth_uid}],
              'payment_lines' => [
                  {
                      'id' => [{'id' => 'shopify-payment', 'provider' => organization.oauth_provider, 'realm' => organization.oauth_uid}],
                      'amount' => 155.0,
                      'linked_transactions' => [
                          {
                              'id' => [{'id' => 'N11003', 'provider' => organization.oauth_provider, 'realm' => organization.oauth_uid}],
                              'class' => 'Invoice'
                          },
                          {
                              'id' => [{'id' => 'N11003', 'provider' => organization.oauth_provider, 'realm' => organization.oauth_uid}],
                              'class' => 'SalesOrder'
                          }
                      ]
                  }
              ],
              'amount' => {'currency' => 'AUD', 'total_amount' => 155.0},
              'title' => 'N11003',
              'person_id' => [{'id' => 'USER-ID', 'provider' => organization.oauth_provider, 'realm' => organization.oauth_uid}],
              'transaction_date' => '2016-06-12 23:26:26',
              'type' => 'CUSTOMER',
              'status' => 'ACTIVE'
          }
        }

        it 'maps to Connec! payment' do
          expect(subject.map_to('Payment', transaction)).to eql(connec_payment)
        end
      end

    end
  end
end
