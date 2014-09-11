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
require 'spec_helper'

describe 'gardener::tests::pinascdn_upload', :default => true do
  let(:params) { {:remote_dir => 'fog-rocks', :local_dir => '/tmp', :file_name => 'my_file.txt'} }
  context 'with default values' do
    it { should compile }
  end
end

describe 'gardener::tests::pinascdn_delete', :default => true do
  let(:params) { {:remote_dir => 'fog-rocks', :file_name => 'my_file.txt'} }
  context 'with default values' do
    it { should compile }
  end
end

describe "apply test pinas cdn upload", :apply => true do
  let(:params) { {:remote_dir => 'fog-rocks', :local_dir => '/tmp', :file_name => 'my_file.txt'} }
  context 'with puppet apply' do
    it "should upload a file to object storage with." do
      apply("include gardener::tests::pinascdn_upload").should be(true)
    end
  end
end

describe "apply test pinas cdn delete", :apply => true do
  let(:params) { {:remote_dir => 'fog-rocks', :file_name => 'my_file.txt'} }
  context 'with puppet apply' do
    it "should delete a file from object storage with." do
      apply("include gardener::tests::pinascdn_delete").should be(true)
    end
  end
end

