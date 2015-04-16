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
# we want to identify the correct library to load outside
# a provider, so we use the fog provider to load the correct library

#  require 'ruby-debug' ; Debugger.start

require 'lorj_cloud' if Puppet.features.lorj_cloud?

# Module Pinas
module Pinas
  # Module Lorj for Pinas Lorj cloud implementation
  module Lorj
    module Common
      # Convert a String with key=value pairs as a Hash
      #
      # * *args*:
      #   - +str+ : String. list of key/value pairs
      #
      # * *returns* :
      #   - +Hash+ : Hash instance returned
      #
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

      # Set the server name with or without the instance name
      #
      # * *args*:
      #   - +server+ : String. Server name
      #
      # * *returns* :
      #   - +String+ : Instance server name
      def get_servername(server)
        if @resource[:instance_id] == ''
          return server
        else
          return "#{server}.#{@resource[:instance_id]}"
        end
      end

      # Load Lorj resources
      #
      # * *Args* :
      #   - +prefix+ : String. String prefixing notice/errors messages.
      #   - +conf+   : Configuration file name located in ::PrcLib.data_path/accounts
      #
      # * *returns*:
      #   - ::Lorj::Core : Lorj resource loaded.
      #   OR
      #   - nil : in case of errors.
      #
      def lorj_instance(prefix, conf)
        if ::Puppet::LorjCloud.instance?
          core = ::Puppet::LorjCloud.get_instance
        else
          isok, config = ::Puppet::LorjCloud.load_config(conf)
          unless isok
            Puppet.warning(prefix + "Unable to load '#{@resource[:conf]}' from"\
                           " '#{File.join(::PrcLib.data_path, 'accounts')}'")
            return nil
          end
          core = ::Puppet::LorjCloud.instance(config, config['account#provider'])
        end

        raise Puppet::Error, prefix + "Error : Unable to get a Lorj_cloud"\
                             " instance." unless ::Puppet::LorjCloud.instance?
        core
      end

      # check the hash key value.
      #
      # * *args* :
      #   - hash : Hash
      #   - key  : key to check
      #
      # * *return* :
      #   - true : if
      #     - value is a String
      #     - value is not 'nil'
      #     - value is not empty
      #   - false otherwise
      def hash_key_valid?(hash, key)
        key && hash.key?(key) && hash[key].is_a?(String) && hash[key].size > 0
      end

      # TODO: Lorj_cloud to support image_id or image_name
      # TODO: Lorj_cloud to support Array of SG.

      # Initialize create parameters, thanks to :server_template Hash
      # It maps to what Lorj_cloud will require.
      #
      # * *Args* :
      #   - prefix          : String. string context of this call.
      #   - server_template : Hash. Should contains:
      #     - :image_name      : Image name
      #       Warning! Must be only an Image Name. Not an ID.
      #     - :flavor_name     : Flavor name
      #     - :key_name        : keypair name
      #     - :security_groups : Security group name used
      #       Converted to get security_groups[0]
      #     - :user_data       : Instructions to be executed by cloud-init
      #     - :meta_data       : key/value pairs passed to the server built step.
      #     - :network_name    : network name
      def build_create_parameters(prefix, server_template, config)
        ref = {
          :image_name => [:image_name, 'maestro#image_name'],
          :flavor_name => [:flavor_name, 'maestro#flavor_name'],
          :keypair_name => [:key_name],
          :network_name => [:network_name, 'maestro#network_name'],
          :ports => [nil, 'maestro#ports']
        }

        res = {}
        ref.each do |k, v|
          res[k] = server_template[v[0]] if hash_key_valid?(server_template, v[0])
          res[k] = config[v[1]] if !res.key?(k) && v[1] && config.exist?(v[1])
        end

        if server_template.key?(:security_groups) && server_template[:security_groups].is_a?(Array)
          res[:security_group] = server_template[:security_groups][0]
        end
        res
      end

      # Adapt template data to the context provided 'b' (See Ruby documentation on Binding)
      # setup the meta data/user data for the server, for boot hooks
      def par_template(prefix, server_template, res, b)
        begin
          res[:meta_data] = meta_to_hash(ERB.new(server_template[:meta_data]).result(b)) if server_template.has_key?(:meta_data)
        rescue Exception => e
          Puppet.crit prefix + "servers.create in running erb for :metadata, Error: #{e}"
          raise Puppet::Error, prefix + "Error : #{e}"
        end

        begin
          res[:user_data] = ERB.new(File.read(server_template[:user_data])).result(b)    if server_template.has_key?(:user_data)
        rescue Exception => e
          Puppet.crit prefix + "servers.create in running erb for :user_data, Error: #{e}"
          raise Puppet::Error, prefix + "Error : #{e}"
        end
      end
    end

    # Actions added to lib/puppet/provider/lorj.rb
    # Read it to get more information
    module Actions
      include ::Pinas::Lorj::Common
      # Pinas :compute ensure => present will call this function to create a new
      # servers
      # @resource contains the list of type data declared in lib/puppet/type/pinas.rb
      #
      # NOTE: Lorj_cloud currently do not support multiple sg. Choose the first one.
      #
      # Following input are userd:
      # - @resource[:server_template] : Hash defined by manifests/params.pp
      # - @resource[:do_parallel]     : Not used. We should be able to implement it later.
      # - @resource[:delay]           : Delay between each node creation task.
      # - @resource[:nodes]           : Array of nodes name to create.
      # - @resource[:instance_id]     : Forge instance name.
      def create
        prefix = 'type Pinas(:lorj)-create:'

        core = lorj_instance(prefix, @resource[:conf])
        return false if core.nil?
        pars = build_create_parameters(prefix, @resource[:server_template], core.config)

        @resource[:nodes].each do |server|
          begin
            server_name = get_servername(server)

            # Prepare binding context (require: server_id, server_name and server_host)
            server_id = ''
            server_host = ''
            server_id, server_host = ::Pinas::Common.extract_instance_id_from(server_name) if Puppet.features.pinas?

            par_template(prefix, @resource[:server_template], pars, binding)

            core.create(:server, pars.merge(:server_name => server_name))

            core.create(:public_ip)
          rescue Exception::Error => e
            raise Puppet::Error, prefix + "Problem with server create: #{e}"
          end
        end
        Puppet.debug prefix + "done with create"
      end

      # destroy an existing server
      # Following input are used:
      # - @resource[:server_template] : Hash defined by manifests/params.pp
      # - @resource[:do_parallel]     : Not used. We should be able to implement it later.
      # - @resource[:delay]           : Delay between each node creation task.
      # - @resource[:nodes]           : Array of nodes name to create.
      # - @resource[:instance_id]     : Forge instance name.
      def destroy
        prefix = 'type Pinas(:lorj)-destroy:'

        core = lorj_instance(prefix, @resource[:conf])
        return false if core.nil?

        @resource[:nodes].each do |server|
          begin
            server_name = get_servername(server)
            server_found = core.query(:server, :name => server_name)

            if server_found.length > 0
              core.register(server_found[0])
              core.delete(:server)
            end
          rescue Exception::Error => e
            raise Puppet::Error, prefix + "Problem with server destroy: #{e}"
          end
        end
        Puppet.debug prefix + "done with destroy"
      end

      # check if all servers exist
      # Following input are used:
      # - @resource[:server_template] : Hash defined by manifests/params.pp
      # - @resource[:do_parallel]     : Not used. We should be able to implement it later.
      # - @resource[:delay]           : Delay between each node creation task.
      # - @resource[:nodes]           : Array of nodes name to create.
      # - @resource[:instance_id]     : Forge instance name.
      def exists?
        prefix = 'type Pinas(:lorj)-exist?:'
        core = lorj_instance(prefix, @resource[:conf])
        return false if core.nil?

        Puppet.notice prefix + "checking if nodes #{@resource[:nodes]} exist."

        @resource[:nodes].each do |server|
          begin
            server_name = get_servername(server)
            server_found = core.query(:server, {:name => server_name}, :search_for => server_name)

            return false if server_found.length == 0
          rescue Exception::Error => e
            raise Puppet::Error, prefix + "Problem with server create: #{e}"
          end
        end

        Puppet.notice prefix + "all nodes found, for instance ID '#{@resource[:instance_id]}'"
        true
      end
    end
  end
end

module Puppet
  # Implementation of Lorj cloud in gardener
  module LorjCloud
    @@process ||= nil
    @@initialized ||= false

    module_function

    def initialize
      @lorj_initialized = false
    end

    def lorj_initialize
      return if @lorj_initialized
      PrcLib.app_name = "lorj"
      PrcLib.data_path = "/opt/config/#{PrcLib.app_name}"
      PrcLib.pdata_path = "/opt/config/#{PrcLib.app_name}"
      PrcLib.level = Logger::INFO
      PrcLib.level = Logger::DEBUG if ENV.include?('LORJ_DEBUG')
      PrcLib.info('To add more Lorj info, you can export LORJ_DEBUG=[0-5], before calling puppet.')
      PrcLib.core_level = ENV['LORJ_DEBUG'].to_i if ENV.include?('LORJ_DEBUG') && ENV['LORJ_DEBUG'].match(/[0-9]/)
      @@lorj_initialized = true
    end

    def instance(config, provider)
      lorj_initialize unless @@lorj_initialized

      if Puppet.features.lorj_cloud?
        processes = [{ :process_module => 'cloud',
                       :controller_name => provider }]
        @@process ||= ::Lorj::Core.new(config, processes)
      end
      @@process
    end

    def get_instance
      @@process if instance?
    end

    def instance?
      !(@@process.nil?)
    end

    def load_config(conf)
      unless @@process.nil?
        config = @@process.config
        return [true, config] if conf == config.account_name # Already loaded.
      else
        config = ::Lorj::Account.new
      end

      [config.ac_load(conf), config]
    end
  end

  # Implement Lorj Facter code
  module Lorj
    # Implement Facter code
    module Facter
      def self.get_compute_public_ip(prefix)
        ipaddress = ::Facter.value('ipaddress')
        if (ipaddress == nil or ipaddress == '')
          ::Facter.warn prefix + "unable to continue without ipaddress facter"
          return :undefined
        end
        ::Facter.debug prefix + "looking up compute id with #{ipaddress}"

        # verify fog libraries can be loaded
        if !Puppet.features.lorj_cloud?
          ::Facter.warn prefix + "fog not loaded, compute_public_ip empty"
          return :undefined
        end

        # verify lorj_cloud libraries can be loaded
        if !Puppet.features.lorj_cloud?
          ::Facter.warn prefix + "lorj_cloud not loaded, compute_id_lookup empty"
          return :undefined
        end

        # verify lorj_config file found
        if !Puppet.features.lorj_config?
          ::Facter.warn prefix + "lorj config unavailable, set LORJ_CONF."
          return :undefined
        end

        if ! ::Puppet::LorjCloud.instance?
          # load the Lorj config object and the lorj cloud process
          isready, @config = ::Puppet::LorjCloud.load_config(ENV["LORJ_CONF"])
          unless isready
            ::Facter.warn prefix + "Lorj config load error. Unable to load '#{ENV["LORJ_CONF"]}'"
          end
          ::Facter.debug prefix + "using provider '#{@config['account#provider']}'"

          # Lorj_cloud object loaded.
          @core = ::Puppet::LorjCloud.instance(@config, @config['account#provider'])
        else
          @core = ::Puppet::LorjCloud.get_instance
          @config = @core.config
        end

        servers = @core.query(:server,
                              {:private_ip_addresses => [//, ipaddress]},
                              :search_for => "server with IP #{ipaddress}")

        if servers.length == 0
          ::Facter.warn prefix + "No server was found with private IP '#{ipaddress}'"
          return :undefined
        end
        compute_public_ip = servers[0, :public_ip_address, //].flatten[0]
        @core.register(servers[0])

        return compute_public_ip unless compute_public_ip.nil?
        public_ip = @core.query(:public_ip, { :server_id => servers[0, :id] },
                                :search_for => "public IP for server "\
                                               "#{servers[0, :name]} "\
                                               "(#{servers[0, :id]})")
        return public_ip[:public_ip] unless server.empty?

        ::Facter.warn prefix + "No Public IP found for server ID '#{server_id}'"
        :undefined
      end

      def self.get_compute_id_lookupbyip(prefix)
        ipaddress = ::Facter.value('ipaddress')
        if (ipaddress == nil or ipaddress == '')
          ::Facter.warn prefix + "unable to continue without ipaddress facter"
          return :undefined
        end
        ::Facter.debug prefix + "looking up compute id with #{ipaddress}"

        # verify lorj_cloud libraries can be loaded
        if  !Puppet.features.lorj_cloud?
          ::Facter.warn prefix + "lorj_cloud not loaded, compute_id_lookup empty"
          return :undefined
        end

        # verify lorj_config file found
        if !Puppet.features.lorj_config?
         :: Facter.warn prefix + "lorj config unavailable, set LORJ_CONF."
          return :undefined
        end

        ::Facter.debug prefix + "loading #{ENV["LORJ_CONF"]}"

        if ! ::Puppet::LorjCloud.instance?
          # load the Lorj config object and the lorj cloud process
          ::Facter.debug prefix + "loading #{ENV["LORJ_CONF"]}"
          isready, @config = ::Puppet::LorjCloud.load_config(ENV["LORJ_CONF"])
          unless isready
            ::Facter.warn prefix + "Lorj config load error. Unable to load '#{ENV["LORJ_CONF"]}'"
            return :undefined
          end
          ::Facter.debug prefix + "using provider '#{@config['account#provider']}'"

          # Lorj_cloud object loaded.
          @core = ::Puppet::LorjCloud.instance(@config, @config['account#provider'])
        else
          @core = ::Puppet::LorjCloud.get_instance
          @config = @core.config
        end

        servers = @core.query(:server, {:private_ip_addresses => [//, ipaddress]}, :search_for => "server with IP #{ipaddress}")

        return servers[0, :id] unless servers.length == 0

        ::Facter.warn prefix + "No server was found with private IP '#{ipaddress}'"
        :undefined
      end
    end

    module Parser
      extend ::Pinas::Lorj::Common
      # Function to get the host ID from +args+ definition.
      #
      # * *Args*:
      #   - +prefix+ : String. Prefix most of messages printed out.
      #   - +args+   : Supported function options:
      #     - +host_name+ : String. If containing ^/.*/$, the string
      #       will interpreted as a Regexp
      #
      # * *return*:
      #   - String : Host ID associated to the host name.
      def self.compute_id_lookup(prefix, args)
        # Puppet feature lorj_ready? ensure that everything is available.

        compute = server_object(prefix + "compute_private_ip_lookup", args)

        unless compute.empty?
          compute_id = compute[0][:id]
        end
        compute_id
      end

      # Function to get the Private IP from +args+ definition.
      #
      # * *Args*:
      #   - +prefix+ : String. Prefix most of messages printed out.
      #   - +args+   : Supported function options:
      #     - +host_name+ : String. If containing ^/.*/$, the string
      #       will interpreted as a Regexp
      #
      # * *return*:
      #   - String : Host ID associated to the host name.
      def self.compute_private_ip_lookup(prefix, args)
        # Puppet feature lorj_ready? ensure that everything is available.
        compute = server_object(prefix + "compute_private_ip_lookup", args)

        unless compute.empty?
          compute_ip = compute[0][:private_ip_addresses, //].flatten[0]
        end
        compute_ip
      end

      # Function to get the Public IP from +args+ definition.
      #
      # * *Args*:
      #   - +prefix+ : String. Prefix most of messages printed out.
      #   - +args+   : Supported function options:
      #     - +host_name+ : String. If containing ^/.*/$, the string
      #       will interpreted as a Regexp
      #
      # * *return*:
      #   - String : Host ID associated to the host name.
      def self.compute_public_ip_lookup(prefix, args)
        # Puppet feature lorj_ready? ensure that everything is available.

        compute = server_object(prefix + "compute_public_ip_lookup", args)
        unless compute.empty?
          compute_ip = compute[0][:public_ip_address, //].flatten[0]
        end
        compute_ip
      end

      def self.server_object(prefix, args)
        if (args.size != 1) then
           raise(::Puppet::ParseError, prefix + "compute_id_lookup: Wrong number of arguments "+
             "given #{args.size} for 1")
        end

        # determine if this is a regex string or not, if so convert @compute_name
        @compute_name = args[0]
        if @compute_name.sub(/(^\/)(.*)(\/$)/,'\1\3') == '//'
          @compute_name = Regexp.new(@compute_name.sub(/(^\/)(.*)(\/$)/,'\2'))
          ::Puppet.debug prefix + "performing regex search #{@compute_name.inspect}, class => #{@compute_name.class}"
        end
        @core = lorj_instance(prefix, ENV["LORJ_CONF"])
        return nil if @core.nil?

        # determin the compute id
        compute_id = ''
        begin
          compute = @core.query(:server, {:name => @compute_name}, :search_for => "#{@compute_name}")
        rescue Exception => e
          ::Puppet.warning prefix + "Problem getting compute, #{e} "
        end
      end
    end
  end
end
