require 'test_helper'

class UserMailerTest < ActionMailer::TestCase

  test 'should send password email' do
    user_one = users(:user_one)
    reseller_name = user_one.customer.reseller.name
    email = UserMailer.password_message(user_one, I18n.locale)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['u1@plop.com'], email.to
    assert_equal I18n.t('user_mailer.password.subject', name: reseller_name), email.subject
  end

  test 'should send password email with uploaded image' do
    user_one = users(:user_one)
    reseller = user_one.customer.reseller
    reseller_name = user_one.customer.reseller.name
    file = Rack::Test::UploadedFile.new(Rails.root.join('test', 'fixtures', 'logo', 'logo_mapotempo.png'), 'image/png')
    reseller.logo_large = file
    reseller.save!

    email = UserMailer.password_message(user_one, I18n.locale)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['u1@plop.com'], email.to
    assert_equal I18n.t('user_mailer.password.subject', name: reseller_name), email.subject
  end

  test 'should send connection email' do
    user_one = users(:user_one)
    reseller_name = user_one.customer.reseller.name
    email = UserMailer.connection_message(user_one, I18n.locale)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ['u1@plop.com'], email.to
    assert_equal I18n.t('user_mailer.connection.subject', name: reseller_name), email.subject
  end

  test 'should ensure data validity for automation_dispatcher method' do
    user_one = users(:user_one)
    user_one.customer.reseller.help_url = 'https://www.mapotempo.com/{LG}/help-center'
    user_one.customer.reseller.contact_url = 'https://www.mapotempo.com/{LG}/help-center'

    raw_subjects = %w[accompanying_team features advanced_options]

    emails = [
      UserMailer.automation_dispatcher(user_one, I18n.locale, raw_subjects[0]),
      UserMailer.automation_dispatcher(user_one, I18n.locale, raw_subjects[1]),
      UserMailer.automation_dispatcher(user_one, I18n.locale, raw_subjects[2])
    ]

    assert_emails emails.size do
      emails.each_with_index { |email_delegate, index|
        email_delegate.deliver_now
        assert_equal I18n.t("user_mailer.#{ raw_subjects[index] }.panels_header"), email_delegate.subject
      }
    end

    # Instance_values get access to the Instantiate classes : UserMailer
    # fields is an array of objects like : Mail::Header, Mail::From etc.
    # the [1] is the Mail:From from which we get the full value (not only the email): MySuperComanyName <myroot@root.fr>
    from_value = emails[0].instance_values['header'].fields[1].value
    from_base = "#{user_one.customer.reseller.name} <#{Rails.application.config.default_from_mail}>"

    assert_equal from_base, from_value

    user_one.customer.reseller.help_url = nil
    user_one.customer.reseller.contact_url = nil
  end

  test 'should send an email trough rake task' do
    user_one = users(:user_one)
    creation_date = user_one.created_at

    user_one.update(created_at: DateTime.now.in_time_zone.midnight - 9.days)
    user_one.customer.reseller.update(contact_url: "https://www.mapotempo.com/{LG}/contact-support/", help_url: "https://www.mapotempo.com/{LG}/help-center")

    user_one.reload

    assert_emails 1 do
      Rake::Task['mail:automation'].invoke
    end

    assert_equal I18n.t('user_mailer.accompanying.title'), ActionMailer::Base.deliveries[0].subject

    user_one.update(created_at: creation_date)
    user_one.customer.reseller.update(contact_url: nil, help_url: nil)
  end
end
