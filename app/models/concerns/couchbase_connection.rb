# frozen_string_literal: true

module CouchbaseConnection
  extend ActiveSupport::Concern

  class_methods do
    def couchbase_available?
      defined?(COUCHBASE_CLUSTER) &&
        !COUCHBASE_CLUSTER.nil? &&
        defined?(AIRLINE_COLLECTION) &&
        !AIRLINE_COLLECTION.nil?
    end

    def ensure_couchbase!
      unless couchbase_available?
        raise CouchbaseUnavailableError,
          'Couchbase is not initialized. Check database configuration and ensure Couchbase is running.'
      end
    end
  end

  class CouchbaseUnavailableError < StandardError; end
end
