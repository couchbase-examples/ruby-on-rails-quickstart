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

  def self.create(attributes)
    id = ROUTE_COLLECTION.insert(attributes)
    new(attributes.merge(id: id))
  rescue Couchbase::Error::DocumentExistsError
    nil
  end

  def update(attributes)
    ROUTE_COLLECTION.upsert(id, attributes)
    self.class.new(attributes)
  rescue Couchbase::Error::DocumentNotFound
    nil
  end

  def destroy
    ROUTE_COLLECTION.remove(id)
    true
  rescue Couchbase::Error::DocumentNotFound
    false
  end
end
