class Route
  attr_accessor :id
  attr_accessor :type
  attr_accessor :airline
  attr_accessor :airlineid
  attr_accessor :sourceairport
  attr_accessor :destinationairport
  attr_accessor :stops
  attr_accessor :equipment
  attr_accessor :schedule
  attr_accessor :distance

  def initialize(attributes)
    @id = attributes['id']
    @type = attributes['type']
    @airline = attributes['airline']
    @airlineid = attributes['airlineid']
    @sourceairport = attributes['sourceairport']
    @destinationairport = attributes['destinationairport']
    @stops = attributes['stops']
    @equipment = attributes['equipment']
    @schedule = attributes['schedule']
    @distance = attributes['distance']
  end

  def self.find(id)
    result = ROUTE_COLLECTION.get(id)
    new(result.content) if result.success?
  rescue Couchbase::Error::DocumentNotFound
    nil
  end

  def self.create(id,attributes)
    formatted_attributes = {
      'id' => attributes['id'],
      'type' => 'route',
      'airline' => attributes['airline'],
      'airlineid' => attributes['airlineid'],
      'sourceairport' => attributes['sourceairport'],
      'destinationairport' => attributes['destinationairport'],
      'stops' => attributes['stops'],
      'equipment' => attributes['equipment'],
      'schedule' => attributes['schedule'],
      'distance' => attributes['distance']
    }
    ROUTE_COLLECTION.insert(id, formatted_attributes)
    new(formatted_attributes)
  rescue Couchbase::Error::DocumentExists
    raise Couchbase::Error::DocumentExists, "Route with ID #{id} already exists"
  end

  def update(id,attributes)
    formatted_attributes = {
      'id' => attributes['id'],
      'type' => 'route',
      'airline' => attributes['airline'],
      'airlineid' => attributes['airlineid'],
      'sourceairport' => attributes['sourceairport'],
      'destinationairport' => attributes['destinationairport'],
      'stops' => attributes['stops'],
      'equipment' => attributes['equipment'],
      'schedule' => attributes['schedule'],
      'distance' => attributes['distance']
    }
    ROUTE_COLLECTION.upsert(id, formatted_attributes)
    self.class.new(formatted_attributes)
  rescue Couchbase::Error::DocumentNotFound
    raise Couchbase::Error::DocumentNotFound, "Route with ID #{id} not found"
  end

  def destroy(id)
    ROUTE_COLLECTION.remove(id)
    true
  rescue Couchbase::Error::DocumentNotFound
    false
  end
end
