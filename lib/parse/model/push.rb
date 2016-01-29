require_relative '../query.rb'
require_relative '../client.rb'

module Parse

  class Push
    include Client::Connectable
    attr_accessor :query, :alert, :badge, :sound, :title, :data
    attr_accessor :expiration_time, :expiration_interval, :push_time, :channels

    alias_method :message, :alert
    alias_method :message=, :alert=
    
    def self.send(payload)
      client.push payload.as_json
    end

    def initialize(constraints = {})
      self.where constraints
    end

    def query
      @query ||= Parse::Query.new(Parse::Model::CLASS_INSTALLATION)
    end

    def where=(where_clausees)
      query.where where_clauses
    end

    def where(constraints = nil)
      return query.compile_where unless constraints.is_a?(Hash)
      query.where constraints
      query
    end

    def channels=(list)
      @channels = [list].flatten
    end

    def data=(h)
      if h.is_a?(String)
        @alert = h
      else
        @data = h.symbolize_keys
      end
    end

    def as_json(*args)
      payload.as_json
    end

    def to_json(*args)
      as_json.to_json
    end

    def payload
      msg = {
        data: {
          alert: alert,
          badge: badge || "Increment".freeze
        }
      }
      msg[:data][:sound] = sound if sound.present?
      msg[:data][:title] = title if title.present?
      msg[:data].merge! @data if @data.is_a?(Hash)


      if @expiration_time.present?
        msg[:expiration_time] = @expiration_time.respond_to?(:iso8601) ? @expiration_time.iso8601(3) : @expiration_time
      end
      if @push_time.present?
        msg[:push_time] = @push_time.respond_to?(:iso8601) ? @push_time.iso8601(3) : @push_time
      end

      if @expiration_interval.is_a?(Numeric)
        msg[:expiration_interval] = @expiration_interval.to_i
      end

      if query.where.present?
        q = @query.dup
        if @channels.is_a?(Array) && @channels.empty? == false
          q.where :channels.in => @channels
        end
        msg[:where] = q.compile_where unless q.where.empty?
      elsif @channels.is_a?(Array) && @channels.empty? == false
        msg[:channels] = @channels
      end
      msg
    end

    def send(message = nil)
      @alert = message if message.is_a?(String)
      @data = message if message.is_a?(Hash)
      client.push( payload.as_json )
    end

  end

end
