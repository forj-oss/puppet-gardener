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

# load relative libraries
__LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)

require 'fog'      if Puppet.features.fog?
require "puppet/provider/pinas/loader" if Puppet.features.pinas?

module Puppet::Parser::Functions
  newfunction(:compute_id_lookup, :type => :rvalue, :doc => <<-EOS
This function will lookup the compute id for a resouce name.
The lookup can be a string id, compute resource name, or regular expresssion.
If using a regular expression, we will only return the first match always.

To configure the fog provider a the following file must be present:
  /opt/config/fog/cloud.fog
  The path to the file can be controlled with environment argument FOG_RC.
  ie; export FOG_RC=/root/.fog/cloud.fog

  Provider definitions depend on the cloud version and provider you are 
  currently using.
  
  The default provider is used for compute resource lookups.

*Arguments:*
  compute_name     : This can be an id, or regular expression like 
                      /maestro.*/

*Examples:*
 
  compute_id_lookup( /maestro.*/ )

returns : XXXXXXX-XXXX-XXXX-XXXXXX

When a compute resource is not found, the return value is ''

    EOS
   ) do |args|
       Puppet.debug "in compute_id_lookup.."
       unless  Puppet.features.fog?
         Puppet.warning "unable to continue, fog libraries are not ready, try running:
                       puppet agent --tags 'gardener::requirements'
                       or 
                       puppet apply --modulepath=\$PUPPET_MODULES -e 'include gardener::requirements'
                       returning false and skipping."
         return nil
       end

       unless Puppet.features.pinas?
         Puppet.warning "Pinas common libraries unavailable, skip for this run."
         return nil
       end

       # check for FOG_RC
       unless Puppet.features.fog_credentials?
         Puppet.warning "fog_credentials unavailable, skip for this run."
         return nil
       end

       @loader = ::Pinas::Compute::Provider::Loader
       unless @loader.get_provider != nil
         Puppet.warning "Pinas fog configuration missing."
         return nil
       end

       if (args.size != 1) then
          raise(Puppet::ParseError, "compute_id_lookup: Wrong number of arguments "+
            "given #{args.size} for 1")
       end
       
       # determine if this is a regex string or not, if so convert @compute_name
       @compute_name = args[0]
       if @compute_name.sub(/(^\/)(.*)(\/$)/,'\1\3') == '//'
         @compute_name = Regexp.new(@compute_name.sub(/(^\/)(.*)(\/$)/,'\2'))
         Puppet.debug "performing regex search #{@compute_name.inspect}, class => #{@compute_name.class}"
       end
       
       @compute_service = ::Pinas::Compute::Provider::Compute
       
       begin
        Puppet.debug("checking if compute node exist ( #{@compute_name} ) exists.")
        pinascompute = @compute_service.instance(@loader.get_compute)
        Puppet.debug  "got compute object."
       rescue Exception => e
         Puppet.err "unable to get compute service for #{@compute_name}"
         Puppet.err "#{e}"
         raise "unable to get compute service for #{@compute_name}"
       end
       # determin the compute id
       compute_id = ''
       begin
         compute = pinascompute.get_compute(@compute_name)
         if compute != nil
           compute_id = compute.id
         end    
       rescue Exception => e
         Puppet.warning "Problem getting compute, #{e} "
       end
       return compute_id
    end
end