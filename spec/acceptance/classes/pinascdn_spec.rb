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

#TODO: need to fix pinascdn for null containers
#/etc/puppet/modules/gardener/lib/puppet/provider/pinascdn/actions.rb
#63  
#64        def exists?
# TODO: need to fix result when cdnservice is nil
#66          cdnservice = get_cdn_service
#=> 67          return cdnservice.file_exists(get_remote_dir, get_file_name)
# TODO: switch default back to true
describe 'pinascdn', :default => false do
  describe 'upload file' do
    # Using puppet_apply as a helper
    fixtures_dir  = 'spec/fixtures/data'
    fixtures_file = 'my_file.txt'
    fixtures_data = "#{fixtures_dir}/#{fixtures_file}"
    cdn_dir = 'fog-rocks'
    it "should upload #{fixtures_data} to :#{cdn_dir} container" do

      expect(File.exists?(fixtures_data)).to be true

      pp = <<-EOS
        pinascdn {'myPinasCdn':
                      ensure      => present,
                      file_name   => '#{fixtures_file}',
                      remote_dir  => '#{cdn_dir}',
                      local_dir   => '#{fixtures_dir}',
                 }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, {:modulepath => get_module_path(get_beaker_ext_module_paths),
                          :acceptable_exit_codes => [0,1,2],
                          :catch_failures => true})
      apply_manifest(pp, {:modulepath => get_module_path(get_beaker_ext_module_paths),
                          :acceptable_exit_codes => [0,1,2],
                          :catch_changes => true})
      # TODO: need a test that verifies the file was uploaded.
      # expect(shell("gem1.8 list|grep hpcloud").exit_code).to be_zero
    end
  end
  describe 'delete file' do
    it 'should delete my_file.txt from :fog-rocks container' do
      pp = <<-EOS
        include gardener::tests::pinascdn_delete
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, {:modulepath => get_module_path(get_beaker_ext_module_paths),
                          :acceptable_exit_codes => [0,1,2],
                          :catch_failures => true})
      apply_manifest(pp, {:modulepath => get_module_path(get_beaker_ext_module_paths),
                          :acceptable_exit_codes => [0,1,2],
                          :catch_changes => true})
      # TODO: need a test that verifies the file was deleted.
      # expect(shell("gem1.8 list|grep hpcloud").exit_code).to be_zero
    end
  end
end


