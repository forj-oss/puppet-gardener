# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
source 'https://rubygems.org'

group(:development, :test) do
  if ENV.key?('PUPPET_VERSION')
    puppetversion = "= #{ENV['PUPPET_VERSION']}"
  else
    puppetversion = ['2.7.25']
  end
  gem 'puppet', puppetversion, :require => false
  gem 'puppetlabs_spec_helper'
  gem 'puppet-lint'
  gem 'rake'
  gem 'rspec', "~> 2.10.0", :require => false
end

gem 'mime-types','1.25.1'
gem 'excon','0.31.0'
gem 'json'
gem 'nokogiri','1.5.11'
gem 'fog', '1.19.0'

# install with :$
# gem1.8 install bundler$
# bundle install --gemfile Gemfile