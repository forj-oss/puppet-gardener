# == gardener::puppetmaster
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

# Facter which determine which cloud_provider to use in Pinas.

def checkdebug
  begin
    if ENV['FACTER_DEBUG'] == 'true'
      Facter.debugging(true)
    end
  rescue
  end
end

#  require 'ruby-debug' ; Debugger.start

# The facter should return
# - :compute : If the server is configured with /opt/config/fog/cloud.fog file
# - :lorj    : If the server is configured with /opt/config/lorj/account/cloud.yaml file
# - :none    : If none of those files are configured.
#
# In Pinas type declaration, we can use hiera data to change the default behavior
# provided by this facter.
Facter.add("cloud_provider") do
  setcode do
    #  debugger
    cloud_provider = :undefined
    cloud_provider = :compute if Puppet.features.fog_ready?
    cloud_provider = :lorj    if Puppet.features.lorj_ready?
    cloud_provider
  end
end
