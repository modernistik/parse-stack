require 'parallel'
require 'active_support'
require 'active_support/core_ext'
class Array

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
      o.id = result['objectId'] if o.id.blank?
      o.set_attributes!(result)
      o.clear_changes!
    end
    batch
  end #save!

end

module Parse

  def self.batch(reqs = nil)
    BatchOperation.new(reqs)
  end

  class BatchOperation
    MAX_REQ_SEC = 25

    attr_accessor :requests, :responses
    include Enumerable

    def client
      @client ||= Parse::Client.session
    end

    def initialize(reqs = nil)
      @requests = []
      @responses = []
      reqs = [reqs] unless reqs.is_a?(Enumerable)
      reqs.each { |r| add(r) } if reqs.is_a?(Enumerable)
    end

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

    # make Batching interoperable with object methods. This allows adding a batch
    # to another batch.
    def change_requests
      @requests
    end

    def each
      return enum_for(:each) unless block_given?
      @requests.each(&Proc.new)
      self
    end

    def as_json(*args)
      { requests:  requests }.as_json
    end

    def count
      @requests.count
    end

    def clear!
      @requests.clear
    end

    def success?
      return false if @responses.empty?
      @responses.compact.all?(&:success?)
    end

    def error?
      return false if @responses.empty?
      ! success?
    end
    # Note that N requests sent in a batch will still count toward
    # your request limit as N requests.
    def submit(segment = 50)
      @responses = []
      @requests.uniq!(&:signature)
      @requests.each_slice(segment) do |slice|
        @responses << client.batch_request( BatchOperation.new(slice) )
        #throttle
        sleep (slice.count.to_f / MAX_REQ_SEC.to_f )
      end
      @responses.flatten!
      #puts "Requests: #{@requests.count} == Response: #{@responses.count}"
      @requests.zip(@responses).each(&Proc.new) if block_given?
      @responses
    end
    alias_method :save, :submit


  end

  module API
    #object fetch methods

    module Batch
      def batch_request(batch_operations)
        unless batch_operations.is_a?(Parse::BatchOperation)
          batch_operations = Parse::BatchOperation.new batch_operations
        end
        response = request(:post, "batch", body: batch_operations.as_json)
        response.success? && response.batch? ? response.batch_responses : response
      end

    end
  end
end
