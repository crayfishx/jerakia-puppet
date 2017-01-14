require 'puppet/indirector/code'
require 'jerakia/client'
require 'json'
require 'digest/md5'

class Puppet::DataBinding::Jerakiaserver < Puppet::Indirector::Code

  desc "Data binding for Jerakia"

  attr_reader :jerakia
  attr_reader :scope_cache


  def initialize(*args)
    @jerakia=::Jerakia::Client.new
    @scope_cache = {}
    super
  end

  def server_scope(identifier)
    returndata = jerakia.get_scope_uuid('puppet', identifier)
    if returndata.is_a?(Hash)
      return returndata['uuid']
    else
      return nil
    end
  end

  def store_scope(identifier, uuid, scope)
    @scope_cache[identifier] = {
      :uuid => uuid,
      :md5  => Digest::MD5.hexdigest(scope.to_s)
    }
  end

  def send_scope(identifier, scope)
    returndata = jerakia.send_scope('puppet', identifier, scope)
    store_scope(identifier, returndata['uuid'], scope)
  end

  def scope_valid?(identifier, scope)
    uuid = server_scope(identifier)

    # If the server doesn't have a copy, refresh
    return false unless uuid

    if scope_cache[identifier]
      # If the UUID is different we need to refresh
      return false unless scope_cache[identifier][:uuid] == uuid

      # If the MD5 sum of the scope has changed, we are probably in a new
      # puppet run and need to refresh the scope.
      return false unless scope_cache[identifier][:md5] == Digest::MD5.hexdigest(scope.to_s)
    else

      # If the scope is not cached at all then we should refresh
      return false
    end
    return true
  end




  def find(request)

    # Jerakia doesn't do anything with lookup_options, this behaviour is achieved
    # using schemas, therefore we always return nil here for the key
    return nil if request.key == 'lookup_options'

    lookupdata=request.key.split(/::/)
    key=lookupdata.pop
    namespace=lookupdata.join('/')
    metadata =  request.options[:variables].to_hash.reject { |k, v| v.is_a?(Puppet::Resource) }

    # If the scope is unchanged assume this is part of the same puppet run and don't resend
    # otherwise we need to send the scope to Jerakia server ahead of time.
    #
    identifier = metadata['trusted']['certname']

    send_scope(identifier, metadata) unless scope_valid?(identifier, metadata)

    lookup_options = {
      :namespace => namespace,
      :scope => 'server',
      :scope_opts => {
        'identifier' => identifier,
        'realm' => 'puppet'
      }
    }

    lookup = jerakia.lookup(key, lookup_options)
    if lookup.is_a?(Hash)
      raise Puppet::DataBinding::LookupError.new("Jerakia data lookup failed", lookup['message']) unless lookup['status'] = 'ok'
      return lookup['payload']
    else
      raise Puppet::DataBinding::LookupError.new("Jerakia data lookup failed", "Unknown reason")
    end
  end
end
