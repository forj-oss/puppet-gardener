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

# Facter which determine the Lorj_cloud account file name.

def checkdebug
  begin
    if ENV['FACTER_DEBUG'] == 'true'
      Facter.debugging(true)
    end
  rescue
  end
end

# The facter should return
# - :compute   : If the server should be used with the configured /opt/config/fog/cloud.fog file
# - :lorj      : If the server should be used with /opt/config/lorj/account/cloud.yaml file
# - :undefined : If none of those files are configured.
#
# If both files are found, :lorj will be prefered, except if /opt/config/lorj/config.yaml
# contains :lorj set to false in section :default.
#
# In Pinas type declaration, we must use this facter.

require 'lorj' if Puppet.features.lorj_cloud?

Facter.add("lorj_config") do
  setcode do
    prefix = "Facter lorj_config: "

    name = :undefined unless Puppet.features.lorj_cloud?
    if ENV["LORJ_CONF"].nil?
      ENV["LORJ_CONF"] = 'cloud.yaml'
      Puppet.debug prefix + "Defaulting LORJ_CONF to '#{name}'"
    else
      name = ENV["LORJ_CONF"]
    end

    unless name == :undefined
      name = ENV["LORJ_CONF"]
      path = File.join(::PrcLib.data_path, 'accounts', name)
      name = :undefined unless File.exist?(path)
      Puppet.debug prefix + "lorj config is '#{::PrcLib.data_path}/#{name}'"
    else
      Puppet.warning prefix + "Missing cred file: '#{name}'. You can set this with export LORJ_CONF."
    end

    name
  end
end
