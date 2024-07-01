# frozen_string_literal: true

class HotelSearch
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
      request = Couchbase::SearchRequest.new(
          Couchbase::SearchQuery.match(name) {|obj| obj.field = "name"}
      )
      options = Couchbase::Options::Search.new
      options.limit = 50
      options.fields = ["name"]
      result = INVENTORY_SCOPE.search(INDEX_NAME, request, options)
      result.rows.map do |row|
        row.fields["name"]
      end
    end

    def self.filter(hotel_search, offset, limit)
      query = Couchbase::SearchQuery.conjuncts()

      query.and_also(
        Couchbase::SearchQuery.term(hotel_search.name) {|obj| obj.field = "name_keyword"}
      ) if hotel_search.name

      query.and_also(
        Couchbase::SearchQuery.match(hotel_search.title) {|obj| obj.field = "title"}
      ) if hotel_search.title

      query.and_also(
        Couchbase::SearchQuery.match(hotel_search.description) {|obj| obj.field = "description"}
      ) if hotel_search.description

      query.and_also(
        Couchbase::SearchQuery.match(hotel_search.country) {|obj| obj.field = "country"}
      ) if hotel_search.country

      query.and_also(
        Couchbase::SearchQuery.match(hotel_search.state) {|obj| obj.field = "state"}
      ) if hotel_search.state

      query.and_also(
        Couchbase::SearchQuery.match(hotel_search.city) {|obj| obj.field = "city"}
      ) if hotel_search.city

      request = Couchbase::SearchRequest.new(query)

      options = Couchbase::Options::Search.new
      options.skip = 0
      options.limit = 50
      options.skip = offset if offset
      options.limit= limit if limit
      options.fields = ["*"]
      options.sort = ["-_score", "name_keyword"]

      result = INVENTORY_SCOPE.search(INDEX_NAME, request, options)
      result.rows.map do |row|
        new(row.fields)
      end
    end
end
  