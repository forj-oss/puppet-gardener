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

Puppet::Type.newtype(:pinascdn) do
  @doc = %q{ Uses fog api to handle object storage.

        Example:
            include gardener::requirements

            pinascdn {'myPinasCdn':
                ensure        => present,
                file_name     => 'sample.txt',
                remote_dir    => 'my-cloud-container',
                local_dir     => '/tmp',
                files_to_keep => 3,
              }

            pinascdn {'myPinasCdnDelete':
              ensure      => absent,
              file_name   => 'sample.txt',
              remote_dir  => 'my-cloud-container',
            }
      }

  ensurable

  newparam(:name) do
    desc "identifier name."
  end

  newparam(:file_name) do
    desc "File name and extension"
  end

  newparam(:remote_dir) do
    desc "Cloud directory"
  end

  newparam(:local_dir) do
    desc "Local directory (Unix format)"
  end

  newparam(:files_to_keep) do
    desc "Optional parameter, keeps n files on object storage"
  end

end
