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
require 'coerce'

class V01::Visits < Grape::API
  helpers SharedParams
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def visit_params
      p = ActionController::Parameters.new(params)
      p = p[:visit] if p.key?(:visit)
      if p[:quantities]
        p[:quantities_operations] = Hash[p[:quantities].map{ |q| [q[:deliverable_unit_id].to_s, q[:operation]] }]
        p[:quantities] = Hash[p[:quantities].map{ |q| [q[:deliverable_unit_id].to_s, q[:quantity]] }]
      end

      # Deals with deprecated open and close
      p[:open1] = p.delete(:open) unless p[:open1]
      p[:close1] = p.delete(:close) unless p[:close1]
      # Deals with deprecated quantity
      unless p[:quantities]
        p[:quantities] = {current_customer.deliverable_units[0].id.to_s => p.delete(:quantity)} if p[:quantity] && current_customer.deliverable_units.size > 0
        if p[:quantity1_1] || p[:quantity1_2]
          p[:quantities] = {}
          p[:quantities].merge!({current_customer.deliverable_units[0].id.to_s => p.delete(:quantity1_1)}) if p[:quantity1_1] && current_customer.deliverable_units.size > 0
          p[:quantities].merge!({current_customer.deliverable_units[1].id.to_s => p.delete(:quantity1_2)}) if p[:quantity1_2] && current_customer.deliverable_units.size > 1
        end
      end

      deliverable_unit_ids = current_customer.deliverable_units.map{ |du| du.id.to_s }
      p.permit(:ref, :take_over, :open1, :close1, :open2, :close2, :priority, tag_ids: [], quantities: deliverable_unit_ids, quantities_operations: deliverable_unit_ids)
    end

    ID_DESC = 'Id or the ref field value, then use "ref:[value]".'.freeze
  end

  resource :destinations do
    params do
      requires :destination_id, type: String, desc: ID_DESC
    end
    segment '/:destination_id' do

      resource :visits do
        desc 'Fetch destination\'s visits.',
          nickname: 'getVisits',
          is_array: true,
          success: V01::Entities::Visit
        params do
          optional :ids, type: Array[String], desc: 'Select returned visits by id separated with comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
        end
        get do
          destination_id = ParseIdsRefs.read(params[:destination_id])
          visits = if params.key?(:ids)
            current_customer.destinations.includes_visits.where(destination_id).first!.visits.select{ |visit|
              params[:ids].any?{ |s| ParseIdsRefs.match(s, visit) }
            }
          else
            current_customer.destinations.includes_visits.where(destination_id).first!.visits.load
          end
          present visits, with: V01::Entities::Visit
        end

        desc 'Fetch visit.',
          nickname: 'getVisit',
          success: V01::Entities::Visit
        params do
          requires :id, type: String, desc: ID_DESC
        end
        get ':id' do
          destination_id = ParseIdsRefs.read(params[:destination_id])
          id = ParseIdsRefs.read(params[:id])
          present current_customer.destinations.includes_visits.where(destination_id).first!.visits.where(id).first!, with: V01::Entities::Visit
        end

        desc 'Create visit.',
          nickname: 'createVisit',
          success: V01::Entities::Visit
        params do
          use :params_from_entity, entity: V01::Entities::Visit.documentation.except(
              :id,
              :destination_id,
              :tag_ids,
              :open1,
              :close1,
              :take_over,
              :open2,
              :close2,
              :priority)

          optional :tag_ids, type: Array[Integer], desc: 'Ids separated by comma.', coerce_with: CoerceArrayInteger, documentation: { param_type: 'form' }

          optional :quantities, type: Array do
            requires :deliverable_unit_id, type: Integer
            requires :quantity, type: Float
          end

          optional :open1, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
          optional :close1, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
          optional :take_over, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
          optional :open2, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
          optional :close2, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
        end
        post do
          destination_id = ParseIdsRefs.read(params[:destination_id])
          destination = current_customer.destinations.where(destination_id).first!
          visit = destination.visits.build(visit_params)
          visit.save!
          destination.customer.save!
          present visit, with: V01::Entities::Visit
        end

        desc 'Update visit.',
          detail: 'If want to force geocoding for a new address, you have to send empty lat/lng with new address.',
          nickname: 'updateVisit',
          success: V01::Entities::Visit
        params do
          requires :id, type: String, desc: ID_DESC
          use :params_from_entity, entity: V01::Entities::Visit.documentation.except(
              :id,
              :destination_id,
              :tag_ids,
              :open1,
              :close1,
              :take_over,
              :open2,
              :close2)

          optional :tag_ids, type: Array[Integer], desc: 'Ids separated by comma.', coerce_with: CoerceArrayInteger, documentation: { param_type: 'form' }

          optional :quantities, type: Array do
            requires :deliverable_unit_id, type: Integer
            requires :quantity, type: Float
          end

          optional :open1, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
          optional :close1, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
          optional :take_over, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
          optional :open2, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
          optional :close2, type: Integer, documentation: { type: 'string', desc: 'Schedule time (HH:MM)' }, coerce_with: ->(value) { ScheduleType.new.type_cast(value) }
        end
        put ':id' do
          destination_id = ParseIdsRefs.read(params[:destination_id])
          id = ParseIdsRefs.read(params[:id])
          destination = current_customer.destinations.where(destination_id).first!
          visit = destination.visits.where(id).first!
          visit.update! visit_params
          destination.customer.save!
          present visit, with: V01::Entities::Visit
        end

        desc 'Delete visit.',
          nickname: 'deleteVisit'
        params do
          requires :id, type: String, desc: ID_DESC
        end
        delete ':id' do
          destination_id = ParseIdsRefs.read(params[:destination_id])
          id = ParseIdsRefs.read(params[:id])
          destination = current_customer.destinations.where(destination_id).first!
          destination.visits.where(id).first!.destroy
          destination.customer.save!
          status 204
        end
      end
    end
  end

  resource :visits do
    desc 'Delete multiple visits.',
      nickname: 'deleteVisits'
    params do
      requires :ids, type: Array[String], desc: 'Ids separated by comma. You can specify ref (not containing comma) instead of id, in this case you have to add "ref:" before each ref, e.g. ref:ref1,ref:ref2,ref:ref3.', coerce_with: CoerceArrayString
    end
    delete do
      Visit.transaction do
        current_customer.visits.select{ |visit|
          params[:ids].any?{ |s| ParseIdsRefs.match(s, visit) }
        }.each(&:destroy)
        status 204
      end
    end
  end
end
