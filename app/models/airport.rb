class Airport
  attr_accessor :id
  attr_accessor :type
  attr_accessor :airportname
  attr_accessor :city
  attr_accessor :country
  attr_accessor :faa
  attr_accessor :icao
  attr_accessor :tz
  attr_accessor :geo

  def initialize(attributes)
    @id = attributes['id']
    @type = attributes['type']
    @airportname = attributes['airportname']
    @city = attributes['city']
    @country = attributes['country']
    @faa = attributes['faa']
    @icao = attributes['icao']
    @tz = attributes['tz']
    @geo = attributes['geo']
  end

  def self.find(id)
    result = AIRPORT_COLLECTION.get(id)
    new(result.content) if result.success?
  rescue Couchbase::Error::DocumentNotFound
    nil
  end

  def self.create(id,attributes)
    formatted_attributes = {
      'id' => attributes['id'],
      'type' => 'airport',
      'airportname' => attributes['airportname'],
      'city' => attributes['city'],
      'country' => attributes['country'],
      'faa' => attributes['faa'],
      'icao' => attributes['icao'],
      'tz' => attributes['tz'],
      'geo' => attributes['geo']
    }
    AIRPORT_COLLECTION.insert(id, formatted_attributes)
    new(formatted_attributes)
  rescue Couchbase::Error::DocumentExists
    raise Couchbase::Error::DocumentExists, "Airport with ID #{id} already exists"
  end

  def update(id,attributes)
    formatted_attributes = {
      'id' => attributes['id'],
      'type' => 'airport',
      'airportname' => attributes['airportname'],
      'city' => attributes['city'],
      'country' => attributes['country'],
      'faa' => attributes['faa'],
      'icao' => attributes['icao'],
      'tz' => attributes['tz'],
      'geo' => attributes['geo']
    }
    AIRPORT_COLLECTION.upsert(id, formatted_attributes)
    self.class.new(formatted_attributes)
  rescue Couchbase::Error::DocumentNotFound
    raise Couchbase::Error::DocumentNotFound, "Airport with ID #{id} not found"
  end

  def destroy(id)
    AIRPORT_COLLECTION.remove(id)
    true
  rescue Couchbase::Error::DocumentNotFound
    false
  end

  def self.direct_connections(destination_airport_code, limit = 10, offset = 0)
    bucket_name = 'travel-sample'
    scope_name = 'inventory'
    route_collection_name = 'route'
    airport_collection_name = 'airport'

    query = "
      SELECT DISTINCT route.destinationairport
      FROM `#{bucket_name}`.`#{scope_name}`.`#{airport_collection_name}` AS airport
      JOIN `#{bucket_name}`.`#{scope_name}`.`#{route_collection_name}` AS route ON route.sourceairport = airport.faa
      WHERE airport.faa = $destinationAirportCode AND route.stops = 0
      LIMIT $limit OFFSET $offset
    "

    options = Couchbase::Cluster::QueryOptions.new
    options.named_parameters({ "destinationAirportCode" => destination_airport_code, "limit" => limit.to_i, "offset" => offset.to_i })

    result = COUCHBASE_CLUSTER.query(query, options)
    result.rows.map { |row| row['destinationairport'] }
  end
end
