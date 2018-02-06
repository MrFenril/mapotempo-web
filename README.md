Mapotempo [![Build Status](https://travis-ci.org/Mapotempo/mapotempo-web.svg?branch=dev)](https://travis-ci.org/Mapotempo/mapotempo-web)
=========
Route optimization with numerous stops. Based on [OpenStreetMap](http://www.openstreetmap.org) and [OR-Tools](http://code.google.com).

## Installation

1. [Project dependencies](#project-dependencies)
2. [Install Bundler Gem](#install-bundler-gem)
3. [Install Node modules](#install-node-modules)
4. [Requirements for all systems](#requirements-for-all-systems)
5. [Install project](#install-project)
6. [Configuration](#configuration)
7. [Background Tasks](#background-tasks)
8. [Initialization](#Initialization)
9. [Running](#running)
10. [Running on producton](#running-on-production)
11. [Launch tests](#launch-tests)

### Project dependencies

#### On Fedora

Install ruby (>2.0 is needed), bundler and some dependencies from system package.

    yum install ruby ruby-devel rubygem-bundler postgresql-devel libgeos++-dev

#### On Mac OS

Install ruby (>2.0 is needed), bundler and some dependencies from system package.

    brew install icu4c
    bundle config build.charlock_holmes --with-icu-dir=/usr/local/opt/icu4c

#### On other systems

Install Ruby (> 2.0 is needed) and other dependencies from system package.

For example, with __Ubuntu__, follows this instructions:

To know the last version, check with this command tools

    apt-cache search [package_name]

First, install Ruby :

    sudo apt install ruby2.1.8 ruby2.1.8-dev

Next, install Postgrsql environment:

     postgresql postgresql-client-9.6 postgresql-server-dev-9.6

You need some others libs :

    libz-dev libicu-dev build-essential g++ libgeos-dev libgeos++-dev

__It's important to have all of this installed packages before installing following gems.__

### Install Bundler Gem

Bundler provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed.
For more information see [Bundler website](http://bundler.io).

To install Bundler Ruby Gem:

    export GEM_HOME=~/.gem/ruby/2.1.8
    gem install bundler

The GEM_HOME variable is the place who are stored Ruby gems.

### Install Node modules

In addition to gems, node modules must be installed for Javascript files.
To install all dependencies, run the following command after installing yarn:

    yarn install

All packages will be available through _node_modules_ directory.

If a npm package includes assets, they must be declared in the _config/initializers/assets.rb_ file:

    Rails.application.config.assets.paths += Dir["#{Rails.root}/node_modules/package/asset_dir"]

## Requirements for all systems

Now add gem bin directory to path with :

    export PATH=$PATH:~/.gem/ruby/2.1.8/bin

Add Environement Variables into the end of your .bashrc file:

    nano ~/.bashrc

Add following code:

    # RUBY GEM CONFIG
    export GEM_HOME=~/.gem/ruby/2.1.8
    export PATH=$PATH:~/.gem/ruby/2.1.8/bin

Save changes and Quit

Run this command to activate your modifications:

    source ~/.bashrc

### Install project

For the following installation, your current working directory needs to be the mapotempo-web root directory.

Clone the project:

    git clone git@github.com:Mapotempo/mapotempo-web.git

Go to project directory:

    cd mapotempo-web

Add the ruby version :

    echo '2.1.8' >> .ruby-version

And finally install gem project dependencies with:

    bundle install

If you have this message:
>Important: You may need to add a javascript runtime to your Gemfile in order for bootstrap's LESS files to compile to CSS.

Don't worry, we use SASS to compile CSS and not LESS.

## Configuration

### Override variables
Default project configuration is in `config/application.rb` you can override any setting by create a `config/initializers/mapotempo.rb` file and override any variable.

External resources can be configured trough environment variables:
* POSTGRES_USERNAME, default: 'mapotempo'
* POSTGRES_PASSWORD, default: 'mapotempo'
* POSTGRES_DATABASE', default: 'mapotempo-test', 'mapotempo-dev' or 'mapotempo-prod'
* REDIS_HOST', default: 'localhost', production environment only
* OPTIMIZER_URL, default: 'http://localhost:1791/0.1'
* OPTIMIZER_API_KEY, default: 'demo'
* GEOCODER_URL, default: 'http://localhost:8558/0.1'
* GEOCODER_API_KEY, default: 'demo'
* ROUTER_URL, default: 'http://localhost:4899/0.1'
* ROUTER_API_KEY, default: 'demo'
* HERE_APP_ID
* HERE_APP_CODE
* DEVICE_TOMTOM_API_KEY
* DEVICE_FLEET_ADMIN_API_KEY

### Background Tasks
Delayed job (background task) can be activated by setting `Mapotempo::Application.config.delayed_job_use = true` it's allow asynchronous running of import geocoder and optimization computation.

Default configuration point on public [OSRM](http://project-osrm.org) API but matrix computation heavily discouraged on it. So point on your own instance.

## Initialization

Check database configuration in `config/database.yml` and from project directory create a database for your environment with :

As postgres user:

    sudo -i -u postgres

Create user and databases:

    createuser -s [username]
    createdb -E UTF8 -T template0 -O [username] mapotempo-dev
    createdb -E UTF8 -T template0 -O [username] mapotempo-test

Create a `config/application.yml` file and set variables :

```
PG_USERNAME: "[username]"
PG_PASSWORD: "[userpassword]"
```

By default, the *user*/*password* variables are set to *mapotempo*/*mapotempo*

For informations, to __delete a user__ use:

    dropuser [username]

To __delete a database__ :

    dropdb [database]

As normal user, we call rake to initialize databases (load schema and demo data):

    rake db:setup

## Running

Start standalone rails server with:

    rails server

Start Webpack to auto-compile JS assets (and reload browser on change):

    ./bin/webpack-dev-server

Enjoy at [http://localhost:3000](http://localhost:3000)

To run both server in on command, you can launch Guard (configuration in _Guardfile_):

    guard

Start the background jobs runner with

    ./bin/delayed_job run

## Running on production

Setup assets:

    rake i18n:js:export
    rake assets:precompile

## Launch tests

    rake test

If you focus one test only or for any other good reasons, you don't want to check i18n and coverage:

    rake test I18N=false COVERAGE=false
