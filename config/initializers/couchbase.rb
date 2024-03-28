require 'couchbase'

# Get environment variables
DB_USERNAME = ENV['DB_USERNAME']
DB_PASSWORD = ENV['DB_PASSWORD']
DB_CONN_STR = ENV['DB_CONN_STR']
DB_BUCKET_NAME = ENV['DB_BUCKET_NAME']

# Check if running in CI environment
if ENV['CI']
  # Use environment variables from GitHub Secrets
  options = Couchbase::Cluster::ClusterOptions.new
  options.authenticate(DB_USERNAME, DB_PASSWORD)
  COUCHBASE_CLUSTER = Couchbase::Cluster.connect(DB_CONN_STR, options)
else
  # Load environment variables from dev.env file
  require 'dotenv'
  Dotenv.load('dev.env')

  # Define default values
  DEFAULT_DB_USERNAME = 'Administrator'
  DEFAULT_DB_PASSWORD = 'password'
  DEFAULT_DB_CONN_STR = 'couchbase://localhost'
  DEFAULT_DB_BUCKET_NAME = 'travel-sample'

  # Get environment variables with fallback to default values
  DB_USERNAME = ENV.fetch('DB_USERNAME', DEFAULT_DB_USERNAME)
  DB_PASSWORD = ENV.fetch('DB_PASSWORD', DEFAULT_DB_PASSWORD)
  DB_CONN_STR = ENV.fetch('DB_CONN_STR', DEFAULT_DB_CONN_STR)
  DB_BUCKET_NAME = ENV.fetch('DB_BUCKET_NAME', DEFAULT_DB_BUCKET_NAME)

  # Connect to the Couchbase cluster
  options = Couchbase::Cluster::ClusterOptions.new
  options.authenticate(DB_USERNAME, DB_PASSWORD)
  COUCHBASE_CLUSTER = Couchbase::Cluster.connect(DB_CONN_STR, options)
end

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

%w[airline airport route].each do |collection_name|
  scope.collection(collection_name)
rescue Couchbase::Error::CollectionNotFoundError
  scope.create_collection(collection_name)
end

AIRLINE_COLLECTION = scope.collection('airline')
AIRPORT_COLLECTION = scope.collection('airport')
ROUTE_COLLECTION = scope.collection('route')
