class Entities::Item < Maestrano::Connector::Rails::Entity

  def self.connec_entity_name
    'Item'
  end

  def self.external_entity_name
    'Variant'
  end

  def self.mapper_class
    ItemMapper
  end

  def self.object_name_from_connec_entity_hash(entity)
    entity['name']
  end

  def self.object_name_from_external_entity_hash(entity)
    entity['title']
  end

  def self.get_product_variants(product)
    product['variants'].each do |variant|
      variant['product_id'] = product['id']
      variant['product_title'] = product['title']
      variant['body_html'] = product['body_html']
      variant['updated_at'] = [variant['updated_at'].to_time, product['updated_at'].to_time].max.iso8601
    end
    product['variants']
  end

  def get_external_entities(client, last_synchronization, organization, opts={})
    entities = client.find('Product')
    entities.map { |product|
      self.class.get_product_variants(product)
    }.flatten!
    entities
  end


  def create_connec_entity(connec_client, external_entity, connec_entity_name, organization)
    connec_entity = super
    create_or_update_product_id_map external_entity, connec_entity, organization
    connec_entity
  end

  def update_connec_entity(connec_client, external_entity, connec_id, connec_entity_name, organization)
    connec_entity = super
    create_or_update_product_id_map external_entity, connec_entity, organization
    connec_entity
  end

  def create_or_update_product_id_map(external_entity, connec_entity, organization)
    product_id_map = Maestrano::Connector::Rails::IdMap.find_or_create_by(external_id: external_entity[:product_id], connec_id: connec_entity['id'], connec_entity: self.class.connec_entity_name, external_entity: 'product', organization_id: organization.id)
    product_id_map.update_attributes(last_push_to_external: Time.now, message: nil, name: external_entity[:product_name])
  end


  def push_entity_to_external(client, mapped_connec_entity_with_idmap, external_entity_name, organization)
    idmap = mapped_connec_entity_with_idmap[:idmap]
    connec_entity = mapped_connec_entity_with_idmap[:entity]

    begin
      title = connec_entity[:product_title]
      product = {
          title: title,
          body_html: connec_entity[:body_html],
          variants: [connec_entity]
      }
      if idmap.external_id.blank?
        created_entity = client.update('Product', product)
        idmap.update_attributes(external_id: created_entity['variants'][0]['id'], last_push_to_external: Time.now, message: nil)
        product_id_map = Maestrano::Connector::Rails::IdMap.find_or_create_by(external_id: created_entity['id'], connec_id: idmap.connec_id, connec_entity: self.class.connec_entity_name, external_entity: 'product', organization_id: organization.id)
        product_id_map.update_attributes(last_push_to_external: Time.now, message: nil, name: title)
      else
        connec_entity[:id] = idmap.external_id
        product_id_map = Maestrano::Connector::Rails::IdMap.find_by(connec_id: idmap.connec_id, connec_entity: self.class.connec_entity_name, external_entity: 'product', organization_id: organization.id)
        product[:id] = product_id_map.external_id
        client.update('Product', product)
        idmap.update_attributes(last_push_to_external: Time.now, message: nil)
        product_id_map.update_attributes(last_push_to_external: Time.now, message: nil)
      end
    rescue => e
      # Store External error
      Maestrano::Connector::Rails::ConnectorLogger.log('error', organization, "Error while pushing to #{Maestrano::Connector::Rails::External.external_name}: #{e}")
      idmap.update_attributes(message: e.message)
    end
  end


  class ItemMapper
    extend HashMapper
    # normalize from Connec to Shopify
    # denormalize from Shopify to Connec
    # map from (connect_field) to (shopify_field)
    map from('description'), to('body_html')
    map from('product_id'), to('product_id')
    map from('code'), to('sku')
    map from('sale_price/net_amount'), to('price')
    map from('quantity_available'), to('inventory_quantity', &:to_i)

    map from('weight'), to('weight')
    map from('weight_unit'), to('weight_unit')
    map from('description'), to('body_html')

    after_normalize do |input, output|
      output[:product_title] = input['name']
      output[:inventory_management] = input['is_inventoried'] ? 'shopify' : nil
      output
    end

    after_denormalize do |input, output|
      output[:name] = input['product_title']
      output[:name] += ' ' +  input['title'] if input['title']  && input['title'] != 'Default Title'
      output[:product_name] = input['product_title']
      output[:is_inventoried] = input['inventory_management'] == 'shopify'
      output
    end

  end

end


