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

describe 'to_json', :default => true do
  it 'should change { \'a\' => \'1\' } to { "a" : "1" }' do
   should run.with_params({ "a" => "1" }).and_return("{\"a\":\"1\"}")
  end

  it 'should change [1,2] to [ "1" , "2" }' do
   should run.with_params([1,2]).and_return("[1,2]")
  end

  it 'should throw exception Puppet::ParseError with no arguments' do
    should run.with_params().and_raise_error(Puppet::ParseError)
  end
end
