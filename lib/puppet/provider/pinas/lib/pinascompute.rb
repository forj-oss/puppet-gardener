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
# driver class for fog

#  require 'ruby-debug' ; Debugger.start

require 'fog' if Puppet.features.fog?
require 'json' if Puppet.features.json?
require 'erb'
#TODO: This class brings together network and compute, we may need to break these out down the line.
module Puppet
  module Pinas
    class Compute
      attr_accessor :compute
      attr_accessor :network
      # singleton call:
      def self.instance(comm, network = nil)  # use this instead of .new!! to get a singleton
        @@pinas ||= self.new(comm, network)
        @@pinas.network = network if @@pinas.network == nil and network != nil # refresh the network object when provided.
        return @@pinas
      end

      #  initialize
      def initialize(comm, network = nil)
        @compute = comm
        @network = network
      end

      # check if server exist in compute
      def server_exist?(server_name)
        compute = find_match(@compute.servers, server_name)
        Puppet.debug "found server #{compute.name}" if compute != nil
        Puppet.debug "server not found : #{server_name}" if compute == nil
        return (compute != nil)
      end

      # create a server
      # TODO: Implement a fog provider mapping. Ex: flavor_ref(openstack) = flavor_id(hpcloud)
      def server_create(server_name, template)
        # calculate instance id
        Puppet.debug "template keys => " + JSON.pretty_generate(template)

        server_id, server_host = ::Pinas::Common.extract_instance_id_from(server_name)

        # 1. setup the default options
        options = {
                :name => server_name,
                :flavor_ref => get_flavor(template[:flavor_name]), # For Openstack provider
                :image_ref => get_image(template[:image_name]),    # For Openstack provider
                :flavor_id => get_flavor(template[:flavor_name]),  # For HPCloud provider
                :image_id => get_image(template[:image_name]),     # For HPCloud provider
                :key_name => template[:key_name],
                :security_groups => template[:security_groups],
          }
        Puppet.debug "setup default options = >" + JSON.pretty_generate(options)
        # 2. setup the meta data/user data for the server, for boot hooks
        begin
          options[:metadata] = meta_to_hash(ERB.new(template[:meta_data]).result(binding)) if template.has_key?(:meta_data)
        rescue Exception => e
           Puppet.crit "servers.create in running erb for :metadata, Error: #{e}"
           raise Puppet::Error, "Error : #{e}"
        end
        begin
          options[:user_data] = ERB.new(File.read(template[:user_data])).result(binding)   if template.has_key?(:user_data)
        rescue Exception => e
           Puppet.crit "servers.create in running erb for :user_data, Error: #{e}"
           raise Puppet::Error, "Error : #{e}"
        end
        Puppet.debug "added metadata and user_data"
        Puppet.debug "has network_name key ? #{template.has_key?(:network_name)}"
        Puppet.debug "network class => #{network.class}"
        Puppet.debug "template[:network_name] => #{template[:network_name]}"
        Puppet.debug "template[:network_name] => #{template['network_name']}"
        # 3. get the network uuid and name
        if @network != nil and template.has_key?(:network_name) and template[:network_name] != ''
          Puppet.debug "adding network #{template[:network_name]}"
          networks = Array.new
          nics      = Array.new
          nics << get_networkid(template[:network_name])
          # nics << template[:network_name]
          Puppet.debug "working on nics => #{nics}."
          begin
            nics.each do |net|
                   Puppet.debug "working on net => #{net}"
                   network = find_match(@network.networks, net)
                   networks.push('net_id' => network.id) if network
            end
            options[:nics] = networks
          rescue Exception => e
            raise Puppet::Error, "Problem assigning nics, #{e}"
          end
          Puppet.debug "after options, got  = >" + JSON.pretty_generate(options)
        end
        # 4. create new server and wait for it to be ready.
        # TODO: implement retryable and wait for code.  need to confirm we have a timeout in fog.
        # server = @compute.servers.create(options)
        # retryable(on: Timeout::Error, tries: 200) do
        #   begin
        #       server.wait_for(30) { ready? }
        #        rescue RuntimeError, Fog::Errors::TimeoutError => e
        #   end
        # end
        Puppet.debug "attempting to create server #{server_name}"
        new_server = nil
        begin
          new_server = @compute.servers.create(options)
          new_server.wait_for { ready?}
          new_server.wait_for { !addresses.nil? }
        rescue Exception => e
           Puppet.crit "servers.create Error: #{e}"
           raise Puppet::Error, "Error : #{e}"
        end

        Puppet.notice "server created #{server_name} on net #{template[:network_name]} "
        begin
          newserver_ip_assign(new_server)
        rescue  Exception => e
          Puppet.crit "server_ip_assign Error: #{e}"
          raise Puppet::Error, "Error : #{e}"
       end

      end
      # get the public ip of the server
      def server_get_public_ip(server_name)
        public_ip = ''
        if server_exist?(server_name)
          server = find_match(@compute.servers, server_name)
          network_name = server.addresses.keys.reduce
          server.addresses.each do |address|
            if (address.include? network_name and  address.length == 2) #TODO: research why is this 'private' for a public ip?
              if address[1].length >= 2
                Puppet.debug "found floating ip = #{address[1][1].inspect}"
                public_ip = address[1][1].addr
               end
            end
          end
        end
        return public_ip
      end
      # get the private ip of the server
      def server_get_private_ip(server_name)
        private_ip = ''
        if server_exist?(server_name)
          server = find_match(@compute.servers, server_name)
          network_name = server.addresses.keys.reduce
          server.addresses.each do |address|
            if (address.include? network_name and  address.length == 2)
              if address[1].length >= 1
                Puppet.debug "found private ip = #{address[1][0].inspect}"
                private_ip = address[1][0].addr
               end
            end
          end
        end
        return private_ip
      end

      # get the server id by private ip
      #
      # @params string [String] the private ip
      # @return string [String] the server id
      def get_server_id_by_private_ip(private_ip)
        @compute.servers.each do |server|
          network_name = server.addresses.keys.reduce
          server.addresses.each do |address|
            if (address.include? network_name and address.length == 2)
              if address[1].length >= 1
                return server.id if address[1][0].addr == private_ip
              end
            end
          end
        end
        return String.new
      end
      # assign floating IP address to server by server  hash
      # TODO: consider moving to network class.
      # only assign an ip if the server does not have two addresses yet.
      def newserver_ip_assign(server)
        if server != nil
          addresses = server.addresses
          if addresses != nil
            network_name = server.addresses.keys.reduce
          else
            raise Puppet::Error, "Server has no network connections"
          end
          if addresses[network_name].count < 2
          # check if already assigned
            new_ip = nil
            ip = get_free_floating_ip(server)
            if ip != nil
              begin
                new_ip = @compute.associate_address(server.id, ip)
                Puppet.notice "#{server.name} assigned ip => #{ip}"
              rescue Exception => e
                  Puppet.err e
                  raise Puppet::Error, "associate_address Error : #{e}"
              end
            else
              Puppet.warning "unable to assign server an ip : #{server.name}"
              return nil
            end
          end
        else
          Puppet.warning "unable to find server to assign new ip #{server.name}"
          return nil
        end
        return ip
      end
      # assign floating IP address to server by server name
      # TODO: consider moving to network class.
      # only assign an ip if the server does not have two addresses yet.
      def server_ip_assign(server_name)
        server = find_match(@compute.servers, server_name)
        if server != nil
          addresses = server.addresses
          if addresses != nil
            network_name = server.addresses.keys.reduce
          else
            Puppet.warning "falling back to default network"
            network_name = 0 # HACK HACK HACK
          end
          if addresses[network_name].count < 2
          # check if already assigned
            new_ip = nil
            ip = get_free_floating_ip(server)
            if ip != nil
              begin
                new_ip = @compute.associate_address(server.id, ip)
                Puppet.notice "#{server_name} assigned ip => #{ip}"
              rescue Exception => e
                  Puppet.err e
                  raise Puppet::Error, "associate_address Error : #{e}"
              end
            else
              Puppet.warning "unable to assign server an ip : #{server_name}"
              return nil
            end
          end
        else
          Puppet.warning "unable to find server to assign new ip #{server_name}"
          return nil
        end
        return ip
      end
      # get an ip that is already allocated but unassigned to a server
      # if one is not assigned, getting a new floating ip generated, and return that.
      def get_free_floating_ip(server)
        @compute.addresses.each do |address|
          Puppet.debug "found a free address to assign #{address.ip}" if address.instance_id == nil
          return address.ip if address.instance_id == nil
        end
        #if no free address generate new address
        Puppet.debug "no free address available, create a new one."
        ext_net = nil
        begin
          ext_net = get_first_external_network
        rescue Exception => e
            Puppet.err e
            raise Puppet::Error, "get_first_external_network Error : #{e}"
        end
        response = nil
        if ext_net != nil
           Puppet.debug "using #{ext_net.name}"
           ext_net_id = ext_net.id
           #TODO: consider creating options for the hash below so we can
           # provide more flexiblity in external network config.
           hsh = {
                      #:tenant_id           => server.tenant_id
                      #:floating_network_id => ext_net_id   #,
                      #:port_id => @port,
                      #:fixed_ip_address => @fixed_ip,
                      #:floating_ip_address => @floating_ip
                    }
           begin
             Puppet.debug hsh
             response = @network.create_floating_ip(ext_net_id, hsh)
             Puppet.debug "got response = > #{response.status}"
           rescue Exception => e
               Puppet.err e
               raise Puppet::Error, "create_floating_ip Error : #{e}"
           end
        else
           Puppet.warning "unable to get a valid external network"
        end

        Puppet.debug "use new floating ip address: #{response}"
        new_ip = nil
        unless response.nil?
          #  this was failing : new_ip = response.body['floating_ip']['ip']
          new_ip = response.body['floatingip']['floating_ip_address']
          Puppet.debug "allocated a new address => #{new_ip}"
        end
        return new_ip
      end

      def get_first_external_network
        if @network != nil
          @network.networks.each{ |n|
            Puppet.debug "looking for external network #{n.name}"
            if n.router_external == true
              return n
            end
          }
        end
        return nil
      end

      #TODO: move to common
      def meta_to_hash(str)
        key_pairs = str.split(',')
        h_kp = {}
        key_pairs.each do | kp |
          a_kp = kp.split('=')
          key = a_kp[0]
          val = a_kp[1]
          h_kp[key] = val if val != nil
        end
        return h_kp
      end

      # TODO: move to common
      def meta_to_json(str)
        key_pairs = str.split(',')
        h_kp = {}
        key_pairs.each do | kp |
          a_kp = kp.split('=')
          key = a_kp[0]
          val = a_kp[1]
          h_kp[key] = val
        end
        return h_kp.to_json
      end

      # destroy server
      def server_destroy(server_name)
        Puppet.notice "destroying server : #{server_name}\n"
        server = find_match(@compute.servers, server_name)
        if server != nil
          server = @compute.servers.get(server.id)
          Puppet.debug "calling server.destroy for #{server_name}"
          server.destroy
        else
          Puppet.notice "server was not found..."
        end
      end

      # get server_id from name
      # DEPRICATE: Use find_match in common.rb
      def server_id(server_name)
        Puppet.warning "[DEPRICATED]: Use find_match in common.rb"
        @compute.servers.each do |server|
          return server.id if server.name == server_name
        end
        return nil
      end

      # return the flavor_id from the server_template[:flavor_name]
      def get_flavor(flavor_name)
        flavor_res = find_match(@compute.flavors, flavor_name)
        flavor_to_use = (flavor_res != nil) ? flavor_res.id.to_s : nil
        if flavor_to_use.nil?
          Puppet.crit "The flavor is not found on cloud account!, flavor_name => #{flavor_name}"
          raise Puppet::Error, "The flavor is not found on cloud account!, flavor_name => #{flavor_name}"
        else
          Puppet.notice "Flavor '#{flavor_name}' found : '#{flavor_to_use}'"
        end
        return flavor_to_use
      end

      # return the network_id from the server_template[:network_name]
      # network.networks[2].name  but with Fog::Network
      def get_networkid(network_name)
        network_res = find_match(@network.networks, network_name)
        network_to_use = (network_res != nil) ? network_res.id.to_s : nil
        if network_to_use.nil?
          Puppet.crit "The network is not found on cloud account!, network_name => #{network_name}"
          raise Puppet::Error, "The network is not found on cloud account!, network_name => #{network_name}"
        else
          Puppet.notice "Network '#{network_name}' found : '#{network_to_use}'"
        end
        return network_to_use
      end

    # return the image_id from the server_template[:image_name]
      def get_image(image_name)
        image_res = find_match(@compute.images, image_name)
        image_to_use = (image_res != nil) ? image_res.id : nil
        if image_to_use.nil?
          Puppet.crit "The image is not found on cloud account!, image_name => #{image_name}"
          raise Puppet::Error, "The image is not found on cloud account!, image_name => #{image_name}"
        else
          Puppet.notice "Image '#{image_name}' found : '#{image_to_use}'"
        end
        return image_to_use
      end

      # get a compute
      def get_compute(compute_name_id)
        return find_match(@compute.servers, compute_name_id)
      end
    end

    module Facter
      # Facter 'compute_public_ip'
      def self.get_compute_public_ip(prefix)
        compute_public_ip = String.new

        server_id = ::Facter.value('compute_id_lookupbyip')
        if (server_id == nil or server_id == '')
          ::Facter.warn prefix + "unable to continue without compute_id_lookupip facter"
          return :undefined
        end
        ::Facter.debug prefix + "looking up compute public ip with #{server_id}"

        # verify fog libraries can be loaded
        if !Puppet.features.fog?
          ::Facter.warn prefix + "fog not loaded, compute_public_ip empty"
          return :undefined
        end

        # verify pinas common lib is available
        if !Puppet.features.pinas?
          ::Facter.warn prefix + "pinas common lib unavailable."
          return :undefined
        end

        # verify fog_rc file found
        if !Puppet.features.fog_credentials?
          ::Facter.warn prefix + "fog_credentials unavailable, set FOG_RC"
          return :undefined
        end

        # load the compute object
        @loader = ::Pinas::Compute::Provider::Loader
        if @loader.get_provider == nil and isready == true
          ::Facter.warn prefix + "Pinas fog configuration missing."
          return :undefined
        end

        ::Facter.debug prefix + "using provider #{@loader.get_provider}"

        # compute service
        @compute_service = ::Pinas::Compute::Provider::Compute
        pinascompute = @compute_service.instance(@loader.get_compute)
        compute_public_ip = pinascompute.server_get_public_ip(server_id)
        return :undefined if compute_public_ip == ""
        compute_public_ip
      end

      def self.get_compute_id_lookupbyip(prefix)
        ipaddress = ::Facter.value('ipaddress')
        if (ipaddress == nil or ipaddress == '')
          ::Facter.warn prefix + "unable to continue without ipaddress facter"
          return :undefined
        end
        ::Facter.debug prefix + "looking up compute id with #{ipaddress}"

        # verify fog libraries can be loaded
        if  !Puppet.features.fog?
          ::Facter.warn prefix + "fog not loaded, compute_id_lookup empty"
          return :undefined
        end

        # verify pinas common lib is available
        if !Puppet.features.pinas?
          ::Facter.warn prefix + "pinas common lib unavailable."
          return :undefined
        end

        # verify fog_rc file found
        if !Puppet.features.fog_credentials?
          ::Facter.warn prefix + "fog_credentials unavailable, set FOG_RC"
          return :undefined
        end

        # load the compute object
        @loader = ::Pinas::Compute::Provider::Loader
        if @loader.get_provider == nil
          ::Facter.warn prefix + "Pinas fog configuration missing."
          return :undefined
        end

        ::Facter.debug prefix + "using provider #{@loader.get_provider}"

        # compute service
        @compute_service = ::Pinas::Compute::Provider::Compute
        pinascompute = @compute_service.instance(@loader.get_compute)
        compute_id = pinascompute.get_server_id_by_private_ip(ipaddress)
        compute_id = :undefined if compute_id == ""
        compute_id
      end
    end
  end
end
