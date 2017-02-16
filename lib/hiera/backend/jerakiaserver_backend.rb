require 'puppet'
require 'puppet/resource'
require 'jerakia/client'

class Hiera
  module Backend
    class Jerakiaserver_backend

      def initialize(config = nil)
        @config = config || Hiera::Config[:jerakia] || {}
        @jerakia = ::Jerakia::Client.new
        @scope_cache = {}
      end

      def store_scope(identifier, uuid, scope)
        @scope_cache[identifier] = {
          :uuid => uuid,
          :scope  => scope
        }
      end

      def send_scope(identifier, scope)
        returndata = @jerakia.send_scope('puppet', identifier, scope)
        store_scope(identifier, returndata['uuid'], scope)
      end

      def scope_valid?(identifier, metadata)
        return false unless @scope_cache.include?(identifier)
        return false unless @scope_cache[identifier][:scope] == metadata
        return true
     end

      def lookup(key, scope, order_override, resolution_type)

        # Jerakia doesn't do anything with lookup_options, this behaviour is achieved
        # using schemas, therefore we always return nil here for the key

        return nil if key == 'lookup_options'

        lookup_type = :first
        merge_type = :none

        case resolution_type
        when :array
          lookup_type = :cascade
          merge_type = :array
        when :hash
          lookup_type = :cascade
          merge_type = :hash
        end

        namespace = []

        if key.include?('::')
           lookup_key = key.split('::')
           key = lookup_key.pop
           namespace = lookup_key.join('/')
        end




        metadata={}
        if scope.is_a?(Hash)
          metadata=scope.reject { |k, v| v.is_a?(Puppet::Resource) }
        else
          metadata = scope.real.to_hash.reject { |k, v| v.is_a?(Puppet::Resource) }
        end


        if metadata['trusted']
          identifier = metadata['trusted']['certname']
        else
          identifier = metadata['fqdn']
        end

        send_scope(identifier, metadata) unless scope_valid?(identifier, metadata)

        lookup_options = {
          :namespace => namespace,
          :scope => 'server',
          :lookup_type => lookup_type.to_s,
          :merge  => merge_type.to_s,
          :scope_opts => {
            'identifier' => identifier,
            'realm' => 'puppet'
          }
        }

        begin
          lookup = @jerakia.lookup(key, lookup_options)
        rescue Jerakia::Client::ScopeNotFoundError => e
          send_scope(identifier, metadata)
          lookup = @jerakia.lookup(key, lookup_options)
        end

        if lookup.is_a?(Hash)
          raise Puppet::Error, "Jerakia data lookup failed #{lookup['message']}" unless lookup['status'] = 'ok'

          payload = lookup['payload']
          case resolution_type
          when :array
            return [] if payload.nil?
            return payload
          when :hash
            return {} if payload.nil?
            return payload
          else
            return payload
          end
        else
          raise Puppet::Error, "Jerakia data lookup failed Expected a hash but got a #{lookup.class}"
        end
      end
    end
  end
end
