# == gardener::compute_public_ip
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
# Use pinas compute lib to lookup public ip

def checkdebug
  begin
    if ENV['FACTER_DEBUG'] == 'true'
      Facter.debugging(true)
    end
  rescue
  end
end

#  require 'ruby-debug' ; Debugger.start

if Puppet.features.lorj_ready?
  require 'lorj_cloud'
  require "puppet/provider/pinas/lib/lorj"
end

if Puppet.features.fog_ready?
  require 'fog'                              if Puppet.features.fog?
  require "puppet/provider/pinas/lib/loader" if Puppet.features.pinas?
end

include ::Puppet::Forj::Facter if Puppet.features.factercache?

Facter.add("compute_public_ip") do
  setcode do
    prefix = 'Facter compute_public_ip: '
    res = (!Puppet.features.factercache?) ? nil : Cache.instance().cache("compute_public_ip") do
      checkdebug
      begin
        ::Puppet::LorjCloud.lorj_initialize
        config = ::Lorj::Config.new

        if Puppet.features.lorj_ready?
          compute_public_ip = ::Puppet::Lorj::Facter.get_compute_public_ip(prefix)
        end
        if Puppet.features.fog_ready?
          compute_public_ip = ::Puppet::Pinas::Facter.get_compute_public_ip(prefix)
        end
        compute_public_ip
      rescue Exception => e
        Facter.warn(prefix + "compute_public_ip failed, #{e}")
        :undefined
      end
    end
  end
end
