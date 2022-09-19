![Parse Stack - The Parse Server Ruby Client SDK](https://raw.githubusercontent.com/modernistik/parse-stack/master/parse-stack.png?raw=true)

A full featured Active Model ORM and Ruby REST API for Parse-Server. [Parse Stack](https://github.com/modernistik/parse-stack) is the [Parse Server](http://parseplatform.org/) SDK, REST Client and ORM framework for [Ruby](https://www.ruby-lang.org/en/). It provides a client adapter, a query engine, an object relational mapper (ORM) and a Cloud Code Webhooks rack application.

Below is a [quick start guide](https://github.com/modernistik/parse-stack#overview), but you can also check out the full *[API Reference](https://www.modernistik.com/gems/parse-stack/index.html)* for more detailed information about our Parse Server SDK.

### Hire Us

Interested in our work? You can find us here: [https://www.modernistik.com](https://www.modernistik.com)

### Code Status
[![Gem Version](https://img.shields.io/gem/v/parse-stack.svg)](https://github.com/modernistik/parse-stack)
[![Downloads](https://img.shields.io/gem/dt/parse-stack.svg)](https://rubygems.org/gems/parse-stack)
[![Build Status](https://travis-ci.org/modernistik/parse-stack.svg?branch=master)](https://travis-ci.org/modernistik/parse-stack)
[![API Reference](http://img.shields.io/badge/api-docs-blue.svg)](https://www.modernistik.com/gems/parse-stack/index.html)

#### Tutorial Videos
1. Getting Started: https://youtu.be/zoYSGmciDlQ
2. Custom Classes and Relations: https://youtu.be/tfSesotfU7w
3. Working with Existing Schemas: https://youtu.be/EJGPT7YWyXA

Any other questions, please post them on StackOverflow with the proper parse-stack / parse-server / ruby tags.

## Installation

Add this line to your application's `Gemfile`:
```ruby
gem 'parse-stack'
```
And then execute:
```bash
$ bundle
```
Or install it yourself as:
```bash
$ gem install parse-stack
```
### Rack / Sinatra
Parse-Stack API, models and webhooks easily integrate in your existing Rack/Sinatra based applications. For more details see [Parse-Stack Rack Example](https://github.com/modernistik/parse-stack-example).

### Rails
Parse-Stack comes with support for Rails by adding additional rake tasks and generators. After adding `parse-stack` as a gem dependency in your Gemfile and running `bundle`, you should run the install script:
```bash
$ rails g parse_stack:install
```
For a more details on the rails integration see [Parse-Stack Rails Example](https://github.com/modernistik/parse-stack-rails-example).

### Interactive Command Line Playground
You can also used the bundled `parse-console` command line to connect and interact with your Parse Server and its data in an IRB-like console. This is useful for trying concepts and debugging as it will automatically connect to your Parse Server, and if provided the master key, automatically generate all the models entities.

```bash
$ parse-console -h # see all options
$ parse-console -v -a myAppId -m myMasterKey http://localhost:1337/parse
Server : http://localhost:1337/parse
App Id : myAppId
Master : true
2.4.0 > Parse::User.first
```

## Overview
Parse-Stack is a full stack framework that utilizes several ideas behind [DataMapper](http://datamapper.org/docs/find.html) and [ActiveModel](https://github.com/rails/rails/tree/master/activemodel) to manage and maintain larger scale ruby applications and tools that utilize the [Parse Server Platform](http://parseplatform.org/). If you are familiar with these technologies, the framework should feel familiar to you.

```ruby
require 'parse/stack'

Parse.setup server_url: 'http://localhost:1337/parse',
            app_id: APP_ID,
            api_key: REST_API_KEY,
            master_key: YOUR_MASTER_KEY # optional

# Automatically build models based on your Parse application schemas.
Parse.auto_generate_models!

# or define custom Subclasses (Highly Recommended)
class Song < Parse::Object
  property :name
  property :play, :integer
  property :audio_file, :file
  property :tags, :array
  property :released, :date
  belongs_to :artist
  # `like` is a Parse Relation to User class
  has_many :likes, as: :user, through: :relation

  # deny public write to Song records by default
  set_default_acl :public, read: true, write: false
end

class Artist < Parse::Object
  property :name
  property :genres, :array
  has_many :fans, as: :user
  has_one :manager, as: :user

  scope :recent, ->(x) { query(:created_at.after => x) }
end

# updates schemas for your Parse app based on your models (non-destructive)
Parse.auto_upgrade!

# login
user = Parse::User.login(username, passwd)

artist = Artist.new(name: "Frank Sinatra", genres: ["swing", "jazz"])
artist.fans << user
artist.save

# Query
artist = Artist.first(:name.like => /Sinatra/, :genres.in => ['swing'])

# more examples
song = Song.new name: "Fly Me to the Moon"
song.artist = artist
# Parse files - upload a file and attach to object
song.audio_file = Parse::File.create("http://path_to.mp3")

# relations - find a User matching username and add it to relation.
song.likes.add Parse::User.first(username: "persaud")

# saves both attributes and relations
song.save

# find songs
songs = Song.all(artist: artist, :plays.gt => 100, :released.on_or_after => 30.days.ago)

songs.each { |s| s.tags.add "awesome" }
# batch saves
songs.save

# Call Cloud Code functions
result = Parse.call_function :myFunctionName, {param: value}

```
## Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Architecture](#architecture)
  - [Parse::Client](#parseclient)
  - [Parse::Query](#parsequery)
  - [Parse::Object](#parseobject)
  - [Parse::Webhooks](#parsewebhooks)
- [Field Naming Conventions](#field-naming-conventions)
- [Connection Setup](#connection-setup)
  - [Connection Options](#connection-options)
- [Working With Existing Schemas](#working-with-existing-schemas)
- [Parse Config](#parse-config)
- [Core Classes](#core-classes)
  - [Parse::Pointer](#parsepointer)
  - [Parse::File](#parsefile)
  - [Parse::Date](#parsedate)
  - [Parse::GeoPoint](#parsegeopoint)
    - [Calculating Distances between locations](#calculating-distances-between-locations)
  - [Parse::Bytes](#parsebytes)
  - [Parse::TimeZone](#parsetimezone)
  - [Parse::ACL](#parseacl)
  - [Parse::Session](#parsesession)
  - [Parse::Installation](#parseinstallation)
  - [Parse::Product](#parseproduct)
  - [Parse::Role](#parserole)
  - [Parse::User](#parseuser)
    - [Signup](#signup)
      - [Third-Party Services](#third-party-services)
    - [Login and Sessions](#login-and-sessions)
    - [Linking and Unlinking](#linking-and-unlinking)
    - [Request Password Reset](#request-password-reset)
- [Modeling and Subclassing](#modeling-and-subclassing)
  - [Defining Properties](#defining-properties)
    - [Accessor Aliasing](#accessor-aliasing)
    - [Property Options](#property-options)
      - [`:required`](#required)
      - [`:field`](#field)
      - [`:default`](#default)
      - [`:alias`](#alias)
      - [`:symbolize`](#symbolize)
      - [`:enum`](#enum)
      - [`:scope`](#scope)
  - [Associations](#associations)
    - [Belongs To](#belongs-to)
      - [Options](#options)
        - [`:required`](#required-1)
        - [`:as`](#as)
        - [`:field`](#field-1)
    - [Has One](#has-one)
    - [Has Many](#has-many)
      - [Query](#query)
      - [Array](#array)
      - [Parse Relation](#parse-relation)
      - [Options](#options-1)
        - [`:through`](#through)
        - [`:scope_only`](#scope_only)
- [Creating, Saving and Deleting Records](#creating-saving-and-deleting-records)
  - [Create](#create)
  - [Saving](#saving)
  - [Saving applying User ACLs](#saving-applying-user-acls)
    - [Raising an exception when save fails](#raising-an-exception-when-save-fails)
  - [Modifying Associations](#modifying-associations)
  - [Batch Requests](#batch-requests)
  - [Magic `save_all`](#magic-save_all)
  - [Deleting](#deleting)
- [Fetching, Finding and Counting Records](#fetching-finding-and-counting-records)
  - [Auto-Fetching Associations](#auto-fetching-associations)
- [Advanced Querying](#advanced-querying)
  - [Results Caching](#results-caching)
  - [Counting](#counting)
  - [Distinct Aggregation](#distinct-aggregation)
  - [Query Expressions](#query-expressions)
    - [:order](#order)
    - [:keys](#keys)
    - [:includes](#includes)
    - [:limit](#limit)
    - [:skip](#skip)
    - [:cache](#cache)
    - [:use_master_key](#use_master_key)
    - [:session](#session)
    - [:where](#where)
- [Query Constraints](#query-constraints)
    - [Equals](#equals)
    - [Less Than](#less-than)
    - [Less Than or Equal To](#less-than-or-equal-to)
    - [Greater Than](#greater-than)
    - [Greater Than or Equal](#greater-than-or-equal)
    - [Not Equal To](#not-equal-to)
    - [Nullability Check](#nullability-check)
    - [Exists](#exists)
    - [Contained In](#contained-in)
    - [Not Contained In](#not-contained-in)
    - [Contains All](#contains-all)
    - [Regex Matching](#regex-matching)
    - [Select](#select)
    - [Reject](#reject)
    - [Matches Query](#matches-query)
    - [Excludes Query](#excludes-query)
    - [Matches Object Id](#matches-object-id)
  - [Geo Queries](#geo-queries)
    - [Max Distance Constraint](#max-distance-constraint)
    - [Bounding Box Constraint](#bounding-box-constraint)
    - [Polygon Area Constraint](#polygon-area-constraint)
    - [Full Text Search Constraint](#full-text-search-constraint)
  - [Relational Queries](#relational-queries)
  - [Compound Queries](#compound-queries)
- [Query Scopes](#query-scopes)
- [Calling Cloud Code Functions](#calling-cloud-code-functions)
- [Calling Background Jobs](#calling-background-jobs)
- [Active Model Callbacks](#active-model-callbacks)
- [Schema Upgrades and Migrations](#schema-upgrades-and-migrations)
- [Push Notifications](#push-notifications)
- [Cloud Code Webhooks](#cloud-code-webhooks)
  - [Cloud Code Functions](#cloud-code-functions)
  - [Cloud Code Triggers](#cloud-code-triggers)
  - [Mounting Webhooks Application](#mounting-webhooks-application)
  - [Register Webhooks](#register-webhooks)
- [Parse REST API Client](#parse-rest-api-client)
  - [Request Caching](#request-caching)
- [Contributing](#contributing)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Architecture
The architecture of `Parse::Stack` is broken into four main components.

### [Parse::Client](https://www.modernistik.com/gems/parse-stack/Parse/Client.html)
This class is the core and low level API for the Parse Server REST interface that is used by the other components. It can manage multiple sessions, which means you can have multiple client instances pointing to different Parse Server applications at the same time. It handles sending raw requests as well as providing Request/Response objects for all API handlers. The connection engine is Faraday, which means it is open to add any additional middleware for features you'd like to implement.

### [Parse::Query](https://www.modernistik.com/gems/parse-stack/Parse/Query.html)
This class implements the [Parse REST Querying](http://docs.parseplatform.org/rest/guide/#queries) interface in the [DataMapper finder syntax style](http://datamapper.org/docs/find.html). It compiles a set of query constraints and utilizes `Parse::Client` to send the request and provide the raw results. This class can be used without the need to define models.

### [Parse::Object](https://www.modernistik.com/gems/parse-stack/Parse/Object.html)
This component is main class for all object relational mapping subclasses for your application. It provides features in order to map your remote Parse records to a local ruby object. It implements the Active::Model interface to provide a lot of additional features, CRUD operations, querying, including dirty tracking, JSON serialization, save/destroy callbacks and others. While we are overlooking some functionality, for simplicity, you will mainly be working with Parse::Object as your superclass. While not required, it is highly recommended that you define a model (Parse::Object subclass) for all the Parse classes in your application.

### [Parse::Webhooks](https://www.modernistik.com/gems/parse-stack/Parse/Webhooks.html)
Parse provides a feature called [Cloud Code Webhooks](http://blog.parse.com/announcements/introducing-cloud-code-webhooks/). For most applications, save/delete triggers and cloud functions tend to be implemented by Parse's own hosted Javascript solution called Cloud Code. However, Parse provides the ability to have these hooks utilize your hosted solution instead of their own, since their environment is limited in terms of resources and tools.

## Field Naming Conventions
By convention in Ruby (see [Style Guide](https://github.com/bbatsov/ruby-style-guide#snake-case-symbols-methods-vars)), symbols and variables are expressed in lower_snake_case form. Parse, however, prefers column names in **lower-first camel case** (ex. `objectId`, `createdAt` and `updatedAt`). To keep in line with the style guides between the languages, we do the automatic conversion of the field names when compiling the query. As an additional exception to this rule, the field key of `id` will automatically be converted to the `objectId` field when used. If you do not want this to happen, you can turn off or change the value `Parse::Query.field_formatter` as shown below. Though we recommend leaving the default `:columnize` if possible.

```ruby
# default uses :columnize
query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
query.compile_where # {"fieldOne"=>1, "fieldTwo"=>2, "fieldThree"=>3}

# turn off
Parse::Query.field_formatter = nil
query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
query.compile_where # {"field_one"=>1, "FieldTwo"=>2, "Field_Three"=>3}

# force everything camel case
Parse::Query.field_formatter = :camelize
query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
query.compile_where # {"FieldOne"=>1, "FieldTwo"=>2, "FieldThree"=>3}

```


## Connection Setup
To connect to a Parse server, you will need a minimum of an `application_id`, an `api_key` and a `server_url`. To connect to the server endpoint, you use the `Parse.setup()` method below.

```ruby
  Parse.setup app_id: "YOUR_APP_ID",
              api_key: "YOUR_API_KEY",
              master_key: "YOUR_MASTER_KEY", # optional
              server_url: 'https://localhost:1337/parse' #default
```

If you wish to add additional connection middleware to the stack, you may do so by utilizing passing a block to the setup method.

```ruby
  Parse.setup( ... ) do |conn|
    # conn is a Faraday connection object
    conn.use Your::Middleware
    conn.response :logger
    # ....
  end
```

Calling `setup` will create the default `Parse::Client` session object that will be used for all models and requests in the stack. You may retrive this client by calling the class `client` method. It is possible to create different client connections and have different models point to different Parse applications and endpoints at the same time.

```ruby
  default_client = Parse.client
                   # alias Parse::Client.client(:default)
```

### Connection Options
There are additional connection options that you may pass the setup method when creating a `Parse::Client`.

#### `:server_url`
The server url of your Parse Server if you are not using the hosted Parse service. By default it will use `PARSE_SERVER_URL` environment variable available or fall back to `https://localhost:1337/parse` if not specified.

#### `:app_id`
The Parse application id. By default it will use `PARSE_SERVER_APPLICATION_ID` environment variable if not specified.

#### `:api_key`
The Parse REST API Key. By default it will use `PARSE_SERVER_REST_API_KEY` environment variable if not specified.

#### `:master_key` _(optional)_
The Parse application master key. If this key is set, it will be sent on every request sent by the client and your models. By default it will use `PARSE_SERVER_MASTER_KEY` environment variable if not specified.

#### `:logging`
A true or false value. It provides you additional logging information of requests and responses. If set to the special symbol of `:debug`, it will provide additional payload data in the log messages.

#### `:adapter`
The connection adapter. By default it uses the `Faraday.default_adapter` which is Net/HTTP.

#### `:cache`
A caching adapter of type `Moneta::Transformer`. Caching queries and object fetches can help improve the performance of your application, even if it is for a few seconds. Only successful `GET` object fetches and queries (non-empty) will be cached. You may set the default expiration time with the `expires` option. See related: [Moneta](https://github.com/minad/moneta). At any point in time you may clear the cache by calling the `clear_cache!` method on the client connection.

```ruby
  store = Moneta.new :Redis, url: 'redis://localhost:6379'
   # use a Redis cache store with an automatic expire of 10 seconds.
  Parse.setup(cache: store, expires: 10, ...)
```

As a shortcut, if you are planning on using REDIS and have configured the use of `redis` in your `Gemfile`, you can just pass the REDIS connection string directly to the cache option.

```ruby
  Parse.setup(cache: 'redis://localhost:6379', ...)
```

#### `:expires`
Sets the default cache expiration time (in seconds) for successful non-empty `GET` requests when using the caching middleware. The default value is 3 seconds. If `:expires` is set to 0, caching will be disabled. You can always clear the current state of the cache using the `clear_cache!` method on your `Parse::Client` instance.

#### `:faraday`
You may pass a hash of options that will be passed to the `Faraday` constructor.

## Working With Existing Schemas
If you already have a Parse application with defined schemas and collections, you can have Parse-Stack automatically generate the ruby Parse::Object subclasses instead of writing them on your own. Through this process, the framework will download all the defined schemas of all your collections, and infer the properties and associations defined. While this method is useful for getting started with the framework with an existing app, we highly recommend defining your own models. This would allow you to customize and utilize all the features available in Parse Stack.

```ruby
  # after you have called Parse.setup
  # Assume you have a Song and Artist collections defined remotely
  Parse.auto_generate_models!

  # You can now use them as if you defined them
  artist = Artist.first
  Song.all(artist: artist)
```

You can always combine both approaches by defining special attributes before you auto generate your models:

```ruby
  # create a Song class, but only create the artist array pointer association.
  class Song < Parse::Object
    has_many :artists, through: :array
  end

  # Now let Parse Stack generate the rest of the properties and associations
  # based on your remote schema. Assume there is a `title` field for the `Song`
  # collection.
  Parse.auto_generate_models!

  song = Song.first
  song.artists # created with our definition above
  song.title # auto-generated property

```

## [Parse Config](https://www.modernistik.com/gems/parse-stack/Parse/API/Config.html)
Getting your configuration variables once you have a default client setup can be done with `Parse.config`. The first time this method is called, Parse-Stack will get the configuration from Parse Server, and cache it. To force a reload of the config, use `config!`. You

```ruby
  Parse.setup( ... )

  val = Parse.config["myKey"]
  val = Parse.config["myKey"] # cached

  # update a config with Parse
  Parse.set_config "myKey", "someValue"

  # batch update several
  Parse.update_config({fieldEnabled: true, searchMiles: 50})

  # Force fetch of config!
  val = Parse.config!["myKey"]

```

## Core Classes
While some native data types are similar to the ones supported by Ruby natively, other ones are more complex and require their dedicated classes.

### [Parse::Pointer](https://www.modernistik.com/gems/parse-stack/Parse/Pointer.html)
An important concept is the `Parse::Pointer` class. This is the superclass of `Parse::Object` and represents the pointer type in Parse. A `Parse::Pointer` only contains data about the specific Parse class and the `id` for the object. Therefore, creating an instance of any Parse::Object subclass with only the `:id` field set will be considered in "pointer" state even though its specific class is not `Parse::Pointer` type. The only case that you may have a Parse::Pointer is in the case where an object was received for one of your classes and the framework has no registered class handler for it. Using the example above, assume you have the tables `Post`, `Comment` and `Author` defined in your remote Parse application, but have only defined `Post` and `Commentary` locally.

```ruby
 # assume the following
class Post < Parse::Object
end

class Commentary < Parse::Object
  parse_class "Comment"
	belongs_to :post
	#'Author' class not defined locally
	belongs_to :author
end

comment = Commentary.first
comment.post? # true because it is non-nil
comment.artist? # true because it is non-nil

# both are true because they are in a Pointer state
comment.post.pointer? # true
comment.author.pointer? # true

 # we have defined a Post class handler
comment.post # <Post @parse_class="Post", @id="xdqcCqfngz">

 # we have not defined an Author class handler
comment.author # <Parse::Pointer @parse_class="Author", @id="hZLbW6ofKC">


comment.post.fetch # fetch the relation
comment.post.pointer? # false, it is now a full object.
```

The effect is that for any unknown classes that the framework encounters, it will generate Parse::Pointer instances until you define those classes with valid properties and associations. While this might be ok for some classes you do not use, we still recommend defining all your Parse classes locally in the framework.

### [Parse::File](https://www.modernistik.com/gems/parse-stack/Parse/File.html)
This class represents a Parse file pointer. `Parse::File` has helper methods to upload Parse files directly to Parse and manage file associations with your classes. Using our Song class example:

```ruby
  song = Song.first
  file = song.audio_file # Parse::File
  file.url # URL in the Parse file storage system

  file = File.open("file_path.jpg")
  contents = file.read
  file = Parse::File.new("myimage.jpg", contents , "image/jpeg")
  file.saved? # false. Hasn't been uploaded to Parse
  file.save # uploads to Parse.

  file.url # https://files.parsetfss.com/....

  # or create and upload a remote file (auto-detected mime type)
  file = Parse::File.create(some_url)
  song.file = file
  song.save

```

The default MIME type for all files is `image/jpeg`. This can be default can be changed by setting a value to `Parse::File.default_mime_type`. Other ways of creating a `Parse::File` are provided below. The created Parse::File is not uploaded until you call `save`.

```ruby
  # urls
  file = Parse::File.new "http://example.com/image.jpg"
  file.name # image.jpg

  # file objects
  file = Parse::File.new File.open("myimage.jpg")

  # non-image files work too
  file = Parse::File.new "http://www.example.com/something.pdf"
  file.mime_type = "application/octet-stream" #set the mime-type!

  # or another Parse::File object
  file = Parse::File.new parse_file
```

If you are using displaying these files on a secure site and want to make sure that urls returned by a call to `url` are `https`, you can set `Parse::File.force_ssl` to true.

```ruby
# Assume file is a Parse::File

file.url # => http://www.example.com/file.png

Parse::File.force_ssl = true # make all urls be https

file.url # => https://www.example.com/file.png

```

### [Parse::Date](https://www.modernistik.com/gems/parse-stack/Parse/Date.html)
This class manages dates in the special JSON format it requires for properties of type `:date`. `Parse::Date` subclasses `DateTime`, which allows you to use any features or methods available to `DateTime` with `Parse::Date`. While the conversion between `Time` and `DateTime` objects to a `Parse::Date` object is done implicitly for you, you can use the added special methods, `DateTime#parse_date` and `Time#parse_date`, for special occasions.

```ruby
  song = Song.first
  song.released = DateTime.now # converted to Parse::Date
  song.save # ok
```

### [Parse::GeoPoint](https://www.modernistik.com/gems/parse-stack/Parse/GeoPoint.html)
This class manages the GeoPoint data type that Parse provides to support geo-queries. To define a GeoPoint property, use the `:geopoint` data type. Please note that latitudes should not be between -90.0 and 90.0, and longitudes should be between -180.0 and 180.0.

```ruby
  class PlaceObject < Parse::Object
    property :location, :geopoint
  end

  san_diego = Parse::GeoPoint.new(32.8233, -117.6542)
  los_angeles = Parse::GeoPoint.new [34.0192341, -118.970792]
  san_diego == los_angeles # false

  place = PlaceObject.new
  place.location = san_diego
  place.save
```

#### Calculating Distances between locations
We include helper methods to calculate distances between GeoPoints: `distance_in_miles` and `distance_in_km`.

```ruby
	san_diego = Parse::GeoPoint.new(32.8233, -117.6542)
	los_angeles = Parse::GeoPoint.new [34.0192341, -118.970792]

	# Haversine calculations
	san_diego.distance_in_miles(los_angeles)
	# ~112.33 miles

	san_diego.distance_in_km(los_angeles)
	# ~180.793 km
```

### [Parse::Bytes](https://www.modernistik.com/gems/parse-stack/Parse/Bytes.html)
The `Bytes` data type represents the storage format for binary content in a Parse column. The content is needs to be encoded into a base64 string.

```ruby
  bytes = Parse::Bytes.new( base64_string )
  # or use helper method
  bytes = Parse::Bytes.new
  bytes.encode( content ) # same as Base64.encode64

  decoded = bytes.decoded # same as Base64.decode64
```

### [Parse::TimeZone](https://www.modernistik.com/gems/parse-stack/Parse/TimeZone.html)
While Parse does not provide a native time zone data type, Parse-Stack provides a class to make it easier to manage time zone attributes, usually stored IANA string identifiers, with your ruby code. This is done by utilizing the features provided by [`ActiveSupport::TimeZone`](http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html). In addition to setting a column as a time zone field, we also add special validations to verify it is of the right IANA identifier.

```ruby
class Event < Parse::Object
  # an event occurs in a time zone.
  property :time_zone, :timezone, default: 'America/Los_Angeles'
end

event = Event.new
event.time_zone.name # => 'America/Los_Angeles'
event.time_zone.valid? # => true

event.time_zone.zone # => ActiveSupport::TimeZone
event.time_zone.formatted_offset # => "-08:00"

event.time_zone = 'Europe/Paris'
event.time_zone.formatted_offset # => +01:00"

event.time_zone = 'Galaxy/Andromeda'
event.time_zone.valid? # => false
```

### [Parse::ACL](https://www.modernistik.com/gems/parse-stack/Parse/ACL.html)
The `ACL` class represents the access control lists for each record. An ACL is represented by a JSON object with the keys being `Parse::User` object ids or the special key of `*`, which indicates the public access permissions.
The value of each key in the hash is a [`Parse::ACL::Permission`](https://www.modernistik.com/gems/parse-stack/Parse/ACL/Permission.html) object which defines the boolean permission state for `read` and `write`.

The example below illustrates a Parse ACL JSON object where there is a public read permission, but public write is prevented. In addition, the user with id `3KmCvT7Zsb` and the `Admins` role, are allowed to both read and write on this record.

```json
{
  "*": { "read": true },
  "3KmCvT7Zsb": {  "read": true, "write": true },
  "role:Admins": {  "read": true, "write": true }
}
```

All `Parse::Object` subclasses have an `acl` property by default. With this property, you can apply and delete permissions for this particular Parse object record.

```ruby
  user = Parse::User.first
  artist = Artist.first

  artist.acl # "*": { "read": true, "write": true }

  # apply public read, but no public write
  artist.acl.everyone true, false

  # allow user to have read and write access
  artist.acl.apply user.id, true, true

  # remove all permissions for this user id
  artist.acl.delete user.id

  # allow the 'Admins' role read and write
  artist.acl.apply_role "Admins", true, true

  # remove write from all attached privileges
  artist.acl.no_write!

  # remove all attached privileges
  artist.acl.master_key_only!

  artist.save
```
You may also set default ACLs for newly created instances of your subclasses using `set_default_acl`:

```ruby
class AdminData < Parse::Object

  # Disable public read and write
  set_default_acl :public, read: false, write: false

  # but allow members of the Admin role to read and write
  set_default_acl 'Admin', role: true, read: true, write: true

end

data = AdminData.new
data.acl # => ACL({"role:Admin"=>{"read"=>true, "write"=>true}})
```

For more information about Parse record ACLs, see the documentation at  [Security](http://docs.parseplatform.org/rest/guide/#security)

## Builtin parse collections

These classes match parse builtin collections. Do not redeclare them as rails autoloader don't support multiple class declarations. To add properties and methods to these classes, properly reopen them with overrides, using this class_eval method.

First, append this to config/application.rb

```ruby
##
# Don't autoload overrides but preload them instead
    overrides = "#{Rails.root}/app/overrides"
    Rails.autoloaders.main.ignore(overrides)

    config.to_prepare do
      Dir.glob("#{overrides}/**/*_override.rb").each do |override|
        load override
      end
    end
```

Then, create the folder app/overrides/models. Create a file named [collection]_override.rb in this folder to reopen one of these classes. Example with the _User collection:

```ruby
# app/overrides/models/user_override.rb
Parse::User.class_eval do
  has_many :created_articles, as: :articles, field: :creator

  property :first_name
  property :last_name
  property :picture
end
```


### [Parse::Session](https://www.modernistik.com/gems/parse-stack/Parse/Session.html)
This class represents the data and columns contained in the standard Parse `_Session` collection. You may add additional properties and methods to this class. See [Session API Reference](https://www.modernistik.com/gems/parse-stack/Parse/Session.html). You may call `Parse.use_shortnames!` to use `Session` in addition to `Parse::Session`.

You can get a specific `Parse::Session` given a session_token by using the `session` method. You can also find the user tied to a specific Parse session or session token with `Parse::User.session`.

```ruby
session = Parse::Session.session(token)

session.user # the Parse user for this session

# or fetch user with a session token
user = Parse::User.session(token)

# save an object with the privileges (ACLs) of this user
some_object.save( session: user.session_token )

# delete an object with the privileges of this user
some_object.destroy( session: user.session_token )

```

### [Parse::Installation](https://www.modernistik.com/gems/parse-stack/Parse/Installation.html)
This class represents the data and columns contained in the standard Parse `_Installation` collection. You may add additional properties and methods to this class. See [Installation API Reference](https://www.modernistik.com/gems/parse-stack/Parse/Installation.html). You may call `Parse.use_shortnames!` to use `Installation` in addition to `Parse::Installation`.

### [Parse::Product](https://www.modernistik.com/gems/parse-stack/Parse/Product.html)
This class represents the data and columns contained in the standard Parse `_Product` collection. You may add additional properties and methods to this class. See [Product API Reference](https://www.modernistik.com/gems/parse-stack/Parse/Product.html). You may call `Parse.use_shortnames!` to use `Product` in addition to `Parse::Product`.

### [Parse::Role](https://www.modernistik.com/gems/parse-stack/Parse/Role.html)
This class represents the data and columns contained in the standard Parse `_Role` collection. You may add additional properties and methods to this class. See [Roles API Reference](https://www.modernistik.com/gems/parse-stack/Parse/Role.html). You may call `Parse.use_shortnames!` to use `Role` in addition to `Parse::Role`.

### [Parse::User](https://www.modernistik.com/gems/parse-stack/Parse/User.html)
This class represents the data and columns contained in the standard Parse `_User` collection. You may add additional properties and methods to this class. See [User API Reference](https://www.modernistik.com/gems/parse-stack/Parse/User.html). You may call `Parse.use_shortnames!` to use `User` in addition to `Parse::User`.

#### Signup
You can signup new users in two ways. You can either use a class method `Parse::User.signup` to create a new user with the minimum fields of username, password and email, or create a `Parse::User` object can call the `signup!` method. If signup fails, it will raise the corresponding exception.

```ruby
user = Parse::User.signup(username, password, email)

#or
user = Parse::User.new username: "user", password: "s3cret"
user.signup!
```

##### Third-Party Services
You can signup users using third-party services like Facebook and Twitter as described in: [Signing Up and Logging In](http://docs.parseplatform.org/rest/guide/#signing-up). To do this with Parse-Stack, you can call the `Parse::User.autologin_service` method by passing the service name and the corresponding authentication hash data. For a listing of supported third-party authentication services, see [OAuth](http://docs.parseplatform.org/parse-server/guide/#oauth-and-3rd-party-authentication).

```ruby
fb_auth = {}
fb_auth[:id] = "123456789"
fb_auth[:access_token] = "SaMpLeAAiZBLR995wxBvSGNoTrEaL"
fb_auth[:expiration_date] = "2025-02-21T23:49:36.353Z"

# signup or login a user with this auth data.
user = Parse::User.autologin_service(:facebook, fb_auth)
```

You may also combine both approaches of signing up a new user with a third-party service and set additional custom fields. For this, use the method `Parse::User.create`.

```ruby
# or to signup a user with additional data, but linked to Facebook
data = {
  username: "johnsmith",
  name: "John",
  email: "user@example.com",
  authData: { facebook: fb_auth }
}
user = Parse::User.create data
```

#### Login and Sessions
With the `Parse::User` class, you can also perform login and logout functionality. The class special accessors for `session_token` and `session` to manage its authentication state. This will allow you to authenticate users as well as perform Parse queries as a specific user using their session token. To login a user, use the `Parse::User.login` method by supplying the corresponding username and password, or if you already have a user record, use `login!` with the proper password.

```ruby
user = Parse::User.login(username,password)
user.session_token # session token from a Parse::Session
user.session # Parse::Session tied to the token

 # You can login user records
user = Parse::User.first
user.session_token # nil

passwd = 'p_n7!-e8' # corresponding password
user.login!(passwd) # true

user.session_token # 'r:pnktnjyb996sj4p156gjtp4im'

 # logout to delete the session
user.logout
```

If you happen to already have a valid session token, you can use it to retrieve the corresponding Parse::User.

```ruby
# finds user with session token
user = Parse::User.session(session_token)

user.logout # deletes the corresponding session
```

#### Linking and Unlinking
You can link or unlink user accounts with third-party services like Facebook and Twitter as described in: [Linking and Unlinking Users](http://docs.parseplatform.org/rest/guide/#linking-users). To do this, you must first get the corresponding authentication data for the specific service, and then apply it to the user using the linking and unlinking methods. Each method returns true or false if the action was successful. For a listing of supported third-party authentication services, see [OAuth](http://docs.parseplatform.org/parse-server/guide/#oauth-and-3rd-party-authentication).

```ruby

user = Parse::User.first

fb_auth = { ... } # Facebook auth data

# Link this user's Facebook account with Parse
user.link_auth_data! :facebook, fb_auth

# Unlinks this user's Facebook account from Parse
user.unlink_auth_data! :facebook
```

#### Request Password Reset
You can reset a user's password using the `Parse::User.request_password_reset` method.

```ruby
user = Parse::User.first

# pass a user object
Parse::User.request_password_reset user
# or email
Parse::User.request_password_reset("user@example.com")
```


## Modeling and Subclassing
For the general case, your Parse classes should inherit from `Parse::Object`. `Parse::Object` utilizes features from `ActiveModel` to add several features to each instance of your subclass. These include `Dirty`, `Conversion`, `Callbacks`, `Naming` and `Serializers::JSON`.

To get started use the `property` and `has_many` methods to setup declarations for your fields. Properties define literal values that are columns in your Parse class. These can be any of the base Parse data types. You will not need to define classes for the basic Parse class types - this includes "\_User", "\_Installation", "\_Session" and "\_Role". These are mapped to `Parse::User`, `Parse::Installation`, `Parse::Session` and `Parse::Role` respectively.

To get started, you define your classes based on `Parse::Object`. By default, the name of the class is used as the name of the remote Parse class. For a class `Post`, we will assume there is a remote camel-cased Parse table called `Post`. If you need to map the local class name to a different remote class, use the `parse_class` method.

```ruby
class Post < Parse::Object
	# assumes Parse class "Post"
end

class Commentary < Parse::Object
	# set remote class "Comment"
	parse_class "Comment"
end
```

### Defining Properties
Properties are considered a literal-type of association. This means that a defined local property maps directly to a column name for that remote Parse class which contain the value. **All properties are implicitly formatted to map to a lower-first camelcase version in Parse (remote).** Therefore a local property defined as `like_count`, would be mapped to the remote column of `likeCount` automatically. The only special behavior to this rule is the `:id` property which maps to `objectId` in Parse. This implicit conversion mapping is the default behavior, but can be changed on a per-property basis. All Parse data types are supported and all Parse::Object subclasses already provide definitions for `:id` (objectId), `:created_at` (createdAt), `:updated_at` (updatedAt) and `:acl` (ACL) properties.

- **:string** (_default_) - a generic string. Can be used as an enum field, see [Enum](#enum).
- **:integer** (alias **:int**) - basic number. Will also generate atomic `_increment!` helper method.
- **:float** - a floating numeric value. Will also generate atomic `_increment!` helper method.
- **:boolean** (alias **:bool**) - true/false value. This will also generate a class scope helper. See [Query Scopes](#query-scopes).
- **:date** - a Parse date type. See [Parse::Date](#parsedate).
- **:timezone** - a time zone object. See [Parse::TimeZone](#parsetimezone).
- **:array** - a heterogeneous list with dirty tracking. See [Parse::CollectionProxy](https://github.com/modernistik/parse-stack/blob/master/lib/parse/model/associations/collection_proxy.rb).
- **:file** - a Parse file type. See [Parse::File](#parsefile).
- **:geopoint** - a GeoPoint type. See [Parse::GeoPoint](#parsegeopoint).
- **:bytes** - a Parse bytes data type managed as base64. See [Parse::Bytes](#parsebytes).
- **:object** - an object "hash" data type. See [ActiveSupport::HashWithIndifferentAccess](http://apidock.com/rails/ActiveSupport/HashWithIndifferentAccess).

For completeness, the `:id` and `:acl` data types are also defined in order to handle the Parse `objectId` field and the `ACL` object. Those are special and should not be used in your class (unless you know what you are doing). New data types can be implemented through the internal `typecast` interface. **TODO: discuss `typecast` interface in the future**

When declaring a `:boolean` data type, it will also create a special method that uses the `?` convention. As an example, if you have a property named `approved`, the normal getter `obj.approved` can return true, false or nil based on the value in Parse. However with the `obj.approved?` method, it will return true if it set to true, false for any other value.

When declaring an `:integer` or `:float` type, it will also create a special method that performs
an atomic increment of that field through the `_increment!` and `_decrement!` methods. If you have
defined a property named `like_count` for one of these numeric types, which would create the normal getter/setter `obj.like_count`; you can now also call `obj.like_count_increment!` or `obj.like_count_decrement!` to perform the atomic operations (done server side) on this field. You may also pass an amount as an argument to these helper methods such as `obj.like_count_increment!(3)`.

Using the example above, we can add the base properties to our classes.

```ruby
class Post < Parse::Object
  property :title
  property :content, :string # explicit

  # treat the values of this field as symbols instead of strings.
  property :category, :string, symbolize: true

  # maybe a count of comments.
  property :comment_count, :integer, default: 0

  # use lambda to access the instance object.
  # Set draft_date to the created_at date if empty.
  property :draft_date, :date, default: lambda { |x| x.created_at }
  # the published date. Maps to "publishDate"
  property :publish_date, :date, default: lambda { |x| DateTime.now }

  # maybe whether it is currently visible
  property :visible, :boolean

  # a list using
  property :tags, :array

  # string column as enumerated type. see :enum
  property :status, enum: [:active, :archived]

  # Maps to "featuredImage" column representing a File.
  property :featured_image, :file

  property :location, :geopoint

  # Support bytes
  property :data, :bytes

  # A field that contains time zone information (ex. 'America/Los_Angeles')
  property :time_zone, :timezone

  # store SEO information. Make sure we map it to the column
  # "SEO", otherwise it would have implicitly used "seo"
  # as the remote column name
  property :seo, :object, field: "SEO"
end
```

After properties are defined, you can use appropriate getter and setter methods to modify the values. As properties become modified, the model will keep track of the changes using the [dirty tracking feature of ActiveModel](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html). If an attribute is modified in-place then make use of **[attribute_name]_will_change!** to mark that the attribute is changing. Otherwise ActiveModel can't track changes to in-place attributes.

To support dirty tracking on properties of data type of `:array`, we utilize a proxy class called `Parse::CollectionProxy`. This class has special functionality which allows lazy loading of content as well and keeping track of the changes that are made. While you are able to access the internal array on the collection through the `#collection` method, it is important not to make in-place edits to the object. You should use the preferred methods of `#add` and `#remove` to modify the contents of the collection. When `#save` is called on the object, the changes will be committed to Parse.

```ruby
post = Post.first
post.tags.each do |tag|
  puts tag
end
post.tags.empty? # false
post.tags.count # 3
array = post.tags.to_a # get array

# Add
post.tags.add "music", "tech"
post.tags.remove "stuff"
post.save # commit changes
```

#### Accessor Aliasing
To enable easy conversion between incoming Parse attributes, which may be different than the locally labeled attribute, we make use of aliasing accessors with their remote field names. As an example, for a `Post` instance and its `publish_date` property, it would have an accessor defined for both `publish_date` and `publishDate` (or whatever value you passed as the `:field` option) that map to the same attribute. We highly discourage turning off this feature, but if you need to, you can pass the value of `false` to the `:alias` option when defining the property.

```ruby
 # These are equivalent
post.publish_date = DateTime.now
post.publishDate = DateTime.now
post.publish_date == post.publishDate

post.seo # ok
post.SEO # the alias method since 'field: "SEO"'
```

#### Property Options
These are the supported options when defining properties. Parse::Objects are backed by `ActiveModel`, which means you can add additional validations and features supported by that library.

##### `:required`
A boolean property. This option provides information to the property builder that it is a required property. The requirement is not strongly enforced for a save, which means even though the value for the property may not be present, saves and updates can be successfully performed. However, the setting `required` to true, it will set some ActiveModel validations on the property to be used when calling `valid?`. By default it will add a `validates_presence_of` for the property key. If the data type of the property is either `:integer` or `:float`, it will also add a `validates_numericality_of` validation. Default `false`.

##### `:field`
This option allows you to set the name of the remote column for the Parse table. Using this will explicitly set the remote property name to the value of this option. The value provided for this option will affect the name of the alias method that is generated when `alias` option is used. **By default, the name of the remote column is the lower-first camelcase version of the property name. As an example, for a property with key `:my_property_name`, the framework will implicitly assume that the remote column is `myPropertyName`.**

##### `:default`
This option provides you to set a default value for a specific property when the getter accessor method is used and the internal value of the instance object's property is nil. It can either take a literal value or a Proc/lambda.

```ruby
class SomeClass < Parse::Object
	# default value
	property :category, default: "myValue"
	# default value Proc style
	property :date, default: lambda { |x| DateTime.now }
end
```

##### `:alias`
A boolean property. It is highly recommended that this is set to true, which is the default. This option allows for the generation of the additional accessors with the value of `:field`. By allowing two accessors methods, aliased to each other, allows for easier importing and automatic object instantiation based on Parse object JSON data into the Parse::Object subclass.

##### `:symbolize`
A boolean property. This option is only available for fields with data type of `:string`. This allows you to utilize the values for this property as symbols instead of the literal strings, which is Parse's storage format. This feature is useful if a particular property represents a set of enumerable states described in string form. As an example, if you have a `Post` object which has a set of publish states stored in Parse as "draft","scheduled", and "published" - we can use ruby symbols to make our code easier.

```ruby
class Post < Parse::Object
	property :state, :string, symbolize: true
end

post = Post.first
 # the value returned is auto-symbolized
if post.state == :draft
	# will be converted to string when updated in Parse
	post.state = :published
	post.save
end
```

##### `:enum`
The enum option allows you to define an array of possible values that the particular `:string` property should hold. This feature has similarities in the methods and accessors generated for you as described in [ActiveRecord::Enum](http://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html). Using the example in that documentation:

```ruby
class Conversation < Parse::Object
  property :status, enum: [ :active, :archived ]
end

Conversation.statuses # => [ :active, :archived ]

# named scopes
Conversation.active # where status: :active
Conversation.archived(limit: 10) # where status: :archived, limit 10

conversation.active! # sets status to active!
conversation.active? # => true
conversation.status  # => :active

conversation.archived!
conversation.archived? # => true
conversation.status    # => :archived

# equivalent
conversation.status = "archived"
conversation.status = :archived

# allowed by the setter
conversation.status = :banana
conversation.status_valid? # => false

```

Similar to [ActiveRecord::Enum](http://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html), you can use the `:_prefix` or `:_suffix` options when you need to define multiple enums with same values. If the passed value is true, the methods are prefixed/suffixed with the name of the enum. It is also possible to supply a custom value:

```ruby
class Conversation < Parse::Object
  property :status, enum: [:active, :archived], _suffix: true
  property :comments_status, enum: [:active, :inactive], _prefix: :comments
  # combined
  property :discussion, enum: [:casual, :business], _prefix: :talk, _suffix: true
end

Conversation.statuses # => [:active, :archived]
Conversation.comments # => [:active, :inactive]
Conversation.talks # => [:casual, :business]

# affects scopes names
Conversation.archived_status
Conversation.comments_inactive
Conversation.business_talk

conversation.active_status!
conversation.archived_status? # => false

conversation.status = :banana
conversation.valid_status? # => false

conversation.comments_inactive!
conversation.comments_active? # => false

conversation.casual_talk!
conversation.business_talk? # => false
```

##### `:scope`
A boolean property. For some data types like `:boolean` and enums, some [query scopes](#query-scopes) are generated to more easily query data. To prevent generating these scopes for a particular property, set this value to `false`.

### Associations
Parse supports a three main types of relational associations. One type of relation is the `One-to-One` association. This is implemented through a specific column in Parse with a Pointer data type. This pointer column, contains a local value that refers to a different record in a separate Parse table. This association is implemented using the `:belongs_to` feature. The second association is of `One-to-Many`. This is implemented is in Parse as a Array type column that contains a list of of Parse pointer objects. It is recommended by Parse that this array does not exceed 100 items for performance reasons. This feature is implemented using the `:has_many` operation with the plural name of the local Parse class. The last association type is a Parse Relation. These can be used to implement a large `Many-to-Many` association without requiring an explicit intermediary Parse table or class. This feature is also implemented using the `:has_many` method but passing the option of `:relation`.

#### Belongs To
This association creates a one-to-one association with another Parse model. This association says that this class contains a foreign pointer column which references a different class. Utilizing the `belongs_to` method in defining a property in a Parse::Object subclass sets up an association between the local table and a foreign table. Specifying the `belongs_to` in the class, tells the framework that the Parse table contains a local column in its schema that has a reference to a record in a foreign table. The argument to `belongs_to` should be the singularized version of the foreign Parse::Object class. you should specify the foreign table as the snake_case singularized version of the foreign table class. It is important to note that the reverse relationship is not generated automatically.

```ruby
class Author < Parse::Object
	property :name
end

class Comment < Parse::Object
	belongs_to :user # Parse::User
end

class Post < Parse::Object
	belongs_to :author
end

post = Post.first
 # Follow the author pointer and get name
post.author.name

other_author = Author.first
 # change author by setting new pointer
post.author = other_author
post.save
```

##### Options
You can override some of the default functionality when creating both `belongs_to`, `has_one` and `has_many` associations.

###### `:required`
A boolean property. Setting the requirement, automatically creates an ActiveModel validation of `validates_presence_of` for the association. This will not prevent the save, but affects the validation check when `valid?` is called on an instance. Default is false.

###### `:as`
This option allows you to override the foreign Parse class that this association refers while allowing you to have a different accessor name. As an example, you may have a class `Band` which has a `manager` who is of type `Parse::User` and a set of band members, represented by the class `Artist`. You can override the default casting class as follows:

```ruby
 # represents a member of a band or group
class Artist < Parse::Object
end

class Band < Parse::Object
	belongs_to :manager, as: :user
	belongs_to :lead_singer, as: :artist
	belongs_to :drummer, as: :artist
end

band = Band.first
band.manager # Parse::User object
band.lead_singer # Artist object
band.drummer # Artist object
```

###### `:field`
This option allows you to set the name of the remote Parse column for this property. Using this will explicitly set the remote property name to the value of this option. The value provided for this option will affect the name of the alias method that is generated when `alias` option is used. **By default, the name of the remote column is the lower-first camel case version of the property name. As an example, for a property with key `:my_property_name`, the framework will implicitly assume that the remote column is `myPropertyName`.**

#### [Has One](https://www.modernistik.com/gems/parse-stack/Parse/Associations/HasOne.html)
The `has_one` creates a one-to-one association with another Parse class. This association says that the other class in the association contains a foreign pointer column which references instances of this class. If your model contains a column that is a Parse pointer to another class, you should use `belongs_to` for that association instead.

Defining a `has_one` property generates a helper query method to fetch a particular record from a foreign class. This is useful for setting up the inverse relationship accessors of a `belongs_to`. In the case of the `has_one` relationship, the `:field` option represents the name of the column of the foreign class where the Parse pointer is stored. By default, the lower-first camel case version of the Parse class name is used.

In the example below, a `Band` has a local column named `manager` which has a pointer to a `Parse::User` record. This setups up the accessor for `Band` objects to access the band's manager.

```ruby
# every band has a manager
class Band < Parse::Object
	belongs_to :manager, as: :user
end

band = Band.first id: '12345'
# the user represented by this manager
user = band.manger

```

Since we know there is a column named `manager` in the `Band` class that points to a single `Parse::User`, you can setup the inverse association read accessor in the `Parse::User` class. Note, that to change the association, you need to modify the `manager` property on the band instance since it contains the `belongs_to` property.

```ruby
# every user manages a band
class Parse::User
  # inverse relationship to `Band.belongs_to :manager`
  has_one :band, field: :manager
end

user = Parse::User.first
# use the generated has_one accessor `band`.
user.band # similar to query: Band.first(:manager => user)

```

You may optionally use `has_one` with scopes, in order to fine tune the query result. Using the example above, you can customize the query with a scope that only fetches the association if the band is approved. If the association cannot be fetched, `nil` is returned.

```ruby
# adding to previous example
class Band < Parse::Object
  property :approved, :boolean
  property :approved_date, :date
end

# every user manages a band
class Parse::User
  has_one :recently_approved, ->{ where(order: :approved_date.desc) }, field: :manager, as: :band
  has_one :band_by_status, ->(status) { where(approved: status) },  field: :manager, as: :band
end

# gets the band most recently approved
user.recently_approved
# equivalent: Band.first(manager: user, order: :approved_date.desc)

# fetch the managed band that is not approved
user.band_by_status(false)
# equivalent: Band.first(manager: user, approved: false)

```

#### [Has Many](https://www.modernistik.com/gems/parse-stack/Parse/Associations/HasMany.html)
Parse has many ways to implement one-to-many and many-to-many associations: `Array`, `Parse Relation` or through a `Query`. How you decide to implement your associations, will affect how `has_many` works in Parse-Stack. Parse natively supports one-to-many and many-to-many relationships using `Array` and `Relations`, as described in [Relational Data](http://docs.parseplatform.org/js/guide/#relational-data). Both of these methods require you define a specific column type in your Parse table that will be used to store information about the association.

In addition to `Array` and `Relation`, Parse-Stack also implements the standard `has_many` behavior prevalent in other frameworks through a query where the associated class contains a foreign pointer to the local class, usually the inverse of a `belongs_to`. This requires that the associated class has a defined column
that contains a pointer the refers to the defining class.

##### Query
In this implementation, a `has_many` association for a Parse class requires that another Parse class will have a foreign pointer that refers to instances of this class. This is the standard way that `has_many` relationships work in most databases systems. This is usually the case when you have a class that has a `belongs_to` relationship to instances of the local class.

In the example below, many songs belong to a specific artist. We set this association by setting `:belongs_to` relationship from `Song` to `Artist`. Knowing there is a column in `Song` that points to instances of an `Artist`, we can setup a `has_many` association to `Song` instances in the `Artist` class. Doing so will generate a helper query method on the `Artist` instance objects.

```ruby
class Song < Parse::Object
  property :released, :date
  # this class will have a pointer column to an Artist
  belongs_to :artist
end

class Artist < Parse::Object
  has_many :songs
end

artist = Artist.first

artist.songs # => [all songs belonging to artist]
# equivalent: Song.all(artist: artist)

# filter also by release date
artist.songs(:released.after => 1.year.ago)
# equivalent: Song.all(artist: artist, :released.after => 1.year.ago)

```

In order to modify the associated objects (ex. `songs`), you must modify their corresponding `belongs_to` field (in this case `song.artist`), to another record and save it.

Options for `has_many` using this approach are `:as` and `:field`. The `:as` option behaves similarly to the `:belongs_to` counterpart. The `:field` option can be used to override the derived column name located in the foreign class. The default value for `:field` is the columnized version of the Parse subclass `parse_class` method.

```ruby
class Parse::User
  # since the foreign column name is :agent
  has_many :artists, field: :agent
end

class Artist < Parse::Object
  belongs_to :manager, as: :user, field: :agent
end

artist.manager # => Parse::User object

user.artists # => [artists where :agent column is user]
```

When using this approach, you may also employ the use of scopes to filter the particular data from the `has_many` association.

```ruby
class Artist
  has_many :songs, ->(timeframe) { where(:created_at.after => timeframe) }
end

artist.songs(6.months.ago)
# => [artist's songs created in the last 6 months]

```

You may also call property methods in your scopes related to the local class. You also have access to the instance object for the local class through a special `:i` method in the scope.

```ruby
class Concert
  property :city
  belongs_to :artist
end

class Artist
  property :hometown
  has_many :local_concerts, -> { where(:city => hometown) }, as: :concerts
end

# assume
artist.hometown = "San Diego"

# artist's concerts in their hometown of 'San Diego'
artist.local_concerts
# equivalent: Concert.all(artist: artist, city: artist.hometown)

```

##### Array
In this implementation, you can designate a column to be of `Array` type that contains a list of Parse pointers. Parse-Stack supports this by passing the option `through: :array` to the `has_many` method. If you use this approach, it is recommended that this is used for associations where the quantity is less than 100 in order to maintain query and fetch performance. You would be in charge of maintaining the array with the proper list of Parse pointers that are associated to the object. Parse-Stack does help by wrapping the array in a [Parse::PointerCollectionProxy](https://github.com/modernistik/parse-stack/blob/master/lib/parse/model/associations/pointer_collection_proxy.rb) which provides dirty tracking.

```ruby
class Artist < Parse::Object
end

class Band < Parse::Object
	has_many :artists, through: :array
end

artist = Artist.first

# find all bands that contain this artist
bands = Band.all( :artists.in => [artist.pointer] )

band = bands.first
band.artists # => [array of Artist pointers]

# remove artists
band.artists.remove artist

# add artist
band.artists.add artist

# save changes
band.save
```

##### Parse Relation
Other than the use of arrays, Parse supports native one-to-many and many-to-many associations through what is referred to as a [Parse Relation](http://docs.parseplatform.org/js/guide/#many-to-many-relationships). This is implemented by defining a column to be of type `Relation` which refers to a foreign class. Parse-Stack supports this by passing the `through: :relation` option to the `has_many` method. Designating a column as a Parse relation to another class type, will create a one-way intermediate "join-list" between the local class and the foreign class. One important distinction of this compared to other types of data stores (ex. PostgresSQL) is that:

1. The inverse relationship association is not available automatically. Therefore, having a column of `artists` in a `Band` class that relates to members of the band (as `Artist` class), does not automatically make a set of `Band` records available to `Artist` records for which they have been related. If you need to maintain both the inverse relationship between a foreign class to its associations, you will need to manually manage that by adding two Parse relation columns in each class, or by creating a separate class (ex. `ArtistBands`) that is used as a join table.
2. Querying the relation is actually performed against the implicit join table, not the local one.
3. Applying query constraints for a set of records within a relation is performed against the foreign table class, not the class having the relational column.

The Parse documentation provides more details on associations, see [Parse Relations Guide](http://docs.parseplatform.org/ios/guide/#relations). Parse-Stack will handle the work for (2) and (3) automatically.

In the example below, a `Band` can have thousands of `Fans`. We setup a `Relation<Fan>` column in the `Band` class that references the `Fan` class. Parse-Stack provides methods to manage the relationship under the [Parse::RelationCollectionProxy](https://github.com/modernistik/parse-stack/blob/master/lib/parse/model/associations/relation_collection_proxy.rb) class.

```ruby

class Fan < Parse::Object
  # .. lots of properties ...
	property :location, :geopoint
end

class Band < Parse::Object
	has_many :fans, through: :relation 
end

band = Band.first

 # the number of fans in the relation
band.fans.count

# get the first object in relation
fan = bands.fans.first # => Parse::User object

# use `add` or `remove` to modify relations
band.fans.add user
band.fans.add_unique user # no op
bands.fans.remove user

# updates the relation as well as changes to `band`
band.fans.save

# Find 50 fans who are near San Diego, CA
downtown = Parse::GeoPoint.new(32.82, -117.23)
fans = band.fans.all :location.near => downtown

```

You can perform atomic additions and removals of objects from `has_many` relations. Parse allows this by providing a specific atomic operation request. You can use the methods below to perform these types of atomic operations. __Note: The operation is performed directly on Parse server and not on your instance object.__

```ruby

# atomically add/remove
band.artists.add! objects  # { __op: :AddUnique }
band.artists.remove! objects  # { __op: :AddUnique }

# atomically add unique Artist
band.artists.add_unique! objects  # { __op: :AddUnique }

# atomically add/remove relations
band.fans.add! users # { __op: :Add }
band.fans.remove! users # { __op: :Remove }

# atomically perform a delete operation on this field name
# this should set it as `undefined`.
band.op_destroy!("category") # { __op: :Delete }

```

You can also perform queries against class entities to find related objects. Assume
that users can like a band. The `Band` class can have a `likes` column that is
a Parse relation to the `Parse::User` class containing the users who have liked a
specific band.

```ruby
  # assume the schema
  class Band < Parse::Object
    # likes is a Parse relation column of user objects.
    has_many :likes, through: :relation, as: :user
  end
```

You can now find all `Parse::User` records that have "liked" a specific band. *In the
example below, the `:likes` key refers to the `likes` column defined in the `Band`
collection which contains the set of user records.*

```ruby
  band = Band.first # get a band
  # find all users who have liked this band, where :likes is a column
  # in the Band collection - NOT in the User collection.
  users = Parse::User.all :likes.related_to => band

  # or use the relation accessor in band. It is equivalent since Band is
  # declared with a :has_many association.
  band.likes.all # => array of Parse::Users who liked the band
```
You can also find all bands that a specific user has liked.

```ruby
  user = Parse::User.first
  # find all bands where this user is contained in the `likes` Parse relation column
  # of the Band collection
  bands_liked_by_user = Band.all :likes => user
```

##### Options
Options for `has_many` are the same as the `belongs_to` counterpart with support for `:required`, `:as` and `:field`. It has these additional options.

###### `:through`
This sets the type of the `has_many` relation whose possible values are `:array`, `:relation` or `:query` (implicit default). If set to `:array`, it defines the column in Parse as being an array of Parse pointer objects and will be managed locally using a `Parse::PointerCollectionProxy`. If set to `:relation`, it defines a column of type Parse Relation with the foreign class and will be managed locally using a `Parse::RelationCollectionProxy`. If set to `:query`, no storage is required on the local class as the associated records will be fetched using a Parse query.

###### `:scope_only`
Setting this option to `true`, makes the association fetch based only on the scope provided and does not use the local instance object as a foreign pointer in the query. This allows for cases where another property of the local class, is needed to match the resulting records in the association.

In the example below, the `Post` class does not have a `:belongs_to` association to `Author`, but using the author's name, we can find related posts.

```ruby

class Author < Parse::Object
  property :name
  has_many :posts, ->{ where :tags.in => name.downcase }, scope_only: true
end

class Post < Parse::Object
  property :tags, :array
end

author.posts # => Posts where author's name is a tag
# equivalent: Post.all( :tags.in => artist.name.downcase )

```

## Creating, Saving and Deleting Records
This section provides some of the basic methods when creating, updating and deleting objects from Parse. Additional documentation for these APIs can be found under [Parse::Core::Actions](https://www.modernistik.com/gems/parse-stack/Parse/Core/Actions.html). To illustrate the various methods available for saving Parse records, we use this example class:

```ruby

class Artist < Parse::Object
  property :name
  belongs_to :manager, as: :user
end

class Song < Parse::Object
	property :name
	property :audio_file, :file
	property :released, :date
	property :available, :boolean, default: true
	belongs_to :artist
	has_many :fans, as: :user, through: :relation
end
```

### Create
To create a new object you can call `#new` while passing a hash of attributes you want to set. You can then use the property accessors to also modify individual properties. As you modify properties, you can access dirty tracking state and data using the generated [`ActiveModel::Dirty`](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html) features. When you are ready to commit the new object to Parse, you can call `#save`.

```ruby
song = Song.new name: "My Old Song"
song.new? # true
song.id # nil
song.released = DateTime.now
song.changed? # true
song.changed # ['name', 'released']
song.name_changed? # true

# commit changes
song.save

song.new? # false
song.id # 'hZLbW6ofKC'
song.name = "My New Song"
song.name_was # "My Old Song"
song.changed # ['name']

```

If you want to either find the first resource matching some given criteria or just create that resource if it can't be found, you can use `first_or_create`. Note that if a match is not found, the object will not be saved to Parse automatically, since the framework provides support for heterogeneous object batch saving. This means you can group different object classes together and save them all at once through the `Array#save` method to reduce API requests. If you want to truly want to find a first or create (save) the object, you may use `first_or_create!`.

```ruby
 # Finds matching song or creates a new unsaved object
song = Song.first_or_create(name: "Awesome Song", available: true)
song.id # nil since it wasn't found, and autosave is off.
song.released = 1.day.from_now
song.save
song.id # now has a valid objectId ex. 'xyz1122df'

song = Song.first_or_create(name: "Awesome Song", available: true)
song.id # 'xyz1122df`
song.save # noop since nothing changed

# first_or_create! : Return an existing OR newly saved object
song = Song.first_or_create!(name: "Awesome Song", available: true)

```

If the constraints you use for the query differ from the attributes you want to set for the new object, you can pass the attributes for creating a new resource as the second parameter to `#first_or_create`, also in the form of a `#Hash`.

```ruby
  song = Song.first_or_create({ name: "Long Way Home" }, { released: DateTime.now })
```

The above will search for a Song with name 'Long Way Home'. If it does not find a match, it will create a new instance with `name` set to 'Long Way Home' and the `released` date field to the current time, at time of execution. In this scenario, both hash arguments are merged to create a new instance with the second set of arguments overriding the first set.

```ruby
  song = Song.first_or_create({ name: "Long Way Home" }, {
          name: "Other Way Home",
          released: DateTime.now # Time.now ok too
    })
```

In the above case, if a Song is not found with name 'Long Way Home', the new instance will be created with `name` set to 'Other Way Home' and `released` set to `DateTime.now`.

### Saving
To commit a new record or changes to an existing record to Parse, use the `#save` method. The method will automatically detect whether it is a new object or an existing one and call the appropriate workflow. The use of ActiveModel dirty tracking allows us to send only the changes that were made to the object when saving. **Saving a record will take care of both saving all the changed properties, and associations. However, any modified linked objects (ex. belongs_to) need to be saved independently.**

```ruby
 song = Song.new(name: "Awesome Song") # Pass in a hash to the new method
 song.name = "Super Song" # Set individual property

 # Set multiple properties at once
 song.attributes = { name: "Best Song", released: DateTime.now }

 song.artist = Artist.first
 song.artist.name = "New Band Name"
 # add a fan to this song. Note this is a Parse Relation
 song.fans.add = Parse::User.first

 # saves changed properties, associations and relations.
 song.save

 song.artist.save # to commit the changes made to 'name'.

 songs = Song.all( :available => false)
 songs.each { |song| song.available = true }

 # uses a Parse batch operation for efficiency
 songs.save # save the rest of the items
```

The save operation can handle both creating and updating existing objects. If you do not want to update the association data of a changed object, you may use the `#update` method to only save the changed property values. In the case where you want to force update an object even though it has not changed, to possibly trigger your `before_save` hooks, you can use the `#update!` method. In addition, just like with other ActiveModel objects, you may call `reload!` to fetch the current record again from the data store.

### Saving applying User ACLs
You may save and delete objects from Parse on behalf of a logged in user by passing the session token to the call to `save` or `destroy`. Doing so will allow Parse to apply the ACLs of this user against the record to see if the user is authorized to read or write the record. See [Parse::Actions](https://www.modernistik.com/gems/parse-stack/Parse/Core/Actions.html).

```ruby
  user = Parse::User.login('myuser','pass')

  song = Song.first
  song.title = "My New Title"
  # save this song as if you were this user.
  # If the user does not have access rights, it will fail
  song.save session: user.session_token
  # shorthand: song.save session: user
```

#### Raising an exception when save fails
By default, we return `true` or `false` for save and destroy operations. If you prefer to have `Parse::Object` raise an exception instead, you can tell to do so either globally or on a per-model basis. When a save fails, it will raise a `Parse::RecordNotSaved`.

```ruby
 # globally across all models
 Parse::Model.raise_on_save_failure = true
 Song.raise_on_save_failure = true  # per-model

 # or per-instance raise on failure
 song.save!
```

When enabled, if an error is returned by Parse due to saving or destroying a record, due to your `before_save` or `before_delete` validation cloud code triggers, `Parse::Object` will return the a `Parse::RecordNotSaved` exception type. This exception has an instance method of `#object` which contains the object that failed to save.

### Modifying Associations
Similar to `:array` types of properties, a `has_many` association is backed by a collection proxy class and requires the use of `#add` and `#remove` to modify the contents of the association in order for it to correctly manage changes and updates with Parse. Using `has_many` for associations has the additional functionality that we will only add items to the association if they are of a `Parse::Pointer` or `Parse::Object` type. By default, these associations are fetched with only pointer data. To fetch all the objects in the association, you can call `#fetch` or `#fetch!` on the collection. Note that because the framework supports chaining, it is better to only request the objects you need by utilizing their accessors.

```ruby
  class Artist < Parse::Object
    has_many :songs # array association
  end

  artist = Artist.first
  artist.songs # Song pointers

  # fetch all the objects in this association
  artist.songs.fetch # fetches with parallel requests

  # add another song
  artist.songs.add Song.first
  artist.songs.remove other_song
  artist.save # commits changes
```

For the cases when you want to modify the items in this association without having to fetch all the objects in the association, we provide the methods `#add!`, `#add_unique!`, `#remove!` and `#destroy` that perform atomic Parse operations. These Parse operations are made directly to Parse compared to the non-bang versions which are batched with the rest of the pending object changes.

```ruby
  artist = Artist.first
  artist.songs.add! song # Add operation
  artist.songs.add_unique! other_song # AddUnique operation
  artist.songs.remove! another_song # Remove operation
  artist.save # no-op. (no operations were sent directly to Parse)

  artist.songs.destroy! # Delete operation of all Songs
```

The `has_many` Parse Relation associations are handled similarly as in the array cases above. However, since a Parse Relation represents a separate table, there are additional methods provided in order to query the intermediate relational table.

```ruby
  song = Song.first

  # Standard methods, but through relation table
  song.fans.count # efficient counting
  song.fans.add user
  song.fans.remove another_user
  song.save # commit changes

  # OR use to commit ONLY relational changes
  song.fans.save

  # Additional filtering methods

  # Find objects within the relation that match query constraints
  song.fans.all( ... constraints ... )

  # get a foreign relational query, related to this object
  query = song.fans.query

  # Atomic operations
  song.fans.add! user # AddRelation operation
  song.fans.remove! user # RemoveRelation operation
  song.fans.destroy! #noop since Relations cannot be emptied.

```

### Batch Requests
Batch requests are supported implicitly and intelligently through an extension of Array. When an array of `Parse::Object` subclasses is saved, Parse-Stack will batch all possible save operations for the objects in the array that have changed. It will also batch save 50 at a time until all items in the array are saved. The objects do not have to be of the same collection in order to be supported in the batch request. *Note: Parse does not allow batch saving Parse::User objects.*

```ruby
songs = Songs.first 1000 #first 1000 songs
songs.each do |song|
  .... modify them ...
end

# will batch save 50 items at a time until all are saved.
songs.save

# you can also destroy a set of objects
songs.destroy
```

### Magic `save_all`
By default, all Parse queries have a maximum fetch limit of 1000. While using the `:max` option, Parse-Stack can increase this up to 11,000. In the cases where you need to update a large number of objects, you can utilize the `Parse::Object#save_all` method to fetch, modify and save objects.

This methodology works by continually fetching and saving older records related to the time you begin a `save_all` request (called an "anchor date"), until there are no records left to update. To enable this to work, you must have confidence that any modifications you make to the records will successfully save through you validations that may be present in your `before_save`. This is important, as saving a record will set its `updated_at` date to one newer than the "anchor date" of when the `save_all` started. This `save_all` process will stop whenever no more records match the provided constraints that are older than the "anchor date", or when an object that was previously updated, is seen again in a future fetch (_which means the object failed to save_). Note that `save_all` will automatically manage the correct `updated_at` constraints in the query, so it is recommended that you do not use it as part of the initial constraints.

```ruby
  # Add any constraints except `updated_at`.
  Song.save_all( available: false) do |song|
    song.available = true # make all songs available
    # only objects that were modified will be updated
  	# do not call save. We will batch objects for saving.
  end
```

If you plan on using this feature in a lot of places, we recommend making sure you have set a MongoDB index of at least `{ "_updated_at" : 1 }`.

### Deleting
You can destroy a Parse record, just call the `#destroy` method. It will return a boolean value whether it was successful.

```ruby
 song = Song.first
 song.destroy

 # or in a batch
 songs = Song.all :limit => 10
 songs.destroy # uses batch operation
```

## Fetching, Finding and Counting Records

```ruby
 song = Song.find "<objectId>"
        Song.get  "<objectId>" # alias

 song1, song2 = Song.find("<objectId>", "<objectId2>", ...) # fetches in parallel with threads

 count = Song.count( constraints ) # performs a count operation

 query = Song.where( constraints ) # returns a Parse::Query with where clauses
 song = Song.first( ... constraints ... ) # first Song matching constraints
 s1, s2, s3 = Song.first(3) # get first 3 records from Parse.

 songs = Song.all( ... expressions ...) # get matching Song records. See Advanced Querying

 # memory efficient for large amounts of records if you don't need all the objects.
 # Does not return results after loop.
 Song.all( ... expressions ...) do |song|
   # ... do something with song..
 end

```

### Auto-Fetching Associations
All associations in are fetched lazily by default. If you wish to include objects as part of your query results you can use the `:includes` expression.

```ruby
  song = Song.first
  song.artist.pointer? # true, not fetched

  # find songs and include the full artist object for each
  song = Song.first(:includes => :artist)
  song.artist.pointer? # false (Full object already available)

```

However, Parse-Stack performs automatic fetching of associations when the associated classes and their properties are locally defined. Using our Artist and Song examples. In this example, the Song object fetched only has a pointer object in its `#artist` field. However, because the framework knows there is a `Artist#name` property, calling `#name` on the artist pointer will automatically go to Parse to fetch the associated object and provide you with the value.

```ruby
  song = Song.first
  # artist is automatically fetched
  song.artist.name

  # You can manually do the same with `fetch` and `fetch!`
  song.artist.fetch # considered "fetch if needed". No-op if not needed.
  song.artist.fetch! # force fetch regardless of state.
```

This also works for all associations types.

```ruby
  song = Song.first
  # automatically fetches all pointers in the chain
  song.artist.manager.username # Parse::User's username

  # Fetches Parse Relation objects
  song.fans.first.username # the fan's username
```

## Advanced Querying
The `Parse::Query` class provides the lower-level querying interface for your Parse tables using the default `Parse::Client` session created when `setup()` was called. This component can be used on its own without defining your models as all results are provided in hash form. By convention in Ruby (see [Style Guide](https://github.com/bbatsov/ruby-style-guide#snake-case-symbols-methods-vars)), symbols and variables are expressed in lower_snake_case form. Parse, however, prefers column names in **lower-first camel case** (ex. `objectId`, `createdAt` and `updatedAt`). To keep in line with the style guides between the languages, we do the automatic conversion of the field names when compiling the query. As an additional exception to this rule, the field key of `id` will automatically be converted to the `objectId` field when used. This feature can be overridden by changing the value of `Parse::Query.field_formatter`.

```ruby
# default uses :columnize
query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
query.compile_where # {"fieldOne"=>1, "fieldTwo"=>2, "fieldThree"=>3}

# turn off
Parse::Query.field_formatter = nil
query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
query.compile_where # {"field_one"=>1, "FieldTwo"=>2, "Field_Three"=>3}

# force everything camel case
Parse::Query.field_formatter = :camelize
query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
query.compile_where # {"FieldOne"=>1, "FieldTwo"=>2, "FieldThree"=>3}

```

Simplest way to perform query, is to pass the Parse class as the first parameter and the set of expressions.

```ruby
 query = Parse::Query.new("Song", {.... expressions ....})
 # or with Object classes
 query = Song.query({ .. expressions ..})

 # Print the prepared query
 query.prepared

 # Get results
 query.results # get results as Parse::Object(s)
 query.results(raw: true) # get the raw hash results

 query.first # first results matching constraints
 query.first(3) # gets first 3 results matching constraints

 query.count # perform a count operation instead
```

For large results set where you may want to operate on objects and may not need to keep all the objects in memory, you can use the block version of the API to iterate through all the records more efficiently.

```ruby

 # For large results set, you can use the block version to iterate over each matching record
 query.each do |record|
	# ... do something with record ...
	# block version does not return results
 end

```

### Results Caching
When a query API is made, the results are cached in the query object in case you need access to the results multiple times. This is only true as long as no modifications to the query parameters are made. You can force clear the locally stored results by calling `clear()` on the query instance.

```ruby
 query = Parse::Query.new("Song")
 query.where :field => value

 query.results # makes request
 # no query parameters changed, therefore same results
 query.results # no API request

 # if you modify the query or call 'clear'
 query.clear
 query.results # makes API request

```

### Counting
If you only need to know the result count for a query, provide count a
non-zero value. However, if you need to perform a count query, use `count()` method instead.

```ruby
 # get number of songs with a play_count > 10
 Song.count :play_count.gt => 10

 # same
 query = Parse::Query.new("Song")
 query.where :play_count.gt => 10
 query.count

```

### Distinct Aggregation
Finds the distinct values for a specified field across a single collection or
view and returns the results in an array. You may mix this with additional query constraints.

```ruby
 # Return a list of unique city names
 # for users created in the last 10 days.
 User.distinct :city, :created_at.after => 10.days.ago
 # ex. ["San Diego", "Los Angeles", "San Juan"]

 # same
 query = Parse::Query.new("_User")
 query.where :created_at.after => 10.days.ago
 query.distinct(:city) #=> ["San Diego", "Los Angeles", "San Juan"]

```

### Query Expressions
The set of supported expressions based on what is available through the Parse REST API. _For those who don't prefer the DataMapper style syntax, we have provided method accessors for each of the expressions._ A full description of supported query  operations, please refer to the [`Parse::Query`](https://www.modernistik.com/gems/parse-stack/Parse/Query.html) API reference.

#### :order
Specify a field to sort by.

```ruby
 # order updated_at ascending order
 Song.all :order => :updated_at

 # first order by highest like_count, then by ascending name.
 # Note that ascending is the default if not specified (ex. `:name.asc`)
 Song.all :order => [:like_count.desc, :name]
```

#### :keys
Restrict the fields returned by the query. This is useful for larger query results set where some of the data will not be used, which reduces network traffic and deserialization performance. _Use this feature with caution when working with the results, as values for the fields not specified in the query will be omitted in the resulting object._

```ruby
 # results only contain :name field
 Song.all :keys => :name

 # multiple keys
 Song.all :keys => [:name,:artist]
```

#### :includes
Use on Pointer columns to return the full object. You may chain multiple columns with the `.` operator.

```ruby
 # assuming an 'Artist' has a pointer column for a 'Manager'
 # and a Song has a pointer column for an 'Artist'.

 # include the full artist object
 Song.all(:includes => :artist)

 # Chaining
 Song.all :includes => [:artist, 'artist.manager']

```

#### :limit
Limit the number of objects returned by the query. The default is 100, with Parse allowing a maximum of 1000. The framework also allows a value of `:max`. Utilizing this will have the framework continually intelligently utilize `:skip` to continue to paginate through results until an empty result set is received or the `:skip` limit is reached. When utilizing `all()`, `:max` is the default option for `:limit`.

```ruby
 Song.all :limit => 1 # same as Song.first
 Song.all :limit => 1000 # maximum allowed by Parse
 Song.all :limit => :max
```

#### :skip
Use with limit to paginate through results. Default is 0.

```ruby
 # get the next 3 songs after the first 10
 Song.all :limit => 3, :skip => 10
```

#### :cache
A `true`, `false` or integer value. If you are using the built-in caching middleware, `Parse::Middleware::Caching`, setting this to `false` will prevent it from using a previously cached result if available. You may pass an integer value, which will allow this request to be cached for the specified number of seconds. The default value is `true`, which uses the [`:expires`](#expires) value that was passed when [configuring the client](#connection-setup).

```ruby
# don't use a cached result if available
Song.all limit: 500, cache: false

# cache this particular request for 60 seconds
Song.all limit: 500, cache: 1.minute
```

You may access the shared cache for the default client connection through `Parse.cache`. This is useful if you
want to utilize the same cache store for other purposes.

```ruby
# Access the cache instance for other uses
Parse.cache["key"] = "value"
Parse.cache["key"] # => "value"

# or with Parse queries and objects
Parse.cache.fetch("all:song:records") do |key|
  results = Song.all # or other complex query or operation
  # store it in the cache, but expires in 30 seconds
  Parse.cache.store(key, results, expires: 30)
end

```

#### :use_master_key
A true/false value. If you provided a master key as part of `Parse.setup()`, it will be sent on every request. However, if you wish to disable sending the master key on a particular request in order for the record ACLs to be enforced, you may pass `false`. If `false` is passed, caching will be disabled for this request.

```ruby
# disable sending the master key in the request if configured
Song.all limit: 3, use_master_key: false
```

#### :session
This will make sure that the query is performed on behalf (and with the privileges) of an authenticated user which will cause record ACLs to be enforced. If a session token is provided, caching will be disabled for this request. You may pass a string representing the session token, an authenticated `Parse::User` instance or a `Parse::Session` instance.

```ruby
# disable sending the master key in the request if configured
# and perform this request as a Parse user represented by this token
Song.all limit: 3, session: "<session_token>"
Song.all limit: 3, session: user # a logged-in Parse::User
Song.all limit: 3, session: session # Parse::Session
```

#### :where
The `where` clause is based on utilizing a set of constraints on the defined column names in your Parse classes. The constraints are implemented as method operators on field names that are tied to a value. Any symbol/string that is not one of the main expression keywords described here will be considered as a type of query constraint for the `where` clause in the query. See the section `Query Constraints` for examples of available query constraints.

```ruby
# parts of a single where constraint
{ :column.constraint => value }
```

## [Query Constraints](https://www.modernistik.com/gems/parse-stack/Parse/Constraint.html)
Most of the constraints supported by Parse are available to `Parse::Query`. Assuming you have a column named `field`, here are some examples. For an explanation of the constraints, please see [Parse Query Constraints documentation](http://docs.parseplatform.org/rest/guide/#queries). You can build your own custom query constraints by creating a `Parse::Constraint` subclass. For all these `where` clauses assume `q` is a `Parse::Query` object.

#### Equals
Default query constraint for matching a field to a single value.

```ruby
q.where :field => value
# (alias) :field.eq => value
```

If you want to see if a particular field contains a specific Parse::Object (pointer), you can use the following:

```ruby
# find rows where the `field` contains a Parse "_User" pointer with the specified objectId.
q.where :field => Parse::Pointer.new("_User", "anObjectId")
# alias using subclass helper
q.where :field => Parse::User.pointer("anObjectId")
# alias using `:id` constraint. We will infer :user maps to class "_User" (Parse::User)
q.where :user.id => "anObjectId"
```

#### Less Than
Equivalent to the `$lt` Parse query operation. The alias `before` is provided for readability.

```ruby
q.where :field.lt => value
# or alias
q.where :field.before => value
# ex. :createdAt.before => DateTime.now
```

#### Less Than or Equal To
Equivalent to the `$lte` Parse query operation. The alias `on_or_before` is provided for readability.

```ruby
q.where :field.lte => value
# or alias
q.where :field.on_or_before => value
# ex. :createdAt.on_or_before => DateTime.now
```

#### Greater Than
Equivalent to the `$gt` Parse query operation. The alias `after` is provided for readability.

```ruby
q.where :field.gt => value
# or alias
q.where :field.after => value
# ex. :createdAt.after => DateTime.now
```

#### Greater Than or Equal
Equivalent to the `$gte` Parse query operation. The alias `on_or_after` is provided for readability.

```ruby
q.where :field.gte => value
# or alias
q.where :field.on_or_after => value
# ex. :createdAt.on_or_after => DateTime.now
```

#### Not Equal To
Equivalent to the `$ne` Parse query operation. Where a particular field is not equal to value.

```ruby
q.where :field.not => value
```

#### Nullability Check
Provides a mechanism using the equality operator to check for `(undefined)` values.

```ruby
q.where :field.null => true|false
```

#### Exists
Equivalent to the `#exists` Parse query operation. Checks whether a value is set for key. The difference between this operation and the nullability check is when using compound queries with location.

```ruby
q.where :field.exists => true|false
```

#### Contained In
Equivalent to the `$in` Parse query operation. Checks whether the value in the column field is contained in the set of values in the target array. If the field is an array data type, it checks whether at least one value in the field array is contained in the set of values in the target array.

```ruby
# ex. :score.in => [1,3,5,7,9]
q.where :field.in => [item1,item2,...]
# alias
q.where :field.contained_in => [item1,item2,...]
```

#### Not Contained In
Equivalent to the `$nin` Parse query operation. Checks whether the value in the column field is __not__ contained in the set of values in the target array. If the field is an array data type, it checks whether at least one value in the field array is __not__ contained in the set of values in the target array.

```ruby
# ex. :player_name.not_in => ['Jonathan', 'Dario', 'Shawn']
q.where :field.not_in => [item1,item2,...]
# alias
q.where :field.not_contained_in => [item1,item2,...]
```

#### Contains All
Equivalent to the `$all` Parse query operation. Checks whether the value in the column field contains all of the given values provided in the array. Note that the `field` column should be of type `Array` in your Parse class.

```ruby
 # ex. :array_key.all => [2,3,4]
 q.where :field.all => [item1, item2,...]
 # alias
 q.where :field.contains_all => [item1,item2,...]
```

#### Regex Matching
Equivalent to the `$regex` Parse query operation. Requires that a field value match a regular expression.

```ruby
# ex. :name.like => /Bob/i
q.where :field.like => /ruby_regex/i
# alias
q.where :field.regex => /abc/
```

#### Select
Equivalent to the `$select` Parse query operation. This matches a value for a key in the result of a different query.

```ruby
q.where :field.select => { key: "field", query: query }

# example
value = { key: 'city', query: Artist.where(:fan_count.gt => 50) }
q.where :hometown.select => value

# if the local field is the same name as the foreign table field, you can omit hash
# assumes key: 'city'
q.where :city.select => Artist.where(:fan_count.gt => 50)
```

#### Reject
Equivalent to the `$dontSelect` Parse query operation. Requires that a field's value not match a value for a key in the result of a different query.

```ruby
q.where :field.reject => { key: :other_field, query: query }

# example
value = { key: 'city', query: Artist.where(:fan_count.gt => 50) }
q.where :hometown.reject => value

# if the local field is the same name as the foreign table field, you can omit hash
# assumes key: 'city'
q.where :city.reject => Artist.where(:fan_count.gt => 50)
```

#### Matches Query
Equivalent to the `$inQuery` Parse query operation. Useful if you want to retrieve objects where a field contains an object that matches another query.

```ruby
q.where :field.matches => query
# ex. :post.matches => Post.where(:image.exists => true )
q.where :field.in_query => query # alias
```

#### Excludes Query
Equivalent to the `$notInQuery` Parse query operation. Useful if you want to retrieve objects where a field contains an object that does not match another query.

```ruby
q.where :field.excludes => query
# ex. :post.excludes => Post.where(:image.exists => true
q.where :field.not_in_query => query # alias
```

#### Matches Object Id
Sometimes you want to find rows where a particular Parse object exists. You can do so by passing a the Parse::Object subclass or a Parse::Pointer. In some cases you may only have the "objectId" of the record you are looking for. For convenience, you can also use the `id` constraint. This will assume that the name of the field matches a particular Parse class you have defined. Assume the following:

```ruby
# where this Parse object equals the object in the column `field`.
q.where :field => Parse::Pointer("Field", "someObjectId")
# => "field":{"__type":"Pointer","className":"Field","objectId":"someObjectId"}}

# alias, shorthand when we infer `:field` maps to `Field` parse class.
q.where :field.id => "someObjectId"
# => "field":{"__type":"Pointer","className":"Field","objectId":"someObjectId"}}

```
It is always important to be thoughtful in naming column names in associations as
close to their foreign Parse class names. This enables more expressive syntax while reducing
code. The `id` also supports any object or pointer object. These are all equivalent:

```ruby
q.where :user    => User.pointer("xyx123")
q.where :user.id => "xyx123"
q.where :user.id => User.pointer("xyx123")
# All produce
# => "user":{"__type":"Pointer","className":"_User","objectId":"xyx123"}}
```

##### Additional Examples

```ruby

class Artist < Parse::Object
  # as described before
end

class Song < Parse::Object
  belongs_to :artist
end

artist = Artist.first # get any artist
artist_id = artist.id # ex. artist.id

# find all songs for this artist object
Song.all :artist => artist
```

In some cases, you do not have the Parse object, but you have its `objectId`. You can use the objectId in the query as follows:

```ruby
# shorthand if you are using convention. Will infer class `Artist`
Song.all :artist.id => artist_id

# other approaches, same result
Song.all :artist => Artist.pointer(artist_id)
Song.all :artist => Parse::Pointer.new("Artist", artist_id)

# "id" safely pointers and strings for supporting these types of API patterns
def find_songs(artist)
  Song.all :artist.id => artist
end

# all ok
songs = find_songs artist_id # by a string ObjectId
songs = find_songs artist # or by an object or pointer
songs = find_songs Artist.pointer(artist_id)

```

### [Geo Queries](https://www.modernistik.com/gems/parse-stack/Parse/Constraint/NearSphereQueryConstraint.html)
Equivalent to the `$nearSphere` Parse query operation. This is only applicable if the field is of type `GeoPoint`. This will query Parse and return a list of results ordered by distance with the nearest object being first.

```ruby
q.where :field.near => geopoint

# example
geopoint = Parse::GeoPoint.new(30.0, -20.0)
PlaceObject.all :location.near => geopoint
```

#### Max Distance Constraint
If you wish to constrain the geospatial query to a maximum number of __miles__, you can utilize the `max_miles` method on a `Parse::GeoPoint` object. This is equivalent to the `$maxDistanceInMiles` constraint used with `$nearSphere`.

```ruby
q.where :field.near => geopoint.max_miles(distance)
# or provide a triplet includes max miles constraint
q.where :field.near => [lat, lng, miles]

# example
geopoint = Parse::GeoPoint.new(30.0, -20.0)
PlaceObject.all :location.near => geopoint.max_miles(10)
```

We will support `$maxDistanceInKilometers` (for kms) and `$maxDistanceInRadians` (for radian angle) in the future.

#### [Bounding Box Constraint](https://www.modernistik.com/gems/parse-stack/Parse/Constraint/WithinGeoBoxQueryConstraint.html)
Equivalent to the `$within` Parse query operation and `$box` geopoint constraint. The rectangular bounding box is defined by a southwest point as the first parameter, followed by the a northeast point. Please note that Geo box queries that cross the international date lines are not currently supported by Parse.

```ruby
# GeoPoint bounding box
q.where :field.within_box => [soutwestGeoPoint, northeastGeoPoint]

# example
sw = Parse::GeoPoint.new 32.82, -117.23 # San Diego
ne = Parse::GeoPoint.new 36.12, -115.31 # Las Vegas

# get all PlaceObjects inside this bounding box
PlaceObject.all :location.within_box => [sw,ne]
```

#### [Polygon Area Constraint](https://www.modernistik.com/gems/parse-stack/Parse/Constraint/WithinPolygonQueryConstraint.html)
Equivalent to the `$geoWithin` Parse query operation and `$polygon` geopoint constraint. The polygon area is described by a list of `Parse::GeoPoint` objects and should contain 3 or more points. This feature is only available in Parse-Server version 2.4.2 and later.

```ruby
 # As many points as you want, minimum 3
 q.where :field.within_polygon => [geopoint1, geopoint2, geopoint3]

 # Polygon for the Bermuda Triangle
 bermuda  = Parse::GeoPoint.new 32.3078000,-64.7504999 # Bermuda
 miami    = Parse::GeoPoint.new 25.7823198,-80.2660226 # Miami, FL
 san_juan = Parse::GeoPoint.new 18.3848232,-66.0933608 # San Juan, PR

 # get all sunken ships inside the Bermuda Triangle
 SunkenShip.all :location.within_polygon => [bermuda, san_juan, miami]
```

#### [Full Text Search Constraint](https://www.modernistik.com/gems/parse-stack/Parse/Constraint/FullTextSearchQueryConstraint.html)
Equivalent to the `$text` Parse query operation and `$search` parameter constraint for efficient search capabilities. By creating indexes on one or more columns your strings are turned into tokens for full text search functionality. The `$search` key can take any number of parameters in hash form. *Requires Parse Server 2.5.0 or later*

```ruby
 # Do a full text search on "anthony"
 q.where :field.text_search => "anthony"

 # perform advance searches
 q.where :field.text_search => {term: "anthony", case_insensitive: true}
 # equivalent
 q.where :field.text_search => {:$term => "anthony", :$caseInsensitive => true}
```

You may use the following keys for the parameters clause.

| Parameter | Use |
| :--- | :----- |
| `$term`               | Specify a field to search (**Required**)|
| `$language`           | Determines the list of stop words and the rules for tokenizer.|
| `$caseSensitive`      | Enable or disable case sensitive search.|
| `$diacriticSensitive` | Enable or disable diacritic sensitive search.|

For additional details, please see [Query on String Values](https://docs.parseplatform.org/rest/guide/#queries-on-string-values).

### Relational Queries
Equivalent to the `$relatedTo` Parse query operation. If you want to retrieve objects that are members of a `Relation` field in your Parse class.

```ruby
q.where :field.related_to => pointer
q.where :field.rel => pointer # alias
```

In the example below, imagine you have a `Post` collection that has a Parse relation column `likes`
which has the set of users who have liked a certain post. You would use the `Parse::Users` class to query
against the `post` record of interest against the `likes` column of the `Post` collection.

```ruby
# assume Post class definition
class Post < Parse::Object
  # Parse relation to Parse::User records who've liked a post
  has_many :likes, through: :relation, as: :user
end

post = Post.first
# find all Users who have liked this post object,
# where 'likes' is a column on the Post class.
users = Parse::User.all :likes.rel => post

# or use the relation accessor declared in Post
users = post.likes.all # same result

# or find posts that a certain user has liked
user = Parse::User.first
# likes is a Parse relation in the Post collection that contains User records
liked_posts_by_user = Post.all :likes => user
```

### Compound Queries
Equivalent to the `$or` Parse query operation. This is useful if you want to find objects that match several queries. We overload the `|` operator in order to have a clean syntax for joining these `or` operations.

```ruby
or_query = query1 | query2 | query3 ...

# ex. where wins > 150 || wins < 5
query = Player.where(:wins.gt => 150) | Player.where(:wins.lt => 5)
results = query.results
```

If you do not prefer the syntax you may use the `or_where` method to chain multiple `Parse::Query` instances.

```ruby
query = Player.where(:wins.gt => 150)
query.or_where(:wins.lt => 5)
# where wins > 150 || wins < 5
results = query.results
```

## Query Scopes
This feature is a small subset of the [ActiveRecord named scopes](http://guides.rubyonrails.org/active_record_querying.html#scopes) feature. Scoping allows you to specify commonly-used queries which can be referenced as class method calls and are chainable with other scopes. You can use every `Parse::Query` method previously covered such as `where`, `includes` and `limit`.

```ruby

class Article < Parse::Object
  property :published, :boolean
  scope :published, -> { query(published: true) }
end
```

This is the same as defining your own class method for the query.

```ruby
class Article < Parse::Object
  def self.published
    query(published: true)
  end
end
```

You can also chain scopes and pass parameters. In addition, boolean and enumerated properties have automatically generated scopes for you to use.

```ruby

class Article < Parse::Object
  scope :published, -> { query(published: true) }

  property :comment_count, :integer
  property :category
  property :approved, :boolean

  scope :published_and_commented, -> { published.where :comment_count.gt => 0 }
  scope :popular_topics, ->(name) { published_and_commented.where category: name }
end

# simple scope
Article.published # => where published is true

# chained scope
Article.published_and_commented # published is true and comment_count > 0

# scope with parameters
Article.popular_topic("music") # => popular music articles
# equivalent: where(published: true, :comment_count.gt => 0, category: name)

# automatically generated scope
Article.approved(category: "tour") # => where approved: true, category: 'tour'

```

If you would like to turn off automatic scope generation for property types, set the option `:scope` to false when declaring the property.

## Calling Cloud Code Functions
You can call on your defined Cloud Code functions using the `call_function()` method. The result will be `nil` in case of errors or the value of the `result` field in the Parse response.

```ruby
 params = {}
 # use the explicit name of the function
 result = Parse.call_function 'functionName', params

 # to get the raw Response object
 response = Parse.call_function 'functionName', params, raw: true
 response.result unless response.error?
```

## Calling Background Jobs
You can trigger background jobs that you have configured in your Parse application as follows.

```ruby
 params = {}
 # use explicit name of the job
 result = Parse.trigger_job :myJobName, params

 # to get the raw Response object
 response = Parse.trigger_job :myJobName, params, raw: true
 response.result unless response.error?
```

## Active Model Callbacks
All `Parse::Object` subclasses extend [`ActiveModel::Callbacks`](http://api.rubyonrails.org/classes/ActiveModel/Callbacks.html) for `#save` and `#destroy` operations. You can setup internal hooks for `before` and `after`.

```ruby

class Song < Parse::Object
	# ex. before save callback
	before_save do
		self.name = self.name.titleize
    # make sure global acls are set
		acl.everyone(true, false) if new?
	end

  after_create do
    puts "New object successfully saved."
  end

end

song = Song.new name: "my title"
puts song.name # 'my title'
song.save # runs :save callbacks
puts song.name # 'My Title'

```

There are also a special `:create` callback. A `before_create` will be called whenever a unsaved object will be saved, and `after_create` will be called when a previously unsaved object successfully saved for the first time.

## Schema Upgrades and Migrations
You may change your local Parse ruby classes by adding new properties. To easily propagate the changes to your Parse Server application (MongoDB), you can call `auto_upgrade!` on the class to perform an non-destructive additive schema change. This will create the new columns in Parse for the properties you have defined in your models. Parse Stack will calculate the changes and only modify the tables which need new columns to be added.  This feature does require the use of the master key when configuring the client. *It will NOT destroy columns or data.*

```ruby
  # auto_upgrade! requires use of master key
  # upgrade the a class individually
  Song.auto_upgrade!

  # upgrade all classes for the default client connection.
  Parse.auto_upgrade!

```

## Push Notifications
Push notifications are implemented through the `Parse::Push` class. To send push notifications through the REST API, you must enable `REST push enabled?` option in the `Push Notification Settings` section of the `Settings` page in your Parse application. Push notifications targeting uses the Installation Parse class to determine which devices receive the notification. You can provide any query constraint, similar to using `Parse::Query`, in order to target the specific set of devices you want given the columns you have configured in your `Installation` class. The `Parse::Push` class supports many other options not listed here.

```ruby

 push = Parse::Push.new
 push.send( "Hello World!") # to everyone

 # simple channel push
 push = Parse::Push.new
 push.channels = ["addicted2salsa"]
 push.send "You are subscribed to Addicted2Salsa!"

 # advanced targeting
 push = Parse::Push.new( {..where query constraints..} )
 # or use `where()`
 push.where :device_type.in => ['ios','android'], :location.near => some_geopoint
 push.alert = "Hello World!"
 push.sound = "soundfile.caf"

  # additional payload data
 push.data = { uri: "app://deep_link_path" }

 # Send the push
 push.send

```

## Cloud Code Webhooks
Parse Parse allows you to receive Cloud Code webhooks on your own hosted server. The `Parse::Webhooks` class is a lightweight Rack application that routes incoming Cloud Code webhook requests and payloads to locally registered handlers. The payloads are `Parse::Webhooks::Payload` type of objects that represent that data that Parse sends webhook handlers. You can register any of the Cloud Code webhook trigger hooks (`beforeSave`, `afterSave`, `beforeDelete`, `afterDelete`) and function hooks.

### Cloud Code Functions
You can use the `route()` method to register handler blocks. The last value returned by the block will be returned back to the client in a success response. If `error!(value)` is called inside the block, we will return the correct Parse error response with the value you provided.

```ruby
# Register handling the 'helloWorld' function.
Parse::Webhooks.route(:function, :helloWorld) do
  #  use the Parse::Webhooks::Payload instance methods in this block
  name = params['name'].to_s #function params
  puts "CloudCode Webhook helloWorld called in Ruby!"
  # will return proper error response
  # error!("Missing argument 'name'.") unless name.present?

  name.present? ? "Hello #{name}!" : "Hello World!"
end

# Advanced: you can register handlers through classes if you prefer
# Parse::Webhooks.route :function, :myFunc, MyClass.method(:my_func)
```

If you have registered this webhook (see instructions below), you should be able to test it out by running curl using the command below.

```bash
curl -X POST \
  -H "X-Parse-Application-Id: ${APPLICATION_ID}" \
  -H "X-Parse-REST-API-Key: ${REST_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}' \
  https://localhost:1337/parse/functions/helloWorld
```

If you are creating `Parse::Object` subclasses, you may also register them there to keep common code and functionality centralized.

```ruby
class Song < Parse::Object

  webhook :function, :mySongFunction do
    the_user = user # available if a Parse user made the call
    str = params["str"]

    # ... get the list of matching songs the user has access to.
    results = Songs.all(:name.like => /#{str}/, :session => the_user)
    # Helper method for logging
    wlog "Found #{results.count} for #{the_user.username}"

    results
  end

end

```

You may optionally, register these functions outside of classes (recommended).

```ruby
Parse::Webhooks.route :function, :mySongFunction do
  # .. do stuff ..
  str = params["str"]
  results = Songs.all(:name.like => /#{str}/, :session => user)
  results
end
```

### Cloud Code Triggers
You can register webhooks to handle the different object triggers: `:before_save`, `:after_save`, `:before_delete` and `:after_delete`. The `payload` object, which is an instance of `Parse::Webhooks::Payload`, contains several properties that represent the payload. One of the most important ones is `parse_object`, which will provide you with the instance of your specific Parse object. In `:before_save` triggers, this object already contains dirty tracking information of what has been changed.

```ruby
  # recommended way
  class Artist < Parse::Object
    # ... properties ...

    # setup after save for Artist
    webhook :after_save do
      puts "User: #{user.username}" if user.present? # Parse::User
      artist = parse_object # Artist
      # no need for return in after save
    end

  end

  # or the explicit way
  Parse::Webhooks.route :after_save, :Artist do
    puts "User: #{user.username}" if user.present? # Parse::User
    artist = parse_object # Artist
    # no need for return in after save
  end
```

For any `after_*` hook, return values are not needed since Parse does not utilize them. You may also register as many `after_save` or `after_delete` handlers as you prefer, all of them will be called.

`before_save` and `before_delete` hooks have special functionality. When the `error!` method is called by the provided block, the framework will return the correct error response to Parse with value provided. Returning an error will prevent Parse from saving the object in the case of `before_save` and will prevent Parse from deleting the object when in a `before_delete`. In addition, for a `before_save`, the last value returned by the block will be the value returned in the success response. If the block returns nil or an `empty?` value, it will return `true` as the default response. You can also return a JSON object in a hash format to override the values that will be saved. However, we recommend modifying the `parse_object` provided since it has dirty tracking, and then returning that same object. This will automatically call your model specific `before_save` callbacks and send the proper payload back to Parse. For more details, see [Cloud Code BeforeSave Webhooks](http://docs.parseplatform.org/cloudcode/guide/#beforesave-triggers)

```ruby
# recommended way
class Artist < Parse::Object
  property :name
  property :location, :geopoint

  # setup after save for Artist
  webhook :before_save do
    the_user = user # Parse::User
    artist = parse_object # Artist
    # artist object will have dirty tracking information

    artist.new? # true if this is a new object

    # default San Diego
    artist.location ||= Parse::GeoPoint.new(32.82, -117.23)

    # raise to fail the save
    error!("Name cannot be empty") if artist.name.blank?

    if artist.name_changed?
      wlog "The artist name changed!"
      # .. do something if `name` has changed
    end

    # *important* returns a special hash of changed values
    artist
  end

  webhook :before_delete do
    # prevent deleting Artist records
    error!("You can't delete an Artist")
  end

end

```

### Mounting Webhooks Application
The app can be mounted like any regular Rack-based application.

```ruby
  # Rack (add this to config.ru)
  map "/webhooks" do
    run Parse::Webhooks
  end

  # or in Padrino (add this to apps.rb)
  Padrino.mount('Parse::Webhooks', :cascade => true).to('/webhooks')

  # or in Rails (add this in routes.rb)
  Rails.application.routes.draw do
    mount Parse::Webhooks, :at => '/webhooks'
  end
```

### Register Webhooks
Once you have locally setup all your trigger and function routes, you can write a small rake task to automatically register these hooks with your Parse application. To do this, you can configure a `HOOKS_URL` variable to be used as the endpoint. If you are using a service like Heroku, this would be the name of the heroku app url followed by your configured mount point.

```ruby
# ex. https://12345678.ngrok.com/webhooks
HOOKS_URL = ENV["HOOKS_URL"]

# Register locally setup handlers with Parse
task :register_hooks do
  # Parse.setup(....) if needed
  Parse::Webhooks.register_functions! HOOKS_URL
  Parse::Webhooks.register_triggers! HOOKS_URL
end

# Remove all webhooks!
task :remove_hooks do
  # Parse.setup(....) if needed
  Parse::Webhooks.remove_all_functions!
  Parse::Webhooks.remove_all_triggers!
end

```

However, we have predefined a few rake tasks you can use in your application. Just require `parse/stack/tasks` in your `Rakefile` and call `Parse::Stack.load_tasks`. This is useful for web frameworks like `Padrino`. Note that if you are using Parse-Stack with Rails, this is automatically done for you through the Railtie.

```ruby
  # Add to your Rakefile (if not using Rails)
  require 'parse/stack/tasks' # add this line
  Parse::Stack.load_tasks # add this line
```

Then you can see the tasks available by typing `rake -T`.

## Parse REST API Client
While in most cases you do not have to work with `Parse::Client` directly, you can still utilize it for any raw requests that are not supported by the framework. We provide support for most of the [Parse REST API](http://docs.parseplatform.org/rest/guide/#quick-reference) endpoints as helper methods, however you can use the `request()` method to make your own API requests. Parse::Client will handle header authentication, request/response generation and caching.

```ruby
client = Parse::Client.new(application_id: <string>, api_key: <string>) do |conn|
	# .. optional: configure additional middleware
end

 # Use API helper methods...
 client.config
 client.create_object "Artist", {name: "Hector Lavoe"}
 client.call_function "myCloudFunction", { key: "value"}

 # or use low-level request method
 client.request :get, "/1/users", query: {} , headers: {}
 client.request :post, "/1/users/<objectId>", body: {} , headers: {}

```

If you are already have setup a client that is being used by your defined models, you can access the current client with the following API:

```ruby
  # current Parse::Client used by this model
  client = Song.client

  # you can also have multiple clients
  client = Parse::Client.client #default client session
  client = Parse::Client.client(:other_session)

```

##### Options
- **app_id**: Your Parse application identifier.
- **api_key**: Your REST API key corresponding to the provided `application_id`.
- **master_key**: The master secret key for the application. If this is provided, `api_key` may be unnecessary.
- **logging**: A boolean value to add additional logging messages.
- **cache**: A [Moneta](https://github.com/minad/moneta) cache store that can be used to cache API requests. We recommend use a cache store that supports native expires like [Redis](http://redis.io). For more information see `Parse::Middleware::Caching`. Disabled by default.
- **expires**: When used with the `cache` option, sets the expiration time of cached API responses. The default is 3 seconds.
- **adapter**: The connection adapter to use. Defaults to `Faraday.default_adapter`.

### Request Caching
For high traffic applications that may be performing several server tasks on similar objects, you may utilize request caching. Caching is provided by a the `Parse::Middleware::Caching` class which utilizes a [Moneta store](https://github.com/minad/moneta) object to cache GET url requests that have allowable status codes (ex. HTTP 200, etc). The cache entry for the url will be removed when it is either considered expired (based on the `expires` option) or if a non-GET request is made with the same url. Using this feature appropriately can dramatically reduce your API request usage.

```ruby
store = Moneta.new :Redis, url: 'redis://localhost:6379'
 # use a Redis cache store with an automatic expire of 10 seconds.
Parse.setup(cache: store, expires: 10, ...)

user = Parse::User.first # request made
same_user = Parse::User.first # cached result

# you may clear the cache at any time
# clear the cache for the default session
Parse::Client.client.clear_cache!

# or through the client accessor of a model
Song.client.clear_cache!
```

You can always access the default shared cache through `Parse.cache` and utilize it
for other purposes in your application:

```ruby
# Access the cache instance for other uses
Parse.cache["key"] = "value"
Parse.cache["key"] # => "value"

# or with Parse queries and objects
Parse.cache.fetch("all:records") do |key|
  results = Song.all # or other complex query or operation
  # store it in the cache, but expires in 30 seconds
  Parse.cache.store(key, results, expires: 30)
end

```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/modernistik/parse-stack](https://github.com/modernistik/parse-stack).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
