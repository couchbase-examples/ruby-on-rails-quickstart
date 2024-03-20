require 'couchbase'

DB_USERNAME = ENV.fetch('DB_USERNAME', 'kaustav')
DB_PASSWORD = ENV.fetch('DB_PASSWORD', 'password')
DB_HOST = ENV.fetch('DB_HOST', 'couchbase://localhost')
DB_BUCKET_NAME = ENV.fetch('DB_BUCKET_NAME', 'travel-sample')

# Connect to the Couchbase cluster
options = Couchbase::Cluster::ClusterOptions.new
options.authenticate(DB_USERNAME, DB_PASSWORD)

COUCHBASE_CLUSTER = Couchbase::Cluster.connect(DB_HOST, options)

# Open the bucket
bucket = COUCHBASE_CLUSTER.bucket(DB_BUCKET_NAME)

# Open the default collection
default_collection = bucket.default_collection

# Create scope and collections if they don't exist
begin
  scope = bucket.scope('inventory')
rescue Couchbase::Error::ScopeNotFoundError
  bucket.create_scope('inventory')
  scope = bucket.scope('inventory')
end

['airline', 'airport', 'route'].each do |collection_name|
  begin
    scope.collection(collection_name)
  rescue Couchbase::Error::CollectionNotFoundError
    scope.create_collection(collection_name)
  end
end

AIRLINE_COLLECTION = scope.collection('airline')
AIRPORT_COLLECTION = scope.collection('airport')
ROUTE_COLLECTION = scope.collection('route')