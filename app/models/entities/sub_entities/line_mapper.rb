class Entities::SubEntities::LineMapper
  extend HashMapper

  map from('id'), to('id')
  map from('unit_price/net_amount', &:to_f), to('price', &:to_s)
  map from('quantity'), to('quantity')
  map from('description'), to('title')
  map from('item_id'), to('variant_id')

  after_denormalize do |input, output|
	  output[:quantity] ||= 1

    if input['taxes_included']
      output[:unit_price][:total_amount] = output[:unit_price].delete(:net_amount)
    end

    total_tax_rate = input['tax_lines']&.map { |line| (line['rate']&.to_f) }.compact.sum&.to_f * 100.0
    unit_price_tax_amount = input['tax_lines']&.map { |line| (line['price']&.to_f / output[:quantity].to_f) }.compact.sum&.to_f
    output[:unit_price][:tax_rate] = total_tax_rate
    output[:unit_price][:tax_amount] = unit_price_tax_amount

    output[:description] = "Shipping: #{input['title']}" unless input['variant_id']

	  output
  end
end
