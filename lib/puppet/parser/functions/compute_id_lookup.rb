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

# To learn about puppet new functions, read:
# https://docs.puppetlabs.com/guides/custom_functions.html
#
# To test this function, simply call it like that:
# $ pp -e 'notice(compute_id_lookup("myserver"))'

# load relative libraries
__LIB_DIR__ = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift __LIB_DIR__ unless $LOAD_PATH.include?(__LIB_DIR__)

if Puppet.features.lorj_config?
  require 'lorj_cloud'
  require "puppet/provider/pinas/lib/lorj"
end

require 'fog' if Puppet.features.fog?
if Puppet.features.pinas?
  require "puppet/provider/pinas/lib/loader"
  require 'puppet/provider/pinas/lib/parser'
end

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
       prefix = 'ParserFunction compute_id_lookup: '
       Puppet.debug prefix + "start up"

       ::Puppet::Pinas::Parser.compute_id_lookup(prefix, args) if Puppet.features.fog_ready?
       ::Puppet::Lorj::Parser.compute_id_lookup(prefix, args) if Puppet.features.lorj_ready?
    end
end
