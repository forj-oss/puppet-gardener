# == gardener::tests::object_storage
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

class gardener::tests::pinascdn_upload (
  $file_name  = 'sample.txt',
  $remote_dir = 'fog-rocks',
  $local_dir  = '/tmp',
) {
  # include gardener::requirements
  warning('DEPRICATED, use rake acceptance spec/acceptance/classes/pinascdn_spec.rb')

  file { "${local_dir}/${file_name}":
    content => 'This is a test for gardener::tests::pinascdn_upload'
  } ->
  # Creating a file in Cloud Storage
  pinascdn {'myPinasCdn':
    ensure     => present,
    file_name  => $file_name,
    remote_dir => $remote_dir,
    local_dir  => $local_dir,
  }

}
