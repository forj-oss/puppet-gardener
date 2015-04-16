# Class: gardener::params
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
# gardener's goal is to be executed on a puppet master to provision a
# working server into a cloud account, and have puppet fully setup and
# configured.  This class holds parameters that need to be
# accessed by other classes.

class gardener::params (
  # can also be 'Ubuntu Precise 12.04 LTS Server 64-bit 20121026 (b)'
  $image_name         = 'ubuntu-12.04-server-cloudimg-amd64',
  # can also be a number like 100
  $flavor_name        = 'm1.medium',
  $key_name           = 'nova',
  $security_groups    = ['default'],
  # by default gardener always installs puppet and default configuration
  # see /templates
  $template_userdata  = '/tmp/mime.txt',
  $template_metadata  = nil,
  $network_name       = '',
) {

    # Following template data are REQUIRED if using Openstack/FOG
    # Using Lorj, /opt/config/lorj/accounts/*.yaml contains
    # all of these data.
    # But note that those template setting replace data coming from
    # Lorj account file.
    $template = {
                  image_name      => $image_name,
                  flavor_name     => $flavor_name,
                  key_name        => $key_name,
                  security_groups => $security_groups,
                  user_data       => $template_userdata,
                  meta_data       => $template_metadata,
                  network_name    => $network_name,
            }
}
