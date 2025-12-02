require 'couchbase'

# Get environment variables
DB_USERNAME = ENV['DB_USERNAME']
DB_PASSWORD = ENV['DB_PASSWORD']
DB_CONN_STR = ENV['DB_CONN_STR']
DB_BUCKET_NAME = 'travel-sample' # Hardcoded bucket name

# Helper method to connect with retry logic for transient failures
def connect_with_retry(max_attempts: 3, delay: 2)
  attempts = 0
  begin
    attempts += 1
    yield
  rescue Couchbase::Error::Timeout,
         Errno::ECONNREFUSED,
         Errno::EHOSTUNREACH => e
    if attempts < max_attempts
      warn "Couchbase connection attempt #{attempts}/#{max_attempts} failed: #{e.message}. Retrying in #{delay}s..."
      sleep delay
      retry
    else
      raise
    end
  end
end

# Helper method to set all Couchbase constants to nil
def set_couchbase_constants_to_nil
  Object.const_set(:COUCHBASE_CLUSTER, nil) unless defined?(COUCHBASE_CLUSTER)
  Object.const_set(:INVENTORY_SCOPE, nil) unless defined?(INVENTORY_SCOPE)
  Object.const_set(:INDEX_NAME, nil) unless defined?(INDEX_NAME)
  Object.const_set(:AIRLINE_COLLECTION, nil) unless defined?(AIRLINE_COLLECTION)
  Object.const_set(:AIRPORT_COLLECTION, nil) unless defined?(AIRPORT_COLLECTION)
  Object.const_set(:ROUTE_COLLECTION, nil) unless defined?(ROUTE_COLLECTION)
  Object.const_set(:HOTEL_COLLECTION, nil) unless defined?(HOTEL_COLLECTION)
end

begin
  # Check if running in CI environment
  if ENV['CI']
    # Use environment variables from GitHub Secrets with retry logic
    connect_with_retry do
      options = Couchbase::Cluster::ClusterOptions.new
      options.authenticate(DB_USERNAME, DB_PASSWORD)
      COUCHBASE_CLUSTER = Couchbase::Cluster.connect(DB_CONN_STR, options)
    end
  else
    # Load environment variables from dev.env file
    require 'dotenv'
    Dotenv.load('dev.env')

    # Define default values
    DEFAULT_DB_USERNAME = 'Administrator'
    DEFAULT_DB_PASSWORD = 'password'
    DEFAULT_DB_CONN_STR = 'couchbase://localhost'

    # Get environment variables with fallback to default values (using local variables)
    db_username = ENV.fetch('DB_USERNAME', DEFAULT_DB_USERNAME)
    db_password = ENV.fetch('DB_PASSWORD', DEFAULT_DB_PASSWORD)
    db_conn_str = ENV.fetch('DB_CONN_STR', DEFAULT_DB_CONN_STR)

    # Connect to the Couchbase cluster
    options = Couchbase::Cluster::ClusterOptions.new
    options.authenticate(db_username, db_password)
    COUCHBASE_CLUSTER = Couchbase::Cluster.connect(db_conn_str, options)
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

  begin
    # create hotel search index
    index_file_path = 'hotel_search_index.json'
    index_content = File.read(index_file_path)
    index_data = JSON.parse(index_content)
    name = index_data["name"]
    index = Couchbase::Management::SearchIndex.new
    index.name= index_data["name"]
    index.type= index_data["type"]
    index.uuid= index_data["uuid"] if index_data.has_key?("uuid")
    index.params= index_data["params"] if index_data.has_key?("params")
    index.source_name= index_data["sourceName"] if index_data.has_key?("sourceName")
    index.source_type= index_data["sourceType"] if index_data.has_key?("sourceType")
    index.source_uuid= index_data["sourceUUID"] if index_data.has_key?("sourceUUID")
    index.source_params= index_data["sourceParams"] if index_data.has_key?("sourceParams")
    index.plan_params= index_data["planParams"] if index_data.has_key?("planParams")
    scope.search_indexes.upsert_index(index)
  rescue StandardError => err
    #puts err.full_message
  end

  %w[airline airport route].each do |collection_name|
    scope.collection(collection_name)
  rescue Couchbase::Error::CollectionNotFoundError
    scope.create_collection(collection_name)
  end

  # Scope is declared as constant to run FTS queries
  INVENTORY_SCOPE = scope
  INDEX_NAME = name
  AIRLINE_COLLECTION = INVENTORY_SCOPE.collection('airline')
  AIRPORT_COLLECTION = INVENTORY_SCOPE.collection('airport')
  ROUTE_COLLECTION = INVENTORY_SCOPE.collection('route')
  HOTEL_COLLECTION = INVENTORY_SCOPE.collection('hotel')
rescue StandardError => e
  error_message = "Couchbase initialization failed: #{e.class.name} - #{e.message}"

  case defined?(Rails) ? Rails.env.to_s : (ENV['RAILS_ENV'] || 'development')
  when 'test'
    # In test environment, allow boot but log warning
    # Tests will fail with CouchbaseUnavailableError from models
    warn "\n#{'='*80}\n⚠️  WARNING: #{error_message}\n"
    warn "Integration tests require Couchbase. See README.md for setup.\n#{'='*80}\n"
    set_couchbase_constants_to_nil
  when 'production'
    # In production, fail fast - don't start without database
    abort("FATAL: #{error_message}\nProduction requires a valid Couchbase connection.")
  else
    # Development: allow boot for convenience, log warning
    warn "\n#{'='*80}\n⚠️  WARNING: #{error_message}\n"
    warn "API endpoints will return 503. See README.md for setup.\n#{'='*80}\n"
    set_couchbase_constants_to_nil
  end
end
