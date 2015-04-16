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
#  require 'ruby-debug' ; Debugger.start

# Return true if we must use FOG provider

Puppet.features.add(:fog_ready) do
  begin
    prefix = "Feature fog_ready: "
    #  debugger
    Puppet.debug prefix + "Starting execution."
    isok = Puppet.features.fog_credentials? && !Puppet.features.lorj_ready?

    if isok
      Puppet.notice prefix + "Fog is selected to be used."
    end

    Puppet.debug prefix + "Ending execution."
    isok
  rescue => err
    Puppet.warning prefix + "Failure: #{err}"
    false
  end
end
