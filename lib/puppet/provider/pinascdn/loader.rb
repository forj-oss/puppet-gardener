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
# we want to identify the correct library to load outside
# a provider, so we use the fog provider to load the correct library

if Puppet.features.pinas?
  require 'puppet/provider/pinas/lib/common'
  require 'puppet/provider/pinas/lib/manager/provider'
  require 'puppet/provider/pinas/lib/pinascdn'
end


module Pinas
  module Cdn
    module Provider


      if Puppet.features.pinas?
        include ::Pinas::Common
        include ::Puppet::PinasProvider
      end


      class Cdn < ::Puppet::Pinas::Cdn 
        if Puppet.features.pinas?
          include ::Pinas::Common
          include ::Puppet::PinasProvider
        end
      end


      class Loader
        if Puppet.features.pinas?
          extend ::Pinas::Common
          extend ::Puppet::PinasProvider
          Puppet.debug("Loading Pinas::Cdn::Provider::Loader...")
          case get_provider
          when :hp, "hp", :openstack, "openstack"
            require 'puppet/provider/pinas/lib/cdn/hp'
            extend ::Puppet::PinasCdnHP
            Puppet.debug "loadded Pinas::Cdn::Provider::Loader for #{get_provider}"
          else
            Puppet.warning "Pinas::Cdn::Provider::Loader fog provider not defined. Loader loaded partially."
          end
        end
        def initialize
        end
      end


    end
  end
end
