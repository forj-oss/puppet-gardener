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

require 'fog' if Puppet.features.fog?
require 'json' if Puppet.features.json?
require 'erb'
#TODO: This class brings together network and compute, we may need to break these out down the line.
module Puppet
  module Pinas
    class Cdn
      attr_accessor :cdn


      # singleton call:
      def self.instance(comm)
        @@pinas ||= self.new(comm)
        return @@pinas
      end


      #  initialize
      def initialize(comm)
        @cdn = comm
      end


      def getContainer(target)
        begin
          return @cdn.directories.get(target)
        rescue Exception => e
          Puppet.warning e.message
          Puppet.debug e.backtrace.inspect
          raise "Unable to create a Fog Storage Connection, verify your Fog configuration."
        end
      end


      #Uploads a file to object storage
      def file_upload(source, target, name)
        Puppet.debug "Uploading #{source}/#{name} to #{target}"
        dir = getContainer(target)

        if dir.nil?
          #Create a directory
          dir = @cdn.directories.create(
            :key    => target, # globally unique name
            :public => true
          )
          Puppet.debug "Directory created: #{target}"
          dir = @cdn.directories.get(target)
        end

        #Uploads the file
        file = dir.files.create(
          :key    => name,
          :body   => File.open("#{source}/#{name}"),
          :public => false
        )

        Puppet.debug "File uploaded!"
      end


      #Deletes a file from object storage
      def file_unlink(target, name)
        Puppet.debug "Deleting #{target}/#{name}"
        dir = getContainer(target)

        if dir.nil?
          Puppet.warning "Puppet::PinasCdn::file_unlink: Container doesnt exist (#{target})."
        else
          if dir.files.head(name)
            # 'new' method does not download the file from Object Storage
            file = dir.files.new(:key => name)
            file.destroy
            Puppet.debug "Deleted!"
          else
            Puppet.warning "Puppet::PinasCdn::file_unlink: #{target}/#{name} doesnt exist."
          end
        end
      end


      #Verifies if a file exists in object storage
      def file_exists(target, name)
        r = false
        dir = getContainer(target)

        if dir.nil?
          Puppet.debug "Container doesn't exist: #{target}"
        else
          r = dir.files.head(name) ? true : false
          Puppet.debug "#{target}/#{name} exists ? #{r}"
        end

        return r
      end


    end
  end
end
