# frozen_string_literal: true

class Hotel
  include CouchbaseConnection

  attr_accessor :name, :title, :description, :country, :city, :state

  def initialize(attributes)
    @name = attributes['name']
    @title = attributes['title']
    @description = attributes['description']
    @country = attributes['country']
    @city = attributes['city']
    @state = attributes['state']
  end

  def self.search_name(name)
    ensure_couchbase!
    request = Couchbase::SearchRequest.new(
      Couchbase::SearchQuery.match(name) { |obj| obj.field = 'name' }
    )
    options = Couchbase::Options::Search.new
    options.limit = 50
    options.fields = ['name']
    result = INVENTORY_SCOPE.search(INDEX_NAME, request, options)
    result.rows.map do |row|
      row.fields['name']
    end
  end

  def self.filter(hotel, offset, limit)
    ensure_couchbase!
    query = Couchbase::SearchQuery.conjuncts

    query.and_also(
      Couchbase::SearchQuery.term(hotel.name) { |obj| obj.field = 'name_keyword' }
    ) if hotel.name

    query.and_also(
      Couchbase::SearchQuery.match(hotel.title) { |obj| obj.field = 'title' }
    ) if hotel.title

    query.and_also(
      Couchbase::SearchQuery.match(hotel.description) { |obj| obj.field = 'description' }
    ) if hotel.description

    query.and_also(
      Couchbase::SearchQuery.match(hotel.country) { |obj| obj.field = 'country' }
    ) if hotel.country

    query.and_also(
      Couchbase::SearchQuery.match(hotel.state) { |obj| obj.field = 'state' }
    ) if hotel.state

    query.and_also(
      Couchbase::SearchQuery.match(hotel.city) { |obj| obj.field = 'city' }
    ) if hotel.city

    request = Couchbase::SearchRequest.new(query)

    options = Couchbase::Options::Search.new
    options.skip = 0
    options.limit = 50
    options.skip = offset if offset
    options.limit = limit if limit
    options.fields = ['*']
    options.sort = ['-_score', 'name_keyword']

    result = INVENTORY_SCOPE.search(INDEX_NAME, request, options)
    result.rows.map do |row|
      new(row.fields)
    end
  end
end
