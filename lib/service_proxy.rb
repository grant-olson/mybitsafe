=begin
Make sure to do:
    gem install rest-client
 
Usage:
    h = ServiceProxy.new('http://user:password@127.0.0.1:8332')
    puts h.getinfo.call
    puts h.getbalance.call 'accname'
=end
require 'json'
require 'rest_client'
 
class JSONRPCException < RuntimeError
    def initialize()
        super()
    end
end
 
class ServiceProxy
    def initialize(service_url, service_name=nil)
        @service_url = service_url
        @service_name = service_name
    end
 
    def method_missing(name, *args, &block)
        if @service_name != nil
            name = "%s.%s" % [@service_name, name]
        end
        return ServiceProxy.new(@service_url, name)
    end
 
    def respond_to?(sym)
    end
 
    def call(*args)
        postdata = {"method" => @service_name, "params" => args, "id" => "jsonrpc"}.to_json
        respdata = RestClient.post @service_url, postdata
        resp = JSON.parse respdata
        if resp["error"] != nil
            raise JSONRPCException.new, resp['error']
        end
        return resp['result']
    end
end
