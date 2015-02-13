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
require 'spec_helper_acceptance'

describe 'pinas type', :long_run => true do
  describe 'provision server' do
    # Using puppet_apply as a helper
    it 'should create server with no errors' do
      pp = <<-EOS
        include gardener::tests::server_up
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, {:modulepath => get_module_path(get_beaker_ext_module_paths),
                          :acceptable_exit_codes => [0,2],
                          :catch_failures => true})
      apply_manifest(pp, {:modulepath => get_module_path(get_beaker_ext_module_paths),
                          :acceptable_exit_codes => [0,2],
                          :catch_changes => true})
    end
    it 'should create destroy with no errors' do
      pp = <<-EOS
        include gardener::tests::server_destroy
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, {:modulepath => get_module_path(get_beaker_ext_module_paths),
                          :acceptable_exit_codes => [0,2],
                          :catch_failures => true})
      apply_manifest(pp, {:modulepath => get_module_path(get_beaker_ext_module_paths),
                          :acceptable_exit_codes => [0,2],
                          :catch_changes => true})
    end
  end
end
