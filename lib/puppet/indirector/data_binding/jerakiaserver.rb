require 'puppet/indirector/code'
require 'jerakia/client'
require 'json'

class Puppet::DataBinding::Jerakiaserver < Puppet::Indirector::Code

  desc "Data binding for Jerakia"

  attr_reader :jerakia
  attr_reader :scope_cache


  def initialize(*args)
    @jerakia=::Jerakia::Client.new
    @scope_cache = {}
    super
  end

  def store_scope(identifier, uuid, scope)
    @scope_cache[identifier] = {
      :uuid => uuid,
      :scope  => scope
    }
  end

  def send_scope(identifier, scope)
    returndata = jerakia.send_scope('puppet', identifier, scope)
    store_scope(identifier, returndata['uuid'], scope)
  end

  def scope_valid?(identifier, metadata)
    return false unless @scope_cache.include?(identifier)
    return false unless @scope_cache[identifier][:scope] == metadata
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

    # If we are on an earlier version of Puppet that doesn't have trusted facts,
    # use the fqdn fact to identify us. Puppet 4 uses trusted.
    if metadata['trusted']
      identifier = metadata['trusted']['certname']
    else
      identifier = metadata['fqdn']
    end

    send_scope(identifier, metadata) unless scope_valid?(identifier, metadata)

    lookup_options = {
      :namespace => namespace,
      :scope => 'server',
      :scope_opts => {
        'identifier' => identifier,
        'realm' => 'puppet'
      }
    }

    begin
      lookup = jerakia.lookup(key, lookup_options)
    rescue Jerakia::Client::ScopeNotFoundError => e
      send_scope(identifier, metadata)
      lookup = jerakia.lookup(key, lookup_options)
    rescue => e
      raise Puppet::DataBinding::LookupError.new("Jerakia data lookup failed #{e.class}", e.message)
    end

    if lookup.is_a?(Hash)
      raise Puppet::DataBinding::LookupError.new("Jerakia data lookup failed", lookup['message']) unless lookup['status'] = 'ok'
      return lookup['payload']
    else
      raise Puppet::DataBinding::LookupError.new("Jerakia data lookup failed", "Expected a hash but got a #{lookup.class}")
    end
  end
end
