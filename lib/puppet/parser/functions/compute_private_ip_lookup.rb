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

if Puppet.features.lorj_ready?
  require 'lorj_cloud'
  require "puppet/provider/pinas/lib/lorj"
end

if Puppet.features.fog_ready?
  require 'fog'                              if Puppet.features.fog?
  require "puppet/provider/pinas/lib/loader" if Puppet.features.pinas?
end

module Puppet::Parser::Functions
  newfunction(:compute_private_ip_lookup, :type => :rvalue, :doc => <<-EOS
This function will lookup the private ip address for a compute resource.

To configure the fog provider a the following file must be present:
  /opt/config/fog/cloud.fog
  The path to the file can be controlled with environment argument FOG_RC.
  ie; export FOG_RC=/root/.fog/cloud.fog

  Provider definitions depend on the cloud version and provider you are
  currently using.

  The default provider is used for compute resource lookups.

*Arguments:*
  compute_name     : the name of the compute resource or id for the compute
                      resource.

*Examples:*

  compute_private_ip_lookup( 'pinasnode1' )

returns : '10.X.X.X'
          undef or '' when not found or exception

When a compute resource is not found, the return value is ''

    EOS
   ) do |args|
       prefix = 'ParserFunction compute_private_ip_lookup: '
       Puppet.debug prefix + "start up."

       ::Puppet::Pinas::Parser.compute_private_ip_lookup(prefix, args) if Puppet.features.fog_ready?
       ::Puppet::Lorj::Parser.compute_private_ip_lookup(prefix, args) if Puppet.features.lorj_ready?
    end
end
