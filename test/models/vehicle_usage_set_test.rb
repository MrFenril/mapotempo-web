require 'test_helper'

class VehicleUsageSetTest < ActiveSupport::TestCase

  def around
    Routers::RouterWrapper.stub_any_instance(:compute_batch, lambda { |url, mode, dimension, segments, options| segments.collect{ |i| [1, 1, '_ibE_seK_seK_seK'] } } ) do
      yield
    end
  end

  test 'should not save' do
    vehicle_usage_set = customers(:customer_one).vehicle_usage_sets.build
    assert_not vehicle_usage_set.save, 'Saved without required fields'
  end

  test 'should save' do
    vehicle_usage_set = customers(:customer_one).vehicle_usage_sets.build(name: '1', max_distance: 200000)
    vehicle_usage_set.save!
  end

  test 'should validate open and close time exceeding one day' do
    vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    vehicle_usage_set.update open: '08:00', close: '32:00'
    assert vehicle_usage_set.valid?
    assert_equal vehicle_usage_set.close, 32 * 3_600
  end

  test 'should validate open and close time from different type' do
    vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    vehicle_usage_set.update open: '08:00', close: 32 * 3_600
    assert vehicle_usage_set.valid?
    assert_equal vehicle_usage_set.close, 32 * 3_600
    vehicle_usage_set.update open: '08:00', close: '32:00'
    assert vehicle_usage_set.valid?
    assert_equal vehicle_usage_set.close, 32 * 3_600
    vehicle_usage_set.update open: '08:00', close: 115200.0
    assert vehicle_usage_set.valid?
    assert_equal vehicle_usage_set.close, 32 * 3_600
    vehicle_usage_set.update open: Time.parse('08:00'), close: '32:00'
    assert vehicle_usage_set.valid?
    assert_equal vehicle_usage_set.open, 8 * 3_600
    vehicle_usage_set.update open: DateTime.parse('2011-01-01 08:00'), close: '32:00'
    assert vehicle_usage_set.valid?
    assert_equal vehicle_usage_set.open, 8 * 3_600
    vehicle_usage_set.update open: 8.hours, close: '32:00'
    assert vehicle_usage_set.valid?
    assert_equal vehicle_usage_set.open, 8 * 3_600
  end

  test 'should update outdated for rest' do
    vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    customer = vehicle_usage_set.customer
    vehicle_usage = vehicle_usage_set.vehicle_usages[0]
    vehicle_usage.rest_duration = vehicle_usage.rest_start = vehicle_usage.rest_stop = nil
    vehicle_usage.save!
    nb_vu_no_rest = vehicle_usage_set.vehicle_usages.select{ |vu| vu.rest_duration.nil? && vu.rest_start.nil? && vu.rest_stop.nil? }.size
    assert nb_vu_no_rest > 0
    nb = (customer.vehicles.size - nb_vu_no_rest) * vehicle_usage_set.plannings.size
    assert nb > 0

    assert_difference('Stop.count', -nb) do
      vehicle_usage_set.vehicle_usages[0].routes[-1].compute
      vehicle_usage_set.vehicle_usages[0].routes[-1].outdated = false
      assert !vehicle_usage_set.rest_duration.nil?

      vehicle_usage_set.rest_duration = vehicle_usage_set.rest_start = vehicle_usage_set.rest_stop = nil
      vehicle_usage_set.save!
      vehicle_usage_set.customer.save!
      assert vehicle_usage_set.vehicle_usages[0].routes[-1].outdated
    end
  end

  test 'should update outdated for open' do
    vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    vehicle_usage_set.open = '09:00:00'
    assert_not vehicle_usage_set.vehicle_usages[0].routes[-1].outdated
    vehicle_usage_set.save!
    assert vehicle_usage_set.vehicle_usages[0].routes[-1].outdated
  end

  test 'should delete in use' do
    assert_difference('VehicleUsageSet.count', -1) do
      customers(:customer_one).vehicle_usage_sets.delete(vehicle_usage_sets(:vehicle_usage_set_one))
    end
  end

  test 'should keep at least one' do
    customer = customers(:customer_one)
    customer.vehicle_usage_sets[0..-2].each(&:destroy)
    customer.reload
    assert_equal 1, customer.vehicle_usage_sets.size
    assert !customer.vehicle_usage_sets[0].destroy
  end

  test 'should update outdated if service time or work time changed' do
    vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    route = vehicle_usage_set.vehicle_usages.sample.routes.take
    assert !route.outdated
    [:service_time_start, :service_time_end, :work_time].shuffle.each do |attr|
      assert vehicle_usage_set.send(attr).nil?
      vehicle_usage_set.update! attr => 10.minutes.to_i
      assert route.reload.outdated
    end
  end

  test 'setting a rest duration requires time start and stop' do
    vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    vehicle_usage_set.update! rest_start: nil, rest_stop: nil, rest_duration: nil
    assert vehicle_usage_set.valid?
    vehicle_usage_set.rest_duration = 15.minutes.to_i
    assert !vehicle_usage_set.valid?
    assert_equal [:rest_start, :rest_stop], vehicle_usage_set.errors.keys
    vehicle_usage_set.rest_start = 10.hours.to_i
    vehicle_usage_set.rest_stop = 11.hours.to_i
    assert vehicle_usage_set.valid?
  end

  test 'should validate work time in relation to the working time range and service range' do
    vehicle_usage_set = vehicle_usage_sets(:vehicle_usage_set_one)
    vehicle_usage_set.update open: '08:00', close: '18:00', work_time: '09:00'
    assert vehicle_usage_set.valid?
    vehicle_usage_set.update open: '08:00', close: '18:00', work_time: '12:00'
    assert_not vehicle_usage_set.valid?
    assert_equal [:work_time], vehicle_usage_set.errors.keys
    vehicle_usage_set.update open: '08:00', close: '18:00', service_time_start: '01:00', service_time_end: '01:00', work_time: '09:00'
    assert_not vehicle_usage_set.valid?
    assert_equal [:work_time], vehicle_usage_set.errors.keys
  end
end
