require 'spec_helper'

describe Entities::SubEntities::Order do

  describe 'class methods' do
    subject { Entities::SubEntities::Order }

    it { expect(subject.entity_name).to eql('Order') }
    it { expect(subject.external?).to eql(true) }
    it { expect(subject.object_name_from_external_entity_hash({'id' => 'ABC'})).to eql('ABC') }
  end

  describe 'instance methods' do
    let(:organization) { create(:organization) }
    let(:connec_client) { Maestrano::Connec::Client[organization.tenant].new(organization.uid) }
    let(:external_client) { Maestrano::Connector::Rails::External.get_client(organization) }
    let(:opts) { {} }
    subject { Entities::SubEntities::Order.new(organization, connec_client, external_client, opts) }
    describe 'map_to_connec' do

      let(:order) {
        {
            id: 'id',
            name: 'a sales order',
            order_number: '123456',
            financial_status: 'pending',
            customer: {id: 'person_id'},
            billing_address: {
                address1: 'line1',
                province: 'region',
                zip: 'postal_code',
                address2: 'line2',
                city: 'city',
                country_code: 'country'
            },
            shipping_address: {
                address1: 'shipping_address.line1',
                address2: 'shipping_address.line2',
                city: 'shipping_address.city',
                province: 'shipping_address.region',
                zip: 'shipping_address.postal_code',
                country_code: 'shipping_address.country'
            },
            closed_at: Date.new(1985, 9, 17).iso8601,
            line_items: [
                {
                    id: 'line_id',
                    price: 55,
                    quantity: '48',
                    title: 'description',
                    variant_id: 'item_id'
                }
            ]
        }
      }

      describe 'external to connec' do


        let(:connec_hash) {
          {
              id: [{id: 'id', provider: organization.oauth_provider, realm: organization.oauth_uid}],
              title: 'a sales order',
              transaction_number: '123456',
              status: 'DRAFT',
              person_id: [{id: 'person_id', provider: organization.oauth_provider, realm: organization.oauth_uid}],
              billing_address: {
                  line1: 'line1',
                  line2: 'line2',
                  city: 'city',
                  region: 'region',
                  postal_code: 'postal_code',
                  country: 'country'
              },
              shipping_address: {
                  line1: 'shipping_address.line1',
                  line2: 'shipping_address.line2',
                  city: 'shipping_address.city',
                  region: 'shipping_address.region',
                  postal_code: 'shipping_address.postal_code',
                  country: 'shipping_address.country'
              },
              transaction_date: Date.new(1985, 9, 17).iso8601,
              lines: [
                  {
                      id: [{id: 'line_id', provider: organization.oauth_provider, realm: organization.oauth_uid}],
                      unit_price: {
                          net_amount: 55
                      },
                      quantity: '48',
                      description: 'description',
                      item_id: [{id: 'item_id', provider: organization.oauth_provider, realm: organization.oauth_uid}]
                  }
              ]
          }
        }
        it { expect(subject.map_to('Sales Order', order.with_indifferent_access)).to eql(connec_hash.with_indifferent_access) }
      end

    end
    describe 'get_external_entities' do
      let(:orders) { [
          {
              'id' => 'order_id_1',
              'line_items' => [{'id' => 'line_item_1'}, {'id' => 'line_item_2'}],
              'customer' => {'id' => 'c1'}
          }, {
              'id' => 'order_id_2',
              'line_items' => [{'id' => 'line_item_3'}, {'id' => 'line_item_4'}],
              'customer' => {'id' => 'c2'}
          }
      ] }
      let(:transactions) { {
          'order_id_1' => [{'id' => 'transactions_1'}, {'id' => 'transactions_2'}],
          'order_id_2' => [{'id' => 'transactions_3'}, {'id' => 'transactions_4'}]
      }
      }
      let(:expected_orders) {
        [
            {
                'id' => 'order_id_1',
                'line_items' => [{'id' => 'line_item_1'}, {'id' => 'line_item_2'}],
                'customer' => {'id' => 'c1'},
                'transactions' => [
                    {'id' => 'transactions_1', 'order_id' => 'order_id_1', 'line_items' => [{'id' => 'line_item_1'}, {'id' => 'line_item_2'}], 'customer' => {'id' => 'c1'}},
                    {'id' => 'transactions_2', 'order_id' => 'order_id_1', 'line_items' => [{'id' => 'line_item_1'}, {'id' => 'line_item_2'}], 'customer' => {'id' => 'c1'}}
                ]
            }, {
                'id' => 'order_id_2',
                'line_items' => [{'id' => 'line_item_3'}, {'id' => 'line_item_4'}],
                'customer' => {'id' => 'c2'},
                'transactions' => [
                    {'id' => 'transactions_3', 'order_id' => 'order_id_2', 'line_items' => [{'id' => 'line_item_3'}, {'id' => 'line_item_4'}], 'customer' => {'id' => 'c2'}},
                    {'id' => 'transactions_4', 'order_id' => 'order_id_2', 'line_items' => [{'id' => 'line_item_3'}, {'id' => 'line_item_4'}], 'customer' => {'id' => 'c2'}}
                ]
            }
        ]
      }


      it 'returns the entities' do
        allow(external_client).to receive(:find).with('Order').and_return(orders)
        allow(external_client).to receive(:find).with('Transaction', {:order_id => 'order_id_1'}).and_return(transactions['order_id_1'])
        allow(external_client).to receive(:find).with('Transaction', {:order_id => 'order_id_2'}).and_return(transactions['order_id_2'])
        expect(subject.get_external_entities(nil)).to eql(expected_orders)
      end
    end

  end
end


