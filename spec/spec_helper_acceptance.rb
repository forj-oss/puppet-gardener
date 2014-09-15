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
require 'debugger' if ENV['RAKE_DEBUG'] == 'true'
require 'beaker-rspec'
require 'spec_utilities'

include ::SpecUtilities::Puppet
UNSUPPORTED_PLATFORMS = [ 'Windows', 'Solaris', 'AIX' ]

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  # This will install the latest available package on el and deb based
  # systems fail on windows and osx, and install via gem on other *nixes
  foss_opts = { :default_action => 'gem_install' }

#  if default.is_pe?; then install_pe; else install_puppet( foss_opts ); end

  hosts.each do |host|
    on hosts, "mkdir -p #{host['distmoduledir']}"
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  c.filter_run :default => true
  c.filter_run :long_run => is_long_run_enabled?

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|
      # Required for binding tests.
#      if fact('osfamily') == 'RedHat'
#        version = fact("operatingsystemmajrelease")
#        shell("yum localinstall -y http://yum.puppetlabs.com/puppetlabs-release-el-#{version}.noarch.rpm")
#      end

      # commands occur on default host
      shell("/bin/touch #{default['puppetpath']}/hiera.yaml")
      shell("rm -rf /etc/puppet/modules/#{get_module_name}")
#     we should install dependent modules
#      shell('puppet module install puppetlabs-stdlib --version 3.2.0', { :acceptable_exit_codes => [0,1] })
#      on host, puppet('module','install','stahnma/epel'), { :acceptable_exit_codes => [0,1] }

      # setup fog creds from local hosts
      # create fog_rc : /opt/config/fog/cloud.fog
      fog_rc = ENV['FOG_RC']
      raise "\n\nMissing export FOG_RC=yourpath/cloud.fog\n\n" if fog_rc == nil or fog_rc == ''
      raise "\n\n#{fog_rc} not found for FOG_RC\n\n" if ! File.exists?(fog_rc)
      shell("mkdir -p #{File.join('','opt','config','fog')}")
      scp_to host, ENV['FOG_RC'], File.join('','opt','config','fog','cloud.fog')

    end
    CUSTOM_INSTALL_IGNORE = ['.bundle', 
                             '.git', 
                             '.idea', 
                             '.vagrant', 
                             '.vendor', 
                             'acceptance', 
                             'tests', 
                             'log',
                             'spec/facter',
                             'spec/acceptance',
                             'spec/classes',
                             'spec/defines',
                             'spec/functions' ]
    puppet_module_install(:source => proj_root, :module_name => get_module_name, :ignore_list => CUSTOM_INSTALL_IGNORE)
  end
end
