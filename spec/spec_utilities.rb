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
require 'yaml'
module SpecUtilities
  module Puppet
    def is_long_run_enabled?
      return (/(false|FALSE|0|off|OFF)/ === ENV['LONG_RUN'] ? false : true)
    end
    # TODO: depricate
    def apply(content = nil, debug = false)
      debug_opts = (debug == true) ? " --debug --verbose"  : " "
      if content != nil
        puts "running => #{content}"
        return command("puppet","apply#{debug_opts} --modulepath=#{get_module_path} -e \"#{content}\"")
      end
    end
    # TODO: depricate
    def applynoop(content = nil, debug = false)
      if content != nil
        puts "running => #{content}"
        debug_opts = (debug == true) ? " --debug --verbose"  : " "
        return command("puppet","apply#{debug_opts} --modulepath=#{get_module_path} -e \"#{content}\" --noop")
      end
    end

    #
    # get repositories from .fixtures.yml
    # example:
    # fixtures:
    #  repositories:
    #   maestro: "https://review.forj.io/forj-oss/maestro"
    #  should translate to -> fixtures/modules/maestro
    def get_ext_module_paths(fixtures_path = File.join(__FILE__,'..','..','.fixtures.yml'),
                              project_root = File.expand_path(File.join(__FILE__,'..','..')))
      fixtures_file=File.expand_path(fixtures_path)
      fixtures = YAML.load_file(fixtures_file)
      module_path_build = []
      fixtures['fixtures']['repositories'].each do |fixture|
        module_path_build << File.join('spec','fixtures','modules',fixture[0])
      end

      module_path = []
      module_path_build.each do |mod_path|
        if File.exists?(File.expand_path(File.join(project_root,mod_path,'Modulefile')))
          module_path << File.join(mod_path,'..')
        elsif File.exists?(File.expand_path(File.join(mod_path,'modules')))
          module_path << File.join(mod_path,'modules')
        elsif File.exists?(File.expand_path(File.join(mod_path,'puppet','modules')))
          module_path << File.join(mod_path,'puppet','modules')
        end
      end
      return module_path
    end

    #
    # get the module paths relative to beaker install_module location
    #
    def get_beaker_ext_module_paths(fixtures_path = nil,
                                    puppet_modules_dir = ['','etc','puppet','modules'].join(File::SEPARATOR))
      modules_paths = nil
      if fixtures_path == nil
        modules_path = get_ext_module_paths
      else
        modules_path = get_ext_module_paths(fixtures_path)
      end
      beaker_modules_path = []
      modules_path.each do |module_path|
        beaker_modules_path << File.join(puppet_modules_dir,get_module_name,module_path)
      end
      return beaker_modules_path
    end
    #
    # get the modulename from the Modulefile for this module
    #
    def get_module_name
      module_file=File.expand_path(File.join(__FILE__,'..','..','Modulefile'))
      module_name = nil
      if File.exists?(module_file)
        File.open(module_file).read.gsub!(/\n\r?/,"\t").split("\t",2).each do | mod_line |
          if mod_line.gsub(/\s+/,' ').split(' ',2)[0] == 'name'
            module_name = mod_line.gsub(/\s+/,' ').split(' ',2)[1].gsub(/'$/,'').gsub(/^'/,'')
            module_name = module_name.split('-',2)[1] if module_name.include? '-' 
            break
          end
        end
      end
      raise 'a Modulefile for this module should be created' if module_name == nil
      return module_name
    end
#
# PUPPET_MODULES superseeds all other module paths
# use ext_lib_name modules to specify test case module path for 3rd party libs
# this module should be tested from /etc/puppet/modules
#
    def get_module_path(ext_lib_name = [])
      modules = []
      if ENV['PUPPET_MODULES'] != nil
        modules = [ENV['PUPPET_MODULES'],ext_lib_name.join(File::PATH_SEPARATOR).to_s]
      else
        modules = [ext_lib_name.join(File::PATH_SEPARATOR).to_s,File.join('','etc','puppet','modules')]
      end
      return modules.join(File::PATH_SEPARATOR).to_s
    end
  end
#
# like shell but for local execution
#
  module Exec
    def command(command, args)
        begin
           command += " "
           command.concat(args)
           puts command
           output = `#{command}`
           exit_status = $?.exitstatus

           output.split(/\r?\n/).each { |line| 
             p line
           }
           puts "Exit Status ( #{exit_status} )"
           return (exit_status == 0)
        rescue Exception => e
           puts "Problem running command -> #{command}"
           puts e.message
           return false
        end
    end
  end
end
