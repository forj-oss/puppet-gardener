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

# FOG Parser functions

module Puppet
  module Pinas
    module Parser
      def self.compute_id_lookup(prefix, args)
        unless  ::Puppet.features.fog?
          ::Puppet.warning prefix + "unable to continue, fog libraries are not ready, try running:
                       puppet agent --tags 'gardener::requirements'
                       or
                       puppet apply --modulepath=\$PUPPET_MODULES -e 'include gardener::requirements'
                       returning false and skipping."
          return nil
        end

        unless ::Puppet.features.pinas?
          ::Puppet.warning prefix + "Pinas common libraries unavailable, skip for this run."
          return nil
        end

        # check for FOG_RC
        unless ::Puppet.features.fog_credentials?
          ::Puppet.warning prefix + "fog_credentials unavailable, skip for this run."
          return nil
        end

        @loader = ::Pinas::Compute::Provider::Loader
        unless @loader.get_provider != nil
          ::Puppet.warning prefix + "Pinas fog configuration missing."
          return nil
        end

        if (args.size != 1) then
           raise(::Puppet::ParseError, prefix + "compute_id_lookup: Wrong number of arguments "+
             "given #{args.size} for 1")
        end

        # determine if this is a regex string or not, if so convert @compute_name
        @compute_name = args[0]
        if @compute_name.sub(/(^\/)(.*)(\/$)/,'\1\3') == '//'
          @compute_name = Regexp.new(@compute_name.sub(/(^\/)(.*)(\/$)/,'\2'))
          ::Puppet.debug prefix + "performing regex search #{@compute_name.inspect}, class => #{@compute_name.class}"
        end

        @compute_service = ::Pinas::Compute::Provider::Compute

        begin
         ::Puppet.debug(prefix + "checking if compute node exist ( #{@compute_name} ) exists.")
         pinascompute = @compute_service.instance(@loader.get_compute)
         ::Puppet.debug  prefix + "got compute object."
        rescue Exception => e
          ::Puppet.err prefix + "unable to get compute service for #{@compute_name}"
          ::Puppet.err prefix + "#{e}"
          raise prefix + "unable to get compute service for #{@compute_name}, error #{e}"
        end
        # determin the compute id
        compute_id = ''
        begin
          compute = pinascompute.get_compute(@compute_name)
          if compute != nil
            compute_id = compute.id
          end
        rescue Exception => e
          ::Puppet.warning prefix + "Problem getting compute, #{e} "
        end
        return compute_id
      end

      def self.compute_private_ip_lookup(prefix, args)
        unless :: Puppet.features.fog?
          ::Puppet.warning prefix + "unable to continue, fog libraries are not ready, try running:
                       puppet agent --tags 'gardener::requirements'
                       or
                       puppet apply --modulepath=\$PUPPET_MODULES -e 'include gardener::requirements'
                       returning nil and skipping."
          return :undefined
        end

        unless ::Puppet.features.pinas?
          ::Puppet.warning prefix + "Pinas common libraries unavailable, skip for this run."
          return :undefined
        end

        # check for FOG_RC
        unless ::Puppet.features.fog_credentials?
          ::Puppet.warning prefix + "fog_credentials unavailable, skip for this run."
          return :undefined
        end

        @loader = ::Pinas::Compute::Provider::Loader
        unless @loader.get_provider != nil
          ::Puppet.warning prefix + "Pinas fog configuration missing."
          return :undefined
        end

        if (args.size != 1) then
           raise(::Puppet::ParseError, prefix + "compute_private_ip_lookup: Wrong number of arguments "+
             "given #{args.size} for 1")
        end

        @compute_name = args[0]

        @compute_service = ::Pinas::Compute::Provider::Compute

        begin
          ::Puppet.debug(prefix + "checking if compute node exist ( #{@compute_name} ) exists.")
          pinascompute = @compute_service.instance(@loader.get_compute)
          ::Puppet.debug  prefix + "got compute object."
        rescue Exception => e
          ::Puppet.err prefix + "unable to get compute service for #{@compute_name}"
          raise prefix + "unable to get compute service for #{@compute_name}, error #{e}"
        end
        return pinascompute.server_get_private_ip(@compute_name)
      end

      def self.compute_public_ip_lookup(prefix, args)
        unless  ::Puppet.features.fog?
          ::Puppet.warning prefix + "unable to continue, fog libraries are not ready, try running:
                        puppet agent --tags 'gardener::requirements'
                        or
                        puppet apply --modulepath=\$PUPPET_MODULES -e 'include gardener::requirements'
                        returning nil and skipping."
          return :undefined
        end

        unless ::Puppet.features.pinas?
          ::Puppet.warning prefix + "Pinas common libraries unavailable, skip for this run."
          return :undefined
        end

        # check for FOG_RC
        unless ::Puppet.features.fog_credentials?
          ::Puppet.warning prefix + "fog_credentials unavailable, skip for this run."
          return :undefined
        end

        @loader = ::Pinas::Compute::Provider::Loader
        unless @loader.get_provider != nil
          ::Puppet.warning prefix + "Pinas fog configuration missing."
          return :undefined
        end

        if (args.size != 1) then
           raise(::Puppet::ParseError, prefix + "compute_public_ip_lookup: Wrong number of arguments "+
             "given #{args.size} for 1")
        end

        @compute_name = args[0]

        @compute_service = ::Pinas::Compute::Provider::Compute

        begin
          ::Puppet.debug(prefix + "checking if compute node exist ( #{@compute_name} ) exists.")
          pinascompute = @compute_service.instance(@loader.get_compute)
          ::Puppet.debug  prefix + "got compute object."
        rescue Exception => e
          ::Puppet.err prefix + "unable to get compute service for #{@compute_name}"
          raise prefix + "unable to get compute service for #{@compute_name}, error #{e}"
        end
        return pinascompute.server_get_public_ip(@compute_name)
      end
    end
  end
end
