require 'couchbase'

# Get environment variables
DB_USERNAME = ENV['DB_USERNAME']
DB_PASSWORD = ENV['DB_PASSWORD']
DB_CONN_STR = ENV['DB_CONN_STR']
DB_BUCKET_NAME = 'travel-sample' # Hardcoded bucket name

begin
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
rescue StandardError => err
  # Allow Rails to boot even if Couchbase is not reachable/misconfigured
  warn_msg = "Couchbase initialization skipped: #{err.class}: #{err.message}"
  defined?(Rails) ? Rails.logger.warn(warn_msg) : warn(warn_msg)
  COUCHBASE_CLUSTER = nil
  INVENTORY_SCOPE = nil
  INDEX_NAME = nil
  AIRLINE_COLLECTION = nil
  AIRPORT_COLLECTION = nil
  ROUTE_COLLECTION = nil
  HOTEL_COLLECTION = nil
end
