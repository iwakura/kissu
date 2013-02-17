#!/usr/bin/env rackup

require File.join(File.dirname(__FILE__), 'config/boot.rb')

use Rack::MethodOverride
use Rack::Session::Cookie, :secret => 'ca12d1d36c6bc8ef649331f44cf9718b'
use Rack::Csrf, :raise => true

require './app.rb'
run Seppun

