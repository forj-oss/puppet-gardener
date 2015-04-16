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

if Puppet.features.lorj_cloud?
  require 'lorj'
  require "puppet/provider/pinas/lib/lorj"
end

# To get debug msg, use --debug in puppet apply call.
#
# You can also uncomment the next line and add a 'debugger' in the ruby code
# where you want to debug. You may need to install gem1.8 install ruby-debug.
#  require 'ruby-debug' ; Debugger.start

# Return true if lorj config /opt/config/lorj/account/cloud.yaml
# is installed.

Puppet.features.add(:lorj_config) do
  begin
    prefix = "Feature lorj_config: "
    Puppet.debug prefix + "Starting execution."

    isok =  Puppet.features.lorj_cloud?

    if isok
      ::Puppet::LorjCloud.lorj_initialize

      config_file = ''
      if ENV["LORJ_CONF"].nil?
        ENV["LORJ_CONF"] = 'cloud.yaml'
        config_file = ENV["LORJ_CONF"]
      else
        config_file = ENV["LORJ_CONF"]
      end
    end

    isok = (config_file != '')
    if isok
      path = File.join(::PrcLib.data_path, 'accounts', config_file)
      isok = File.exist?(path)
    end

    if isok
      Puppet.debug prefix + "lorj config is '#{::PrcLib.data_path}/#{config_file}'"
      Puppet.debug prefix + "Enabled."
    else
      Puppet.warning prefix + "Missing cred file: '#{config_file}'. You can set this to a different file name (no path) with export LORJ_CONF."
      Puppet.debug prefix + "Disabled."
    end

    Puppet.debug prefix + "Ending execution."
    isok
  rescue => err
    Puppet.warning prefix + "Failure: #{err}"
    false
  end
end
