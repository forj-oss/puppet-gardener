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

# To get debug msg, use --debug in puppet apply call.
#
# You can also uncomment the next line and add a 'debugger' in the ruby code
# where you want to debug. You may need to install gem1.8 install ruby-debug.
#  require 'ruby-debug' ; Debugger.start


# Feature returning true if lorj is enabled by configuration
# /opt/config/lorj/config.yaml

if Puppet.features.lorj_cloud?
  require 'lorj'
  require "puppet/provider/pinas/lib/lorj"
end

Puppet.features.add(:lorj_enabled) do
  begin
    prefix = "Feature lorj_enabled: "
    #  debugger
    Puppet.debug prefix + "Starting execution."

    isok = Puppet.features.lorj_cloud?

    config = nil
    if isok
      ::Puppet::LorjCloud.lorj_initialize
      config = ::Lorj::Config.new
    end

    if isok && config && config[:lorj] == false
      Puppet.notice prefix + "Disabled. Lorj has been forcelly disabled. To re-enable it, update /opt/config/lorj/config.yaml, and set :lorj: true under :default section"
      isok = false
    end

    if isok
      #  Puppet.debug prefix + "Enabled. To forcelly disable Lorj, update /opt/config/lorj/config.yaml and add :lorj: false under :default section"
      Puppet.notice prefix + "Enabled. To forcelly disable Lorj, update /opt/config/lorj/config.yaml and add :lorj: false under :default section"
    else
      Puppet.debug prefix + "Disabled."
    end

    Puppet.debug prefix + "Ending execution."
    isok
  rescue => err
    Puppet.warning prefix + "Failure: #{err}"
    false
  end
end
