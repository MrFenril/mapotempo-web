if route.vehicle_usage_id && (!@params.key?(:stops) || @params[:stops].split('|').include?('store'))
  row = {
    ref_planning: route.planning.ref,
    planning: route.planning.name,
    route: route.ref || (route.vehicle_usage_id && route.vehicle_usage.vehicle.name.gsub(%r{[\./\\\-*,!:?;]}, ' ')),
    vehicle: (route.vehicle_usage.vehicle.ref if route.vehicle_usage_id),
    order: 0,
    stop_type: I18n.t('plannings.export_file.stop_type_store'),
    active: nil,
    wait_time: nil,
    time: route.start_absolute_time,
    distance: 0,
    drive_time: 0,
    out_of_window: nil,
    out_of_capacity: nil,
    out_of_drive_time: nil,
    out_of_work_time: nil,
    out_of_max_distance: nil,

    ref: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.ref,
    name: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.name,
    street: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.street,
    detail: nil,
    postalcode: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.postalcode,
    city: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.city
    }

  row.merge!(state: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.state) if route.planning.customer.with_state?

  row.merge!({
    country: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.country,
    lat: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.lat,
    lng: route.vehicle_usage.default_store_start && route.vehicle_usage.default_store_start.lng,
    comment: nil,
    phone_number: nil,
    tags: nil,

    ref_visit: nil,
    duration: nil,
    open1: nil,
    close1: nil,
    open2: nil,
    close2: nil,
    priority: nil,
    tags_visit: nil
  })

  row.merge!(Hash[route.planning.customer.enable_orders ?
    [[:orders, nil]] :
    route.planning.customer.deliverable_units.flat_map{ |du|
      [[('quantity' + (du.label ? '[' + du.label + ']' : '')).to_sym, nil],
      [('quantity_operation' + (du.label ? '[' + du.label + ']' : '')).to_sym, nil]]
    }
  ])

  csv << @columns.map{ |c| row[c.to_sym] }
end

index = 0
route.stops.each { |stop|
  if !@params.key?(:stops) || ((stop.active || !stop.route.vehicle_usage_id || @params[:stops].split('|').include?('inactive')) && (stop.route.vehicle_usage || @params[:stops].split('|').include?('out-of-route')) && (stop.is_a?(StopVisit) || @params[:stops].split('|').include?('rest')))
    row = {
      ref_planning: route.planning.ref,
      planning: route.planning.name,
      route: route.ref || (route.vehicle_usage_id && route.vehicle_usage.vehicle.name.gsub(%r{[\./\\\-*,!:?;]}, ' ')),
      vehicle: (route.vehicle_usage.vehicle.ref if route.vehicle_usage_id),
      order: (index+=1 if route.vehicle_usage_id),
      stop_type: stop.is_a?(StopVisit) ? I18n.t('plannings.export_file.stop_type_visit') : I18n.t('plannings.export_file.stop_type_rest'),
      active: ((stop.active ? '1' : '0') if route.vehicle_usage_id),
      wait_time: ("%i:%02i" % [stop.wait_time/60/60, stop.wait_time/60%60] if route.vehicle_usage_id && stop.wait_time),
      time: (stop.time_absolute_time if route.vehicle_usage_id && stop.time),
      distance: (stop.distance if route.vehicle_usage_id),
      drive_time: (stop.drive_time if route.vehicle_usage_id),
      out_of_window: stop.out_of_window ? 'x' : '',
      out_of_capacity: stop.out_of_capacity ? 'x' : '',
      out_of_drive_time: stop.out_of_drive_time ? 'x' : '',
      out_of_work_time: stop.out_of_work_time ? 'x' : '',
      out_of_max_distance: stop.out_of_max_distance ? 'x' : '',
      status: stop.status && I18n.t("plannings.edit.stop_status.#{stop.status.downcase}", default: stop.status),
      eta: stop.eta && I18n.l(stop.eta, format: :hour_minute),

      ref: stop.is_a?(StopVisit) ? stop.visit.destination.ref : stop.ref,
      name: stop.name,
      street: stop.street,
      detail: stop.detail,
      postalcode: stop.postalcode,
      city: stop.city,
    }

    row.merge!(state: stop.state) if route.planning.customer.with_state?

    row.merge!({
      country: stop.country,
      lat: stop.lat,
      lng: stop.lng,
      comment: stop.comment,
      phone_number: stop.phone_number,
      tags: (stop.visit.destination.tags.collect(&:label).join(',') if stop.is_a?(StopVisit)),

      ref_visit: (stop.visit.ref if stop.is_a?(StopVisit)),
      duration: stop.is_a?(StopVisit) ? (stop.visit.take_over ? stop.visit.take_over_absolute_time_with_seconds : nil) : (route.vehicle_usage.default_rest_duration ? route.vehicle_usage.default_rest_duration_time_with_seconds : nil),
      open1: (stop.open1_absolute_time if stop.open1),
      close1: (stop.close1_absolute_time if stop.close1),
      open2: (stop.open2_absolute_time if stop.open2),
      close2: (stop.close2_absolute_time if stop.close2),
      priority: (stop.priority if stop.priority),
      tags_visit: (stop.visit.tags.collect(&:label).join(',') if stop.is_a?(StopVisit))
    })

    row.merge!(Hash[route.planning.customer.enable_orders ?
      [[:orders, stop.is_a?(StopVisit) && stop.order && stop.order.products.length > 0 ? stop.order.products.collect(&:code).join('/') : nil]] :
      route.planning.customer.deliverable_units.flat_map{ |du|
        [[('quantity' + (du.label ? '[' + du.label + ']' : '')).to_sym, stop.is_a?(StopVisit) ? stop.visit.quantities[du.id] : nil],
        [('quantity_operation' + (du.label ? '[' + du.label + ']' : '')).to_sym, stop.is_a?(StopVisit) ? stop.visit.quantities_operations[du.id] && I18n.t("destinations.import_file.quantity_operation_#{stop.visit.quantities_operations[du.id]}") : nil]]
      }
    ])

    csv << @columns.map{ |c| row[c.to_sym] }
  end
}

if route.vehicle_usage_id && (!@params.key?(:stops) || @params[:stops].split('|').include?('store'))
  row = {
    ref_planning: route.planning.ref,
    planning: route.planning.name,
    route: route.ref || (route.vehicle_usage_id && route.vehicle_usage.vehicle.name.gsub(%r{[\./\\\-*,!:?;]}, ' ')),
    vehicle: (route.vehicle_usage.vehicle.ref if route.vehicle_usage_id),
    order: index+1,
    stop_type: I18n.t('plannings.export_file.stop_type_store'),
    active: nil,
    wait_time: nil,
    time: (route.end_absolute_time if route.end),
    distance: route.stop_distance,
    drive_time: route.stop_drive_time,
    out_of_window: nil,
    out_of_capacity: nil,
    out_of_drive_time: route.stop_out_of_drive_time ? 'x' : '',
    out_of_work_time: route.stop_out_of_work_time ? 'x' : '',
    out_of_max_distance: route.stop_out_of_max_distance ? 'x' : '',

    ref: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.ref,
    name: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.name,
    street: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.street,
    detail: nil,
    postalcode: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.postalcode,
    city: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.city,
    }

  row.merge!(state: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.state) if route.planning.customer.with_state?

  row.merge!({
    country: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.country,
    lat: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.lat,
    lng: route.vehicle_usage.default_store_stop && route.vehicle_usage.default_store_stop.lng,
    comment: nil,
    phone_number: nil,
    tags: nil,

    ref_visit: nil,
    duration: nil,
    open1: nil,
    close1: nil,
    open2: nil,
    close2: nil,
    priority: nil,
    tags_visit: nil
  })

  row.merge!(Hash[route.planning.customer.enable_orders ?
    [[:orders, nil]] :
    route.planning.customer.deliverable_units.flat_map{ |du|
      [[('quantity' + (du.label ? '[' + du.label + ']' : '')).to_sym, nil],
      [('quantity_operation' + (du.label ? '[' + du.label + ']' : '')).to_sym, nil]]
    }
  ])

  csv << @columns.map{ |c| row[c.to_sym] }
end
