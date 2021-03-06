// Copyright © Mapotempo, 2013-2017
//
// This file is part of Mapotempo.
//
// Mapotempo is free software. You can redistribute it and/or
// modify since you respect the terms of the GNU Affero General
// Public License as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Mapotempo is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with Mapotempo. If not, see:
// <http://www.gnu.org/licenses/agpl.html>
//
'use strict';

var customers_index = function(params) {
  'use strict';

  var map_layers = params.map_layers,
    map_attribution = params.map_attribution;

  var is_map_init = false;

  var map_init = function() {

    var map = mapInitialize(params);
    L.control.attribution({
      prefix: false
    }).addTo(map);

    var layer = L.featureGroup();
    map.addLayer(layer);


    function determineIconColor(customer) {

      var color = {
        isActiv: '558800', // green
        isNotActiv: '707070', // grey
        isTest: '0077A3' // blue
      };

      return customer.test ? color.isTest : (customer.isActiv ? color.isActiv : color.isNotActiv);

    }

    var display_customers = function(data) {

      $.each(data.customers, function(i, customer) {

        var iconImg = '/images/point-' + determineIconColor(customer) + '.svg';

        var marker = L.marker(new L.LatLng(customer.lat, customer.lng), {

          icon: new L.NumberedDivIcon({
            number: customer.max_vehicles,
            iconUrl: iconImg,
            iconSize: new L.Point(12, 12),
            iconAnchor: new L.Point(6, 6),
            popupAnchor: new L.Point(0, -6),
            className: "small"
          })

        }).addTo(layer).bindPopup(customer.name);

      });

      map.invalidateSize();

      if (layer.getLayers().length > 0) {
        map.fitBounds(layer.getBounds(), {
          maxZoom: 15,
          padding: [20, 20]
        });
      }

    };

    $.ajax({
      url: '/customers.json',
      beforeSend: beforeSendWaiting,
      success: display_customers,
      complete: completeWaiting,
      error: ajaxError
    });

  };

  $('#accordion').on('show.bs.collapse', function() {
    if (!is_map_init) {
      is_map_init = true;
      map_init();
    }
  });
};

var customers_edit = function(params) {
  'use strict';

  /* Speed Multiplier */
  $('form.number-to-percentage').submit(function(e) {
    $.each($(e.target).find('input[type=\'number\'].number-to-percentage'), function(i, element) {
      var value = $(element).val() ? Number($(element).val()) / 100 : 1;
      $($(document.createElement('input')).attr('type', 'hidden').attr('name', 'customer[' + $(element).attr('name') + ']').val(value)).insertAfter($(element));
    });
    return true;
  });

  /* API: Devices */
  devicesObserveCustomer.init($.extend(params, {
    // FIXME -> THE DEFAULT PASSWORD MUST BE DONE AT THE BACKEND LVL, WHICH MAKE NOT VISIBLE THE TRUE PASSWORD FROM DB
    default_password: Math.random().toString(36).slice(-8)
  }));

  $('#customer_end_subscription').datepicker({
    autoclose: true,
    calendarWeeks: true,
    todayHighlight: true,
    format: I18n.t("all.datepicker"),
    language: I18n.currentLocale(),
    zIndexOffset: 1000
  });

  $('#customer_take_over').timeEntry({
    show24Hours: true,
    showSeconds: true,
    initialField: 1,
    defaultTime: '00:00:00',
    spinnerImage: ''
  });

  var getLocaleFromCurrentLocale = function() {
    for (var locale in $.fn.wysihtml5.locale) {
      if (locale.indexOf(I18n.currentLocale()) !== -1) {
        return locale;
      }
    }
  };

  $('#customer_print_header').wysihtml5({
    locale: getLocaleFromCurrentLocale(),
    toolbar: {
      link: false,
      image: false,
      blockquote: false,
      size: 'sm',
      fa: true
    }
  });

  var smsCharacterCount = function() {
    var count = ($('#customer_sms_template').val() || $('#customer_sms_template').attr('placeholder')).length;
    var color = count > 160 ? 'red' : count > 140 ? 'darkorange' : 'black';
    $('#sms_character_count').html('<span style="color: ' + color + '">' + I18n.t('customers.form.sms_character_count', {c: count}) + '</span>');
  };
  if ($('#customer_sms_template').length) {
    smsCharacterCount();
    $('#customer_sms_template').on('keyup', smsCharacterCount);
  }

  routerOptionsSelect('#customer_router', params);
};

var devicesObserveCustomer = (function() {
  'use strict';

  function _devicesInitCustomer(base_name, config, params) {
    var requests = [];

    function clearCallback() {
      $('.' + config.name + '-api-sync').attr('disabled', 'disabled');
      $('#' + config.name + '_container').removeClass('panel-success panel-danger').addClass('panel-default');
    }

    function successCallback() {
      $('.' + config.name + '-api-sync').removeAttr('disabled');
      $('#' + config.name + '_container').removeClass('panel-default panel-danger').addClass('panel-success');
    }

    // maybe need rework on this one - WARNING -
    function errorCallback(apiError) {
      stickyError(apiError);
      $('.' + config.name + '-api-sync').attr('disabled', 'disabled');
      $('#' + config.name + '_container').removeClass('panel-default panel-success').addClass('panel-danger');
    }

    function _userCredential() {
      var hash = {};
      $.each(config.forms.settings, function(key) {
        hash[key] = $('#' + base_name + '_' + config.name + '_' + key).val() || void(0);
        if (key == 'password' && hash[key] == params.default_password)
          hash[key] = void(0);
      });
      return hash;
    }

    function _allFieldsFilled() {
      var isNotEmpty = true;
      var inputs = $('input[type="text"], input[type="password"]', '#' + config.name + '_container');
      inputs.each(function() {
        if ($(this).val() === '') {
          isNotEmpty = false;
        }
      });
      return !!(inputs.length && isNotEmpty);
    }

    function _ajaxCall(all) {
      $.when($(requests)).done(function() {
        if (!_allFieldsFilled()) return;
        requests.push($.ajax({
          url: '/api/0.1/devices/' + config.name + '/auth/' + params.customer_id + '.json',
          data: (all) ? _userCredential() : $.extend(_userCredential(), {
            check_only: 1
          }),
          dataType: 'json',
          beforeSend: function() {
            if (!all) hideNotices();
            beforeSendWaiting();
          },
          complete: completeWaiting,
          success: function(data) {
            (data && data.error) ? errorCallback(data.error) : successCallback();
          },
          error: function(jqXHR, textStatus) {
            errorCallback(jqXHR.status === 400 && textStatus === 'error' ? I18n.t('customers.form.devices.sync.no_credentials') : textStatus);
          }
        }));
      });
    }

    // Check Credentials Without Before / Complete Callbacks ----- TRANSLATE IN ERROR CALL ISN'T SET
    function checkCredentials() {
      if (!_allFieldsFilled()) return;
      _ajaxCall(true);
    }

    // Check Credentials: Observe User Events with Delay
    var _observe = function() {
      var timeout_id;

      // Anonymous function handle setTimeout()
      var checkCredentialsWithDelay = function() {
        if (timeout_id) clearTimeout(timeout_id);
        timeout_id = setTimeout(function() { _ajaxCall(false); }, 750);
      };

      $("#" + config.name + "_container").find("input").on('keyup', function() {
        clearCallback();
        checkCredentialsWithDelay();
      });
    };

    /* Password Inputs: set fake password  (input view fake) */
    if ("password" in config) {
      var password_field = '#' + [base_name, config.name, "password"].join('_');
      if ($(password_field).val() == '') {
        $(password_field).val(params.default_password);
      }
    }

    // Sync
    $('.' + config.name + '-api-sync').on('click', function() {
      if (confirm(I18n.t('customers.form.devices.sync.confirm'))) {
        $.ajax({
          url: '/api/0.1/devices/' + config.name + '/sync.json',
          type: 'POST',
          data: $.extend(_userCredential(), {
            customer_id: params.customer_id
          }),
          beforeSend: beforeSendWaiting,
          complete: completeWaiting,
          success: function() {
            alert(I18n.t('customers.form.devices.sync.complete'));
          }
        });
      }
    });

    // Check credantial for current device config
    // Observe Widget if Customer has Service Enabled or Admin (New Customer)
    checkCredentials();
    _observe();
  }

  /* Chrome / FF, Prevent Sending Default Password
     The browsers would ask to remember it. */
  (function() {
    $('form.clear-passwords').on('submit', function(e) {
      $.each($(e.target).find('input[type=\'password\']'), function(i, element) {
        if ($(element).val() == params.default_password) {
          $(element).val('');
        }
      });
      return true;
    });
  })();

  var initialize = function(params) {
    $.each(params['devices'], function(deviceName, config) {
      config.name = deviceName;
      _devicesInitCustomer('customer_devices', config, params);
    });

    // Create company with mobile users for each vehicle with email
    $('#create-customer-device').on('click', function(event) {
      event.preventDefault();
      $('#create-customer-device').attr('disabled', true);

      $.ajax({
        type: 'GET',
        url: '/api/0.1/devices/fleet/create_company.json',
        data: {
          customer_id: params.customer_id
        },
        dataType: 'json',
        beforeSend: beforeSendWaiting,
        success: function(data) {
          $('#create-customer-device').attr('disabled', false);

          if (!data) {
            return;
          } else if (data.error) {
            stickyError(data.error);
            return;
          }

          location.reload();
        },
        error: function(error) {
          $('#create-customer-device').attr('disabled', false);
          stickyError(error.statusText + ' : ' + error.responseJSON.message);
        },
        complete: completeWaiting
      });
    });

    // Create mobile users for each vehicle with user
    $('#create-user-device').on('click', function(event) {
      event.preventDefault();
      $('#create-user-device').attr('disabled', true);

      $.ajax({
        type: 'GET',
        url: '/api/0.1/devices/fleet/create_drivers.json',
        data: {
          customer_id: params.customer_id
        },
        dataType: 'json',
        beforeSend: beforeSendWaiting,
        success: function(data) {
          $('#create-user-device').attr('disabled', false);

          if (!data) {
            return;
          } else if (data.error) {
            stickyError(data.error);
            return;
          }

          var drivers = [I18n.t('customers.form.devices.fleet.drivers_created')];
          data.map(function(driver) {
            drivers.push(driver.email + ' : ' + driver.password);
          });

          notice(drivers.join('\r\n'));
        },
        error: function(error) {
          $('#create-user-device').attr('disabled', false);
          stickyError(error.statusText);
        },
        complete: completeWaiting
      });
    });
  };

  return { init: initialize };
})();

Paloma.controller('Customers', {
  index: function() {
    customers_index(this.params);
  },
  new: function() {
    customers_edit(this.params);
  },
  create: function() {
    customers_edit(this.params);
  },
  edit: function() {
    customers_edit(this.params);
  },
  update: function() {
    customers_edit(this.params);
  }
});
