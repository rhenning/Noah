require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Using the Ephemeral API", :reset_redis => true do
  before(:each) do
    Ohm.redis.flushdb
    Noah::Ephemeral.create(:path => "/foo/bar/baz", :data => "value1")
    Noah::Ephemeral.create(:path => "/baz/bar")
    Noah::Ephemeral.create(:path => "/go/away", :lifetime => 5, :data => "pft")
  end
  after(:each) do
    Ohm.redis.flushdb
  end
  describe "calling" do

    describe "GET" do
      it "all ephemerals should return 404" do
        get '/ephemerals'
        last_response.should_not be_ok
        last_response.status.should == 404
        response = last_response.should return_json
        response['error_message'].should == 'Resource not found'
        response['result'].should == 'failure'
      end

      it "named path with data should work" do
        get '/ephemerals/foo/bar/baz'
        last_response.should be_ok
        last_response.body.should == 'value1'
      end

      it "named path without data should work" do
        get '/ephemerals/baz/bar'
        last_response.status.should == 200
        last_response.body.should == ""
      end

      it "invalid path should not work" do
        get '/e/ssss/dddd'
        last_response.should_not be_ok
        last_response.status.should == 404
        response = last_response.should return_json
        response['error_message'].should == 'Resource not found'
        response['result'].should == 'failure'
      end

      it "ephemeral with a lifetime should disappear once expired" do
        sleep 10
        get '/ephemerals/go/away'
        last_response.should_not be_ok
        last_response.status.should == 404
        response = last_response.should return_json
        response['error_message'].should == 'Resource not found'
        response['result'].should == 'failure'
      end
    end

    describe "PUT" do
      it "new ephemeral with data should work" do
        put '/ephemerals/whiz/bang/', 'value3'
        last_response.should be_ok
        response = last_response.should return_json
        response['result'].should == 'success'
        response['id'].nil?.should == false
        response['path'].should == '/whiz/bang/'
        response['data'].should == 'value3'
      end

      it "new ephemeral without data should work" do
        put '/ephemerals/bang/whiz'
        last_response.should be_ok
        response = last_response.should return_json
        response['result'].should == 'success'
        response['action'].should == 'create'
        response['id'].nil?.should == false
        response['path'].should == '/bang/whiz'
        response['data'].should == nil
      end

      it "new ephemeral with lifetime should work" do
        put '/ephemerals/go/away?lifetime=5'
        last_response.should be_ok
        response = last_response.should return_json
        response['result'].should == 'success'
        response['action'].should == 'create'
        response['id'].nil?.should == false
        response['path'].should == '/go/away'
        response['data'].should == nil
      end

      it "existing ephemeral with data should work" do
        Noah::Ephemeral.create(:path => '/new/ephemeral', :data => 'old_value')
        get '/ephemerals/new/ephemeral'
        last_response.should be_ok
        last_response.body.should == 'old_value'
        put '/ephemerals/new/ephemeral', 'new_value'
        last_response.should be_ok
        get '/ephemerals/new/ephemeral'
        last_response.should be_ok
        last_response.body.should == 'new_value'
      end
      it "existing ephemeral without data should work" do
        Noah::Ephemeral.create(:path => '/a/random/key')
        get '/ephemerals/a/random/key'
        last_response.should be_ok
        last_response.body.should == ""
        put '/ephemerals/a/random/key', 'a new value'
        last_response.should be_ok
        get '/ephemerals/a/random/key'
        last_response.should be_ok
        last_response.body.should == 'a new value'
      end
      it "ephemeral with reserved word in subpath should work" do
        Noah::PROTECTED_PATHS.each do |path|
        put "/ephemerals/a/valid/path/with/#{path}"
          last_response.should be_ok
        end
      end
      it "ephemeral with reserved word as path should not work" do
        Noah::PROTECTED_PATHS.each do |path|
          put "/ephemerals/#{path}/other/stuff"
          last_response.should_not be_ok
          response = last_response.should return_json
          response['error_message'].should == 'Path is reserved'
          response['result'].should == 'failure'
        end
      end
    end

    describe "DELETE" do
      it "existing path should work" do
        e = Noah::Ephemeral.new(:path => '/slart/i/bart/fast', :data => 'someddata')
        e.save
        delete "/ephemerals/slart/i/bart/fast"
        last_response.should be_ok
        response = last_response.should return_json
        response['result'].should == 'success'
        response['action'].should == 'delete'
        response['id'].should == e.id
        response['path'].should == e.name
      end

      it "invalid path should not work" do
        delete '/ephemerals/fork/spoon/knife'
        last_response.should_not be_ok
        last_response.status.should == 404
        response = last_response.should return_json
        response['error_message'].should == 'Resource not found'
        response['result'].should == 'failure'
      end
    end
  end
end
