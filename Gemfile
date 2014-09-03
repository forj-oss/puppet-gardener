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

source 'https://rubygems.org'

group(:development, :test) do
  if ENV.key?('PUPPET_VERSION')
    puppetversion = "= #{ENV['PUPPET_VERSION']}"
  else
    puppetversion = ['2.7.25']
  end
  gem 'puppet', puppetversion, :require => false
  gem 'puppetlabs_spec_helper', '0.5.1'
  gem 'puppet-lint', '0.3.2'
  gem 'rake'
  gem 'ruby-debug'
  gem 'rspec', "~> 2.10.0", :require => false
end

`puppet resource package build-essential ensure=present`
`puppet resource package vim ensure=present`
`puppet resource package git ensure=present`
`puppet resource package make ensure=present`
`puppet resource package dos2unix ensure=present`
`puppet resource package libxslt-dev ensure=present`
`puppet resource package libxml2-dev ensure=present`
gem 'mocha','0.12.10'
gem 'mime-types','1.25.1'
gem 'excon','0.31.0'
gem 'json','~>1.7.5'
gem 'nokogiri','1.5.11'
gem 'fog', '1.19.0'
gem 'hpcloud', '2.0.8'
# HOWTO Install:
# Install puppet
# -- /opt/workspace/git/maestro/puppet/install_puppet.sh 
# Install 3rd party modules
# -- /opt/workspace/git/maestro/puppet/install_modules.sh 
# Install hiera
# -- /opt/workspace/git/maestro/hiera/hiera.sh 

# gem1.8 install bundler --no-rdoc --no-ri
# bundle install --gemfile .gemfile

# Testing:
# configure cloud.fog file, see README.md
# rake spec
