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

module Pinas
  module Cdn
    module Actions
      def get_cdn_service
        @loader = ::Pinas::Cdn::Provider::Loader
        @cdnservice = ::Pinas::Cdn::Provider::Cdn
        puts @cdnservice.inspect
        pinascdn = nil
        begin
          pinascdn = @cdnservice.instance(@loader.get_cdn)
        rescue Exception => e
          Puppet.warning "unable to find a valid cdn"
        end
        return pinascdn
      end


      # lookup node
      def get_file_name
        return @resource[:file_name]
      end


      # lookup name for type
      def get_remote_dir
        return @resource[:remote_dir]
      end


      # lookup recordd_type for type
      def get_local_dir
        return @resource[:local_dir]
      end


      def create
          cdnservice = get_cdn_service
          cdnservice.file_upload(get_local_dir, get_remote_dir, get_file_name)
      end


      def destroy
        cdnservice = get_cdn_service
        cdnservice.file_unlink(get_remote_dir, get_file_name)
      end


      def exists?
        cdnservice = get_cdn_service
        return cdnservice.file_exists(get_remote_dir, get_file_name)
      end
    end
  end
end

