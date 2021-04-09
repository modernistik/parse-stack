# encoding: UTF-8
# frozen_string_literal: true

require_relative "request"
require_relative "response"

module Parse
  # Create a new batch operation.
  # @param reqs [Array<Parse::Request>] a set of requests to batch.
  # @return [BatchOperation] a new {BatchOperation} with the given change requests.
  def self.batch(reqs = nil)
    BatchOperation.new(reqs)
  end

  # This class provides a standard way to submit, manage and process batch operations
  # for Parse::Objects and associations.
  #
  # Batch requests are supported implicitly and intelligently through an
  # extension of array. When an array of Parse::Object subclasses is saved,
  # Parse-Stack will batch all possible save operations for the objects in the
  # array that have changed. It will also batch save 50 at a time until all items
  # in the array are saved. Note: Parse does not allow batch saving Parse::User objects.
  #
  #  songs = Songs.first 1000 #first 1000 songs
  #  songs.each do |song|
  #   # ... modify song ...
  #  end
  #
  #  # will batch save 50 items at a time until all are saved.
  #  songs.save
  #
  # The objects do not have to be of the same collection in order to be supported in the
  # batch request.
  # @see Array.save
  # @see Array.destroy
  class BatchOperation
    include Enumerable

    # @!attribute requests
    #  @return [Array] the set of requests in this batch.

    # @!attribute responses
    #  @return [Array] the set of responses from this batch.
    attr_accessor :requests, :responses

    # @return [Parse::Client] the client to be used for the request.
    def client
      @client ||= Parse::Client.client
    end

    # @param reqs [Array<Parse::Request>] an array of requests.
    def initialize(reqs = nil)
      @requests = []
      @responses = []
      reqs = [reqs] unless reqs.is_a?(Enumerable)
      reqs.each { |r| add(r) } if reqs.is_a?(Enumerable)
    end

    # Add an additional request to this batch.
    # @overload add(req)
    #  @param req [Parse::Request] the request to append.
    #  @return [Array<Parse::Request>] the set of requests.
    # @overload add(batch)
    #  @param req [Parse::BatchOperation] add all the requests from this batch operation.
    #  @return [Array<Parse::Request>] the set of requests.
    def add(req)
      if req.respond_to?(:change_requests)
        requests = req.change_requests.select { |r| r.is_a?(Parse::Request) }
        @requests += requests
      elsif req.is_a?(Array)
        requests = req.select { |r| r.is_a?(Parse::Request) }
        @requests += requests
      elsif req.is_a?(BatchOperation)
        @requests += req.requests if req.is_a?(BatchOperation)
      else
        @requests.push(req) if req.is_a?(Parse::Request)
      end
      @requests
    end

    # This method is for interoperability with Parse::Object instances.
    # @see Parse::Object#change_requests
    def change_requests
      @requests
    end

    # @return [Array]
    def each(&block)
      return enum_for(:each) unless block_given?
      @requests.each(&block)
    end

    # @return [Hash] a formatted payload for the batch request.
    def as_json(*args)
      { requests: requests }.as_json
    end

    # @return [Integer] the number of requests in the batch.
    def count
      @requests.count
    end

    # Remove all requests in this batch.
    # @return [Array]
    def clear!
      @requests.clear
    end

    # @return [Boolean] true if the request was successful.
    def success?
      return false if @responses.empty?
      @responses.compact.all?(&:success?)
    end

    # @return [Boolean] true if the request had an error.
    def error?
      return false if @responses.empty?
      !success?
    end

    # Submit the batch operation in chunks until they are all complete. In general,
    # Parse limits requests in each batch to 50 and it is possible that a {BatchOperation}
    # instance contains more than 50 requests. This method will slice up the array of
    # request and send them based on the `segment` amount until they have all been submitted.
    # @param segment [Integer] the number of requests to send in each batch. Default 50.
    # @return [Array<Parse::Response>] the corresponding set of responses for
    #  each request in the batch.
    def submit(segment = 50, &block)
      @responses = []
      @requests.uniq!(&:signature)
      @responses = @requests.each_slice(segment).to_a.threaded_map(2) do |slice|
        client.batch_request(BatchOperation.new(slice))
      end
      @responses.flatten!
      #puts "Requests: #{@requests.count} == Response: #{@responses.count}"
      @requests.zip(@responses).each(&block) if block_given?
      @responses
    end

    alias_method :save, :submit
  end
end

class Array

  # Submit a batch request for deleting a set of Parse::Objects.
  # @example
  #  # assume Post and Author are Parse models
  #  author = Author.first
  #  posts = Post.all author: author
  #  posts.destroy # batch destroy request
  # @return [Parse::BatchOperation] the batch operation performed.
  # @see Parse::BatchOperation
  def destroy
    batch = Parse::BatchOperation.new
    each do |o|
      next unless o.respond_to?(:destroy_request)
      r = o.destroy_request
      batch.add(r) unless r.nil?
    end
    batch.submit
    batch
  end

  # Do not alias method as :delete is already part of array.
  # alias_method :delete, :destroy

  # Submit a batch request for deleting a set of Parse::Objects.
  # Batch requests are supported implicitly and intelligently through an
  # extension of array. When an array of Parse::Object subclasses is saved,
  # Parse-Stack will batch all possible save operations for the objects in the
  # array that have changed. It will also batch save 50 at a time until all items
  # in the array are saved. Note: Parse does not allow batch saving Parse::User objects.
  # @note The objects of the array to be saved do not all have to be of the same collection.
  # @param merge [Boolean] whether to merge the updated changes to the series of
  #  objects back to the original ones submitted. If you don't need the original objects
  #  to be updated with the changes, set this to false for improved performance.
  # @param force [Boolean] Do not skip objects that do not have pending changes (dirty tracking).
  # @example
  #  # assume Post and Author are Parse models
  #  author = Author.first
  #  posts = Post.first 100
  #  posts.each { |post| post.author = author }
  #  posts.save # batch save
  # @return [Parse::BatchOperation] the batch operation performed.
  # @see Parse::BatchOperation
  def save(merge: true, force: false)
    batch = Parse::BatchOperation.new
    objects = {}
    each do |o|
      next unless o.is_a?(Parse::Object)
      objects[o.object_id] = o
      batch.add o.change_requests(force)
    end
    if merge == false
      batch.submit
      return batch
    end
    #rebind updates
    batch.submit do |request, response|
      next unless request.tag.present? && response.present? && response.success?
      o = objects[request.tag]
      next unless o.is_a?(Parse::Object)
      result = response.result
      o.id = result["objectId"] if o.id.blank?
      o.set_attributes!(result)
      o.clear_changes!
    end
    batch
  end #save!
end
