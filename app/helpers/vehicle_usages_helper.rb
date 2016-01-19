# Copyright © Mapotempo, 2016
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
module VehicleUsagesHelper

  def vehicle_usage_emission vehicle_usage
    return if !vehicle_usage.vehicle.emission
    '%s %s'.html_safe % [ vehicle_usage.vehicle.emission, t('all.unit.kgco2e_l_html') ]
  end

  def vehicle_usage_consumption vehicle_usage
    return if !vehicle_usage.vehicle.consumption
    '%s %s'.html_safe % [ vehicle_usage.vehicle.consumption, t('all.unit.l_100km') ]
  end

  def vehicle_usage_router vehicle_usage
    capture do
      if vehicle_usage.vehicle.router && vehicle_usage.vehicle.router.name
        concat vehicle_usage.vehicle.router.name
      elsif @customer.router
        concat content_tag(:span, @customer.router.name, style: 'color:grey')
      end
    end
  end

  def vehicle_usage_store_name item
    store_start = item.respond_to?(:default_store_start) ? item.default_store_start : item.store_start
    store_stop = item.respond_to?(:default_store_stop) ? item.default_store_stop : item.store_stop
    capture do
      if store_start || store_stop
        if store_start
          concat '%s ' % [ store_start.name ]
        else
          concat fa_icon('ban', title: t('vehicle_usages.index.store.no_start'))
        end
        if store_start != store_stop
          concat fa_icon('long-arrow-right')
          concat ' '
          if store_stop
            concat ' %s' % [ store_stop.name ]
          else
            concat fa_icon('ban', title: t('vehicle_usages.index.store.no_stop'))
          end
        elsif store_start
          concat fa_icon('exchange', title: t('vehicle_usages.index.store.same_start_stop'))
        end
      end
    end
  end

  def vehicle_usage_store_hours vehicle_usage
    capture do
      if vehicle_usage.open
        concat l(vehicle_usage.open, format: :hour_minute)
        concat ' - '
      elsif vehicle_usage.vehicle_usage_set.open
        concat content_tag(:span, l(vehicle_usage.vehicle_usage_set.open, format: :hour_minute), style: 'color:grey')
        concat content_tag(:span, ' - ', style: 'color:grey')
      end
      if vehicle_usage.close
        concat l(vehicle_usage.close, format: :hour_minute)
      elsif vehicle_usage.vehicle_usage_set.close
        concat content_tag(:span, l(vehicle_usage.vehicle_usage_set.close, format: :hour_minute), style: 'color:grey')
      end
    end
  end

  def vehicle_usage_service_time vehicle_usage
    capture do
      if vehicle_usage.service_time_start
        concat l(vehicle_usage.service_time_start, format: :hour_minute)
      elsif vehicle_usage.vehicle_usage_set.service_time_start
        concat content_tag(:span, l(vehicle_usage.vehicle_usage_set.service_time_start, format: :hour_minute), style: 'color:grey')
      end
      concat content_tag(:span, ' - ', style: 'color:grey')
      if vehicle_usage.service_time_end
        concat l(vehicle_usage.service_time_end, format: :hour_minute)
      elsif vehicle_usage.vehicle_usage_set.service_time_end
        concat content_tag(:span, l(vehicle_usage.vehicle_usage_set.service_time_end, format: :hour_minute), style: 'color:grey')
      end
    end
  end

  def service_time_export vehicle_usage
    return {
      start_value: vehicle_usage.default_service_time_start_value,
      start_str: (l(vehicle_usage.default_service_time_start, format: :hour_minute) if vehicle_usage.default_service_time_start),
      end_value: vehicle_usage.default_service_time_end_value,
      end_str: (l(vehicle_usage.default_service_time_end, format: :hour_minute) if vehicle_usage.default_service_time_end)
    }
  end

  def route_description route
    capture do
      concat [ route.size_active, t('plannings.edit.stops') ].join(' ')
      if route.start && route.end
        concat ' - %i:%02i - ' % [
          (route.end - route.start) / 60 / 60,
          (route.end - route.start) / 60 % 60
        ]
      end
      concat number_to_human(route.distance, units: :distance, precision: 3)
      if route.vehicle_usage.default_service_time_start
        concat ' - %s: %s' % [
          t('activerecord.attributes.vehicle_usage.service_time_start'),
          l(route.vehicle_usage.default_service_time_start, format: :hour_minute)
        ]
      end
      if route.vehicle_usage.default_service_time_end
        concat ' - %s: %s' % [
          t('activerecord.attributes.vehicle_usage.service_time_end'),
          l(route.vehicle_usage.default_service_time_end, format: :hour_minute)
        ]
      end
    end
  end
end
