# Copyright © Mapotempo, 2018
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
require 'notifications'
require "visit_quantities"

module PlanningsHelperApi

  def send_sms_route(route)
    notif = Notifications.new(
      api_key: route.planning.customer.reseller.sms_api_key,
      api_secret: route.planning.customer.reseller.sms_api_secret,
      from: route.planning.customer.sms_from_customer_name ? route.planning.customer.name : route.planning.customer.reseller.name,
      logger: Mapotempo::Application.config.logger_sms)
    route.stops.select{ |s| s.active && s.is_a?(StopVisit) && s.visit.destination.phone_number }.map{ |s|
      date = route.planning.date || Time.zone.today
      template = route.planning.customer.sms_template || route.planning.customer.name + '. ' + I18n.t('notifications.sms.alert_plan')
      repl = {
        date: I18n.l(date, format: :weekday),
        time: date.beginning_of_day + s.time,
        visit_ref: s.visit.ref,
        quantities: VisitQuantities.normalize(s.visit, nil).map{ |q| q[:quantity] }.join(' ').tr("\u202F", ' '),
        vehicle_name: route.vehicle_usage.vehicle.name
      }.merge(s.visit.destination.attributes.slice('name', 'ref', 'street', 'city', 'comment'))

      notif.send_sms(
        s.visit.destination.phone_number,
        s.visit.destination.country || route.planning.customer.default_country,
        notif.content(template, repl, !route.planning.customer.sms_concat),
        "SMc#{route.planning.customer_id}r#{route.id}t#{(date.beginning_of_day + s.time).to_i}"
      ).count{ |v| v }
    }.sum
  end

  def send_sms_planning(planning)
    planning.routes.select(&:vehicle_usage_id).map{ |r| send_sms_route(r) }.sum
  end
end

