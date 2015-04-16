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
# a new type to work with garnder server nodes using fog api
# current goal is to provision a server with hp cloud
# we call this pinas because garnder's role is to create more nodes like
# the agave pina

# Provider code behavior is explained by example here:
# https://docs.puppetlabs.com/guides/complete_resource_example.html
#
# Check also about https://docs.puppetlabs.com/guides/custom_types.html
#

# Currently this type support 2 providers
# - Openstack via FOG (:compute)
# - lorj_cloud (:lorj)
#
# If Lorj account file exist, it will disable :compute provider and activate :lorj
# If Only FOG file exist, only :compute provider will be activated.
# If none of them exist, no provider are activated.
# This logic has been implemented for a smooth transition from Openstack/fog to Lorj_cloud
#
# The choice is made by a Facter 'cloud_provider' which will select :compute or :lorj
# This facter must be passed as :provider argument to the pinas Custom type.
#
# For Maestro built on a cloud, metadata will determine which option will be used.
# Note that DNS management is still using HPCloud cli library, until lorj_cloud process
# implement it.
#
# ChL - (chrisssss#forj)

Puppet::Type.newtype(:pinas) do
  @doc = %q{Creates a new server node for gardener
        We've been using this to provide a cloud provider independent deployment
        mechanisum under puppet, so we can manage and create servers under puppet.

        Example:
            include gardener::requirements

            $template = {
                  image_name      => '',
                  flavor_name     => '',
                  key_name        => 'nova',
                  security_groups => ["default"],
                  network_name    => '',  # add this parameter for 13.5 hp/openstack support
            }
            pinas {'openstack':
              ensure          => present,
              instance_id     => '42',
              domain          => $domain,
              nodes           => ['node1','node2','node3'],
              credentials     => $creds,
              do_parallel     => true,
              server_template => $template,
              provider        => hp,
            }
      }

  ensurable

# currently not really used, placeholder for what we do that is blueprint specific
# ie; naming schema, etc.
  newparam(:name) do
    desc "blueprint name."
  end

#
# the instance_id is pre-appended to the node name
  newparam(:instance_id) do
    desc "an instance_id that is appended to the front of the hostname."
  end

# The provider name to use from the fog API.
#  newparam(:provider) do
#    desc "blueprint name."
#    defaultto :fog
#  end
#
# setup domain
  newparam(:domain) do
    desc "domain name of the nodes."
  end

# set delay
  newparam(:delay) do
    desc "seconds to wait before create."
    validate do |value|
      unless value =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
         raise ArgumentError, "%s not a number, fix delay argument." % value
      end
    end
  end

# this is an array of nodes to create
  newparam(:nodes, :array_matching => :all) do
    desc "a list of nodes to create."
  end

# this is the server template to use for creating servers
  newparam(:server_template) do
    desc "the server template to use for server creation."
    template = {}
    munge do |value|
      value.each do |key, item|
        Puppet.debug "validating template #{key} and #{item}"
        template[key.to_sym]=item
      end
      template
    end
  end

  newparam(:do_parallel) do
    desc "Execute parallel actions on all nodes."
    newvalues(:true, :false)
  end

  # This parameter has been added to help puppet manage
  # the Lorj Cloud configuration file.
  # By default we set it to the facter :lorj_config

  # Currently Gardener do not support multiple conf.
  newparam(:conf) do
    desc "Cloud Configuration file"
  end
end
