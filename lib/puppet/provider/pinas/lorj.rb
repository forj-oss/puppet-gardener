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
# manage a server node using lorj_cloud
# Cloud providers is maintained in /opt/config/lorj/account/cloud.yaml (detected by feature :lorj_config)
#
# The provider :lorj implements create/destroy and exist? (attached to property ensure/ensurable)
# See https://docs.puppetlabs.com/guides/complete_resource_example.html for puppet provider code explanation.

# https://docs.hpcloud.com/bindings/fog/compute

if Puppet.features.lorj_cloud?
  require 'lorj_cloud'
  require 'puppet/provider/pinas/lib/lorj.rb'   # Pinas::Lorj + Puppet::LorjCloud
  require 'puppet/provider/pinas/lib/common.rb' # Pinas::Common
end

Puppet::Type.type(:pinas).provide :lorj do
  desc "Creates cloud nodes for Gardener with lorj_cloud."
  defaultfor :cloud_provider => :lorj
  confine :feature => :lorj_cloud
  confine :feature => :lorj_config
  include ::Pinas::Lorj::Actions
end
