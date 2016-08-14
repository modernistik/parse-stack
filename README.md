# Parse-Stack - A Parse-Server Ruby Client and ORM
Parse Stack is an opinionated framework for ruby applications that utilize the [Parse Server Platform](https://github.com/ParsePlatform/parse-server). It provides a client adapter, a query engine, an object relational mapper (ORM) and a Cloud Code Webhooks rack application.

### Code Status
[![Gem Version](https://badge.fury.io/rb/parse-stack.svg)](https://badge.fury.io/rb/parse-stack)
[![Build Status](https://travis-ci.org/modernistik/parse-stack.svg?branch=master)](https://travis-ci.org/modernistik/parse-stack)

## Table Of Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Overview](#overview)
- [Main Features](#main-features)
- [Architecture](#architecture)
  - [Parse::Client](#parseclient)
  - [Parse::Query](#parsequery)
  - [Parse::Object](#parseobject)
  - [Parse::Webhooks](#parsewebhooks)
- [Connection Setup](#connection-setup)
  - [Connection Options](#connection-options)
- [Core Classes](#core-classes)
  - [Parse::Pointer](#parsepointer)
  - [Parse::File](#parsefile)
  - [Parse::Date](#parsedate)
  - [Parse::GeoPoint](#parsegeopoint)
    - [Calculating Distances between locations](#calculating-distances-between-locations)
  - [Parse::Bytes](#parsebytes)
- [Modeling and Subclassing](#modeling-and-subclassing)
  - [Defining Properties](#defining-properties)
    - [Accessor Aliasing](#accessor-aliasing)
    - [Property Options](#property-options)
  - [Associations](#associations)
    - [Belongs To](#belongs-to)
    - [Has Many (Array or Relation)](#has-many-array-or-relation)
- [Creating, Saving and Deleting Records](#creating-saving-and-deleting-records)
  - [Create](#create)
  - [Saving](#saving)
    - [Raising an exception when save fails](#raising-an-exception-when-save-fails)
  - [Modifying Associations](#modifying-associations)
  - [Batch Save Requests](#batch-save-requests)
  - [Magic `save_all`](#magic-save_all)
  - [Deleting](#deleting)
- [Fetching, Finding and Counting Records](#fetching-finding-and-counting-records)
  - [Auto-Fetching Associations](#auto-fetching-associations)
- [Advanced Querying](#advanced-querying)
  - [Results Caching](#results-caching)
  - [Counting](#counting)
  - [Query Expressions](#query-expressions)
    - [:order](#order)
    - [:keys](#keys)
    - [:includes](#includes)
    - [:limit](#limit)
    - [:skip](#skip)
    - [:cache](#cache)
    - [:use_master_key](#use_master_key)
    - [:session_token](#session_token)
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
  - [Geo Queries](#geo-queries)
    - [Max Distance Constraint](#max-distance-constraint)
    - [Bounding Box Constraint](#bounding-box-constraint)
  - [Relational Queries](#relational-queries)
  - [Compound Queries](#compound-queries)
- [Cloud Code Functions](#cloud-code-functions)
- [Cloud Code Background Jobs](#cloud-code-background-jobs)
- [Hooks and Callbacks](#hooks-and-callbacks)
- [Schema Upgrades and Migrations](#schema-upgrades-and-migrations)
- [Push Notifications](#push-notifications)
- [Cloud Code Webhooks](#cloud-code-webhooks)
  - [Cloud Code functions](#cloud-code-functions)
  - [Cloud Code Triggers](#cloud-code-triggers)
  - [Mounting Webhooks Application](#mounting-webhooks-application)
  - [Register Webhooks](#register-webhooks)
- [Parse REST API Client](#parse-rest-api-client)
      - [Options](#options-2)
  - [Request Caching](#request-caching)
- [Installation](#installation)
- [Development](#development)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Overview
Parse::Stack is a full stack framework that utilizes several ideas behind [DataMapper](http://datamapper.org/docs/find.html) and [ActiveModel](https://github.com/rails/rails/tree/master/activemodel) to manage and maintain larger scale ruby applications and tools that utilize the Parse Platform. If you are familiar with these technologies, the framework should feel familiar to you.

```ruby

require 'parse/stack'

Parse.setup app_id: APP_ID,
            api_key: REST_API_KEY,
            server_url: 'https://api.parse.com/1/'

# Object Mapper
class Song < Parse::Object
  property :name
  property :play, :integer
  property :audio_file, :file
  property :tags, :array
  property :released, :date
  belongs_to :artist
  # `like` is a Parse Relation to User class
  has_many :likes, as: :user, through: :relation
end

# create tables or add new columns (non-destructive)
Song.auto_upgrade!

artist = Artist.first(:name.like => /Sinatra/, :genres.in => ['swing'])

song = Song.new name: "Fly Me to the Moon"
song.artist = artist
# Parse files
song.audio_file = Parse::File.create("http://path_to.mp3")
# relations
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

## Main Features
While there are many additional features of the framework, these are the main points.

- Object Relational Mapping with dirty tracking.
- Easy management of Parse GeoPoints, Files and ACLs.
- Parse Queries support with caching middleware. (Reduces API usage)
- Support for all Parse data types.
- One-to-One, One-to-Many and Many-to-Many relations.
- Integration with Parse Cloud Code Webhooks.
- Send Push notifications with advanced targeting.
- Schema upgrades and migrations.
- Rake tasks for webhook registrations.
- Some special magic with :save_all and :max limit fetch.

## Architecture
The architecture of `Parse::Stack` is broken into four main components.

### Parse::Client
This class is the core and low level API for the Parse SDK REST interface that is used by the other components. It can manage multiple sessions, which means you can have multiple client instances pointing to different Parse Applications at the same time. It handles sending raw requests as well as providing Request/Response objects for all API handlers. The connection engine is Faraday, which means it is open to add any additional middleware for features you'd like to implement.

### Parse::Query
This class implements the [Parse REST Querying](https://parse.com/docs/rest/guide#queries) interface in the [DataMapper finder syntax style](http://datamapper.org/docs/find.html). It compiles a set of query constraints and utilizes `Parse::Client` to send the request and provide the raw results. This class can be used without the need to define models.

### Parse::Object
This component is main class for all object relational mapping subclasses for your application. It provides features in order to map your remote Parse records to a local ruby object. It implements the Active::Model interface to provide a lot of additional features, CRUD operations, querying, including dirty tracking, JSON serialization, save/destroy callbacks and others. While we are overlooking some functionality, for simplicity, you will mainly be working with Parse::Object as your superclass. While not required, it is highly recommended that you define a model (Parse::Object subclass) for all the Parse classes in your application.

### Parse::Webhooks
Parse provides a feature called [Cloud Code Webhooks](http://blog.parse.com/announcements/introducing-cloud-code-webhooks/). For most applications, save/delete triggers and cloud functions tend to be implemented by Parse's own hosted Javascript solution called Cloud Code. However, Parse provides the ability to have these hooks utilize your hosted solution instead of their own, since their environment is limited in terms of resources and tools. If you are using the open source [Parse Server](https://github.com/ParsePlatform/parse-server), you must enable this hooks feature by enabling the environment variable `PARSE_EXPERIMENTAL_HOOKS_ENABLED` on your Parse server.

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
              server_url: 'https://api.parse.com/1/' #default
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

Calling `setup` will create the default `Parse::Client` session object that will be used for all models and requests in the stack. You may retrive this client by calling the class `session()` method. It is possible to create different client connections and have different models point to different Parse applications and endpoints at the same time.

```ruby
  default_client = Parse::Client.session(:default)
  # or just Parse::Client.session
```

### Connection Options
There are additional connection options that you may pass the setup method when creating a `Parse::Client`.

#### `:server_url`
The server url of your Parse-Server if you are not using the hosted Parse.com service. By default it will use `PARSE_SERVER_URL` environment variable available or fall back to `https://api.parse.com/1/` if not specified.

#### `:app_id`
The Parse application id. By default it will use `PARSE_APP_ID` environment variable if not specified.

#### `:api_key`
The Parse REST API Key. By default it will use `PARSE_API_KEY` environment variable if not specified.

#### `:master_key` _(optional)_
The Parse application master key. If this key is set, it will be sent on every request sent by the client and your models. By default it will use `PARSE_MASTER_KEY` environment variable if not specified.

#### `:logging`
A true or false value. It provides you additional logging information of requests and responses. If set to the special symbol of `:debug`, it will provide additional payload data in the log messages.

#### `:adapter`
The connection adapter. By default it uses the `Faraday.default_adapter` which is Net/HTTP.

#### `:cache`
A caching adapter of type `Moneta::Transformer`. Caching queries and object fetches can help improve the performance of your application, even if it is for a few seconds. Only successful `GET` object fetches and queries (non-empty) will be cached. You may set the default expiration time with the `expires` option. See related: [Moneta](https://github.com/minad/moneta). At any point in time you may clear the cache by calling the `clear_cache!` method on the client connection.

#### `:expires`
Sets the default cache expiration time (in seconds) for successful non-empty `GET` requests when using the caching middleware. The default value is 3 seconds. If `:expires` is set to 0, caching will be disabled. You can always clear the current state of the cache using the `clear_cache!` method on your `Parse::Client` instance.

#### `:faraday`
You may pass a hash of options that will be passed to the `Faraday` constructor.

## Parse Config
Getting your configuration variables once you have a default client setup can be done with `Parse.config`. The first time this method is called, Parse-Stack will get the configuration from Parse-Server, and cache it. To force a reload of the config, use `config!`.

```ruby
  Parse.setup( ... )

  val = Parse.config["myKey"]
  val = Parse.config["myKey"] # cached

  # Force fetch of config!
  val = Parse.config!["myKey"]

```

## Core Classes
While some native data types are similar to the ones supported by Ruby natively, other ones are more complex and require their dedicated classes.

### Parse::Pointer
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
comment.post.pointer? # true
comment.author.pointer? # true

 # we have defined a Post class handler
comment.post # <Post @parse_class="Post", @id="xdqcCqfngz">

 # we have not defined an Author class handler
comment.author # <Parse::Pointer @parse_class="Author", @id="hZLbW6ofKC">
```

The effect is that for any unknown classes that the framework encounters, it will generate Parse::Pointer instances until you define those classes with valid properties and associations. While this might be ok for some classes you do not use, we still recommend defining all your Parse classes locally in the framework.

### Parse::File
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

The default MIME type for all files is `iamge/jpeg`. This can be default can be changed by setting a value to `Parse::File.default_mime_type`. Other ways of creating a `Parse::File` are provided below. The created Parse::File is not uploaded until you call `save`.

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

### Parse::Date
This class manages dates in the special JSON format it requires for properties of type `:date`. `Parse::Date` subclasses `DateTime`, which allows you to use any features or methods available to `DateTime` with `Parse::Date`. While the conversion between `Time` and `DateTime` objects to a `Parse::Date` object is done implicitly for you, you can use the added special methods, `DateTime#parse_date` and `Time#parse_date`, for special occasions.

```ruby
  song = Song.first
  song.released = DateTime.now # converted to Parse::Date
  song.save # ok
```

One important note with dates, is that `created_at` and `updated_at` columns do not follow this convention all the time. Depending on the Cloud Code SDK, they can be the Parse ISO hash date format or the `iso8601` string format. By default, these are serialized as `iso8601` when sent as responses to Parse for backwards compatibility with some clients. To use the Parse ISO hash format for these fields instead, set `Parse::Object.disable_serialized_string_date = true`.

### Parse::GeoPoint
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

### Parse::Bytes
The `Bytes` data type represents the storage format for binary content in a Parse column. The content is needs to be encoded into a base64 string.

```ruby
  bytes = Parse::Bytes.new( base64_string )
  # or use helper method
  bytes = Parse::Bytes.new
  bytes.encode( content ) # same as Base64.encode64

  decoded = bytes.decoded # same as Base64.decode64
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

- **:string** (_default_) - a generic string.
- **:integer** - basic number.
- **:float** - a floating numeric value.
- **:boolean** - true/false value. (_alias: `:bool`_).
- **:date** - a Parse date type. Maps to `Parse::Date`.
- **:array** - a collection of heterogeneous items. Maps to `Parse::CollectionProxy`.
- **:file** - a Parse file type. Maps to `Parse::File`.
- **:geopoint** - a GeoPoint type. Maps to `Parse::GeoPoint`.
- **:bytes** - a Parse bytes data type managed as base64. Maps to `Parse::Bytes`.
- **:object** - an object Hash data type.

For completeness, the `:id` and `:acl` data types are also defined in order to handle the Parse `objectId` field and the `ACL` object. Those are special and should not be used in your class (unless you know what you are doing). New data types can be implemented through the internal `typecast` interface. **TODO: discuss `typecast` interface in the future**

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

	# Maps to "featuredImage" column representing a File.
	property :featured_image, :file

	property :location, :geopoint

  # Support bytes
  property :data, :bytes

	# store SEO information. Make sure we map it to the column
	# "SEO", otherwise it would have implicitly used "seo"
	# as the remote column name
	property :seo, :object, field: "SEO"
end
```

After properties are defined, you can use appropriate getter and setter methods to modify the values. As properties become modified, the model will keep track of the changes using the [dirty tracking feature of ActiveModel](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html). If an attribute is modified in-place then make use of **[attribute_name]_will_change!** to mark that the attribute is changing. Otherwise ActiveModel can't track changes to in-place attributes.

To support dirty tracking on properties of data type of `:array`, we utilize a proxy class called `Parse::CollectionProxy`. This class has special functionality which allows lazy loading of content as well and keeping track of the changes that are made. While you are able to access the internal array on the collection through the `#collection` method, it is important not to make in-place edits to the object. You should use the preferred methods of `#add` and `#remove` to modify the contents of the collection. When `#save` is called on the object, the changes will be commited to Parse.

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

##### `:required => (true|false)`
This option provides information to the property builder that it is a required property. The requirement is not strongly enforced for a save, which means even though the value for the property may not be present, saves and updates can be successfully performed. However, the setting `required` to true, it will set some ActiveModel validations on the property to be used when calling `valid?`. By default it will add a `validates_presence_of` for the property key. If the data type of the property is either `:integer` or `:float`, it will also add a `validates_numericality_of` validation. Default `false`.

##### `:field => (string)`
This option allows you to set the name of the remote column for the Parse table. Using this will explicitly set the remote property name to the value of this option. The value provided for this option will affect the name of the alias method that is generated when `alias` option is used. **By default, the name of the remote column is the lower-first camelcase version of the property name. As an example, for a property with key `:my_property_name`, the framework will implicitly assume that the remote column is `myPropertyName`.**

##### `:default => (value|proc)`
This option provides you to set a default value for a specific property when the getter accessor method is used and the internal value of the instance object's property is nil. It can either take a literal value or a Proc/lambda.

```ruby
class SomeClass < Parse::Object
	# default value
	property :category, default: "myValue"
	# default value Proc style
	property :date, default: lambda { |x| DateTime.now }
end
```

##### `:alias => (true|false)`
It is highly recommended that this is set to true, which is the default. This option allows for the generation of the additional accessors with the value of `:field`. By allowing two accessors methods, aliased to each other, allows for easier importing and automatic object instantiation based on Parse object JSON data into the Parse::Object subclass.

##### `:symbolize => (true|false)`
This option is only available for fields with data type of `:string`. This allows you to utilize the values for this property as symbols instead of the literal strings, which is Parse's storage format. This feature is useful if a particular property represents a set of enumerable states described in string form. As an example, if you have a `Post` object which has a set of publish states stored in Parse as "draft","scheduled", and "published" - we can use ruby symbols to make our code easier.

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

##### Overriding Property Accessors
When a `property` is defined, special accessors are created for it. It is not recommended that you override the generated accessors for the properties you have defined.

### Associations
Parse supports a three main types of relational associations. One type of relation is the `One-to-One` association. This is implemented through a specific column in Parse with a Pointer data type. This pointer column, contains a local value that refers to a different record in a separate Parse table. This association is implemented using the `:belongs_to` feature. The second association is of `One-to-Many`. This is implemented is in Parse as a Array type column that contains a list of of Parse pointer objects. It is recommended by Parse that this array does not exceed 100 items for performance reasons. This feature is implemented using the `:has_many` operation with the plural name of the local Parse class. The last association type is a Parse Relation. These can be used to implement a large `Many-to-Many` association without requiring an explicit intermediary Parse table or class. This feature is also implemented using the `:has_many` method but passing the option of `:relation`.

#### Belongs To
Utilizing the `belongs_to` method in defining a property in a Parse::Object subclass sets up an association between the local table and a foreign table. Specifying the `belongs_to` in the class, tells the framework that the Parse table contains a local column in its schema that has a reference to a record in a foreign table. The argument to `belongs_to` should be the singularized version of the foreign Parse::Object class. you should specify the foreign table as the snake_case singularized version of the foreign table class. It is important to note that the reverse relationship is not generated automatically.

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
You can override some of the default functionality when creating both `belongs_to` and `has_many` associations.

###### `:required => (true|false)`
Setting the requirement, automatically creates an ActiveModel validation of `validates_presence_of` for the association. This will not prevent the save, but affects the validation check when `valid?` is called on an instance. Default is false.

###### `:as => (string)`
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

###### `:field => (string)`
This option allows you to set the name of the remote Parse column for this property. Using this will explicitly set the remote property name to the value of this option. The value provided for this option will affect the name of the alias method that is generated when `alias` option is used. **By default, the name of the remote column is the lower-first camel case version of the property name. As an example, for a property with key `:my_property_name`, the framework will implicitly assume that the remote column is `myPropertyName`.**

#### Has Many (Array or Relation)
Parse has two ways of implementing a `has_many` association. The first type is where you can designate a column to be of Array type that contains a list of Parse pointers. It is recommended that this is used for associations where the quantity is less than 100 in order to maintain query and fetch performance. The second implementation is through a Parse Relation. This is done by passing the option `:through => :relation` to the `has_many` method. Designating a column as a Parse relation to another class type, will create a one-way intermediate "join" table between the local table class and the foreign one. One important distinction of this compared to other types of data stores (ex. PostgresSQL) is that:

1. The inverse relationship association is not available automatically. Therefore, having a column of `artists` in a `Band` class that relates to members of the band (as `Artist` class), does not automatically make a set of `Band` records available to `Artist` records for which they have been related. If you need to maintain both the inverse relationship between a foreign class to its associations, you will need to manually manage that.
2. Querying the relation is actually performed against the implicit join table, not the local one.
3. Applying query constraints for a set of records within a relation is performed against the foreign table class, not the class having the relational column.

The Parse documentation provides more details on associations, see [Parse Relations Guide](https://parse.com/docs/ios/guide#relations). The good news is that the framework will handle the work for (2) and (3) automatically.

To define a `has_many` association, provide the name of the foreign relation class in plural form. The framework will use the camelcase singular form of the property name as being the name of the foreign table class.

```ruby

class Artist < Parse::Object
end

class Fan < Parse::Object
	property :location, :geopoint
end

class Band < Parse::Object
  property :category, :integer, default: 1
	# assume any band as < 100 members
	has_many :artists # assumes `through: :array`
	# bands can have millions of fans (Parse::User objects),
  # we use relations instead
	has_many :fans, as: :user, through: :relation 
end

 # Find all bands which have a category in this array.
bands = Band.all( :category.in => [1,3,5,7,9] )

 # Find all bands which have Joe as an artist.
banjoe = Artist.first name: "Joe Banjoe"
bands = Band.all( :artists.in => [banjoe.pointer] )
band = bands.first

 # the number of fans in the relation
band.fans.count

# get the first object in relation
fan = bands.fans.first

# use `add` or `remove` to modify relations
band.fans.add Parse::User.first
# updates the relation as well as changes to `band`
band.fans.save

 # Find 50 fans who are near San Diego, CA
downtown = Parse::GeoPoint.new(32.82, -117.23)
fans = band.fans.all(:location.near => downtown, :limit => 50)

```

You can perform atomic additions and removals of objects from `has_many` relations. Parse allows this by providing a specific atomic operation request. You can use the methods below to perform these types of atomic operations. __Note: The operation is performed directly on Parse server and not on your local object.__

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

##### Options
Options for `has_many` are the same as the `belongs_to` counterpart with support for `:required`, `:as` and `:field`. It has this additional option of `:through` which helps specify whether it is an Array or Relation association type.

###### `:through => (:array|:relation)`
This sets the type of the `has_many` relation. If `:relation` is set, it tells the framework that the column defined is of type Parse Relation. The default value is `:array`, which defines the column in Parse as being an array of Parse pointer objects.

## Creating, Saving and Deleting Records
This section provides some of the basic methods when creating, updating and deleting objects from Parse. To illustrate the various methods available for saving Parse records, we use this example class:

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

If you want to either find the first resource matching some given criteria or just create that resource if it can't be found, you can use `#first_or_create`. Note that if a match is not found, the object will not be saved to Parse automatically, since the framework provides support for heterogeneous object batch saving. This means you can group different object classes together and save them all at once through the `Array#save` method to reduce API requests. You may modify this behavior by setting `Parse::Model.autosave_on_create = true`.

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

The save operation can handle both creating and updating existing objects. If you do not want to update the association data of a changed object, you may use the `#update` method to only save the changed property values. In the case where you want to force update an object even though it has not changed, to possibly trigger your `before_save` hooks, you can use the `#update!` method.

#### Raising an exception when save fails
By default, we return `true` or `false` for save and destroy operations. If you prefer to have `Parse::Object` raise an exception instead, you can tell to do so either globally or on a per-model basis. When a save fails, it will raise a `Parse::SaveFailureError`.

```ruby
	Parse::Model.raise_on_save_failure = true # globally across all models
	Song.raise_on_save_failure = true          # per-model

  # or per-instance raise on failure
  song.save!

```

When enabled, if an error is returned by Parse due to saving or destroying a record, due to your `before_save` or `before_delete` validation cloud code triggers, `Parse::Object` will return the a `Parse::SaveFailureError` exception type. This exception has an instance method of `#object` which contains the object that failed to save.

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
  artist.save # noop. operations were sent directly to Parse

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

### Batch Save Requests
Batch requests are supported implicitly and intelligently through an extension of array. When an array of `Parse::Object` subclasses is saved, Parse-Stack will batch all possible save operations for the objects in the array that have changed. It will also batch save 50 at a time until all items in the array are saved. *Note: Parse does not allow batch saving Parse::User objects.*

```ruby
songs = Songs.first 1000 #first 1000 songs
songs.each do |song|
  .... modify them ...
end

# will batch save 50 items at a time until all are saved.
songs.save
```

### Magic `save_all`
By default, all Parse queries have a maximum fetch limit of 1000. While using the `:max` option, `Parse::Stack` can increase this up to 11,000. In the cases where you need to update a large number of objects, you can utilize the `Parse::Object#save_all` method
to fetch, modify and save objects.

This methodology works by continually fetching and saving older records related to the time you begin a `save_all` request (called an "anchor date"), until there are no records left to update. To enable this to work, you must have confidence that any modifications you make to the records will successfully save through you validations that may be present in your `before_save`. This is important, as saving a record will set its `updated_at` date to one newer than the "anchor date" of when the `save_all` started. This `save_all` process will stop whenever no more records match the provided constraints that are older than the "anchor date", or when an object that was previously updated, is seen again in a future fetch (_which means the object failed to save_). Note that `save_all` will automatically manage the correct `updated_at` constraints in the query, so it is recommended that you do not use it as part of the initial constraints.

```ruby
  # Add any constraints except `updated_at`.
  Song.save_all( available: false) do |song|
    song.available = true # make all songs available
    # only objects that were modified will be updated
  	# do not call save. We will batch objects for saving.
  end
```

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
All associations in `Parse::Stack` are fetched lazily by default. If you wish to include objects as part of your query results you can use the `:includes` expression.

```ruby
  song = Song.first
  song.artist.pointer? # true, not fetched

  # find songs and include the full artist object for each
  song = Song.first(:includes => :artist)
  song.artist.pointer? # false (Full object already available)

```

However, `Parse::Stack` performs automatic fetching of associations when the associated classes and their properties are locally defined. Using our Artist and Song examples. In this example, the Song object fetched only has a pointer object in its `#artist` field. However, because the framework knows there is a `Artist#name` property, calling `#name` on the artist pointer will automatically go to Parse to fetch the associated object and provide you with the value.

```ruby
  song = Song.first
  # artist is automatically fetched
  song.artist.name

  # You can manually do the same with `fetch` and `fetch!`
  song.artist.fetch # considered "fetch if needed". Noop if not needed.
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
If you only need to know the result count for a query, provide count a non-zero value. However, if you need to perform a count query, use `count()` method instead. As a reminder, there are a few [caveats to counting records as detailed by Parse](https://parse.com/docs/rest/guide#queries-counting-objects).

```ruby
 # get number of songs with a play_count > 10
 Song.count :play_count.gt => 10

 # same
 query = Parse::Query.new("Song")
 query.where :play_count.gt => 10
 query.count

```

### Query Expressions
The set of supported expressions based on what is available through the Parse REST API. _For those who don't prefer the DataMapper style syntax, we have provided method accessors for each of the expressions._

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
Limit the number of objects returned by the query. The default is 100, with Parse allowing a maximum of 1000. The framework also allows a value of `:max`. Utilizing this will have the framework continually intelligently utilize `:skip` to continue to paginate through results until an empty result set is received or the `:skip` limit is reached (10,000). When utilizing `all()`, `:max` is the default option for `:limit`.

```ruby
 Song.all :limit => 1 # same as Song.first
 Song.all :limit => 1000 # maximum allowed by Parse
 Song.all :limit => :max # up to 11,000 records (theoretical).
```

#### :skip
Use with limit to paginate through results. Default is 0 with maximum value being 10,000.

```ruby
 # get the next 3 songs after the first 10
 Song.all :limit => 3, :skip => 10
```

#### :cache
A true/false value. If you are using the built-in caching middleware, `Parse::Middleware::Caching`, it will prevent it from using a previously cached result if available. The default value is `true`.

```ruby
# don't use a cached result if available
Song.all limit: 3, cache: false
```

#### :use_master_key
A true/false value. If you provided a master key as part of `Parse.setup()`, it will be sent on every request. However, if you wish to disable sending the master key on a particular request in order for the record ACLs to be enforced, you may pass `false`. If `false` is passed, caching will be disabled for this request.

```ruby
# disable sending the master key in the request if configured
Song.all limit: 3, use_master_key: false
```

#### :session_token
A Parse session token string. If you would like to perform a query as a particular user, you may pass their session token in the query. This will make sure that the query is performed on behalf (and with the priviledges) of that user which will cause record ACLs to be enforced. If a session token is provided, caching will be disabled for this request.

```ruby
# disable sending the master key in the request if configured
Song.all limit: 3, session_token: "<session_token>"
```

#### :where
The `where` clause is based on utilizing a set of constraints on the defined column names in your Parse classes. The constraints are implemented as method operators on field names that are tied to a value. Any symbol/string that is not one of the main expression keywords described here will be considered as a type of query constraint for the `where` clause in the query. See the section `Query Constraints` for examples of available query constraints.

```ruby
# parts of a single where constraint
{ :column.constraint => value }
```

## Query Constraints
Most of the constraints supported by Parse are available to `Parse::Query`. Assuming you have a column named `field`, here are some examples. For an explanation of the constraints, please see [Parse Query Constraints documentation](http://parseplatform.github.io/docs/rest/guide/#queries). You can build your own custom query constraints by creating a `Parse::Constraint` subclass. For all these `where` clauses assume `q` is a `Parse::Query` object.

#### Equals
Default query constraint for matching a field to a single value.

```ruby
q.where :field => value
# (alias) :field.eq => value
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

### Geo Queries
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

#### Bounding Box Constraint
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

### Relational Queries
Equivalent to the `$relatedTo` Parse query operation. If you want to retrieve objects that are members of a `Relation` field in your Parse class.

```ruby
q.where :field.related_to => pointer
q.where :field.rel => pointer # alias

# example
# find all Users who have liked this post object
post = Post.first
users = Parse::User.all :likes.rel => post
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

## Cloud Code Functions
You can call on your defined Cloud Code functions using the `call_function()` method. The result will be `nil` in case of errors or the value of the `result` field in the Parse response.

```ruby
 params = {}
 # use the explicit name of the function
 result = Parse.call_function 'functionName', params

 # to get the raw Response object
 response = Parse.call_function 'functionName', params, raw: true
 response.result unless response.error?
```

## Cloud Code Background Jobs
You can trigger background jobs that you have configured in your Parse application as follows.

```ruby
 params = {}
 # use explicit name of the job
 result = Parse.trigger_job :myJobName, params

 # to get the raw Response object
 response = Parse.trigger_job :myJobName, params, raw: true
 response.result unless response.error?
```

## Hooks and Callbacks
All `Parse::Object` subclasses extend [`ActiveModel::Callbacks`](http://api.rubyonrails.org/classes/ActiveModel/Callbacks.html) for `#save` and `#destroy` operations. You can setup internal hooks for `before`, `during` and `after`. See

```ruby

class Song < Parse::Object
	# ex. before save callback
	before_save do
		self.name = self.name.titleize
		# make sure global acls are set
		acl.everyone(true, false) if new?
	end

end

song = Song.new name: "my title"
puts song.name # 'my title'
song.save
puts song.name # 'My Title'

```

## Schema Upgrades and Migrations
You may change your local Parse ruby classes by adding new properties. To easily propagate the changes to your Parse application (MongoDB), you can call `auto_upgrade!` on the class to perform an non-destructive additive schema change. This will create the new columns in Parse for the properties you have defined in your models. Parse Stack will calculate the changes and only modify the tables which need new columns to be added. *It will not destroy columns or data*

```ruby
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
Parse Parse allows you to receive Cloud Code webhooks on your own hosted server. The `Parse::Webhooks` class is a lightweight Rack application that routes incoming Cloud Code webhook requests and payloads to locally registered handlers. The payloads are `Parse::Payload` type of objects that represent that data that Parse sends webhook handlers. You can register any of the Cloud Code webhook trigger hooks (`beforeSave`, `afterSave`, `beforeDelete`, `afterDelete`) and function hooks. If you are using the open source [Parse Server](https://github.com/ParsePlatform/parse-server), you must enable this hooks feature by enabling the environment variable `PARSE_EXPERIMENTAL_HOOKS_ENABLED` on your Parse server.

### Cloud Code functions
You can use the `route()` method to register handler blocks. The last value returned by the block will be returned back to the client in a success response. If `error!(value)` is called inside the block, we will return the correct Parse error response with the value you provided.

```ruby
# Register handling the 'helloWorld' function.
Parse::Webhooks.route(:function, :helloWorld) do
  #  use the Parse::Payload instance methods in this block
  incoming_params = params #function params
  name = params['name'].to_s

  # will return proper error response
  error!("Missing argument 'name'.") unless name.present?
  # return early
  "Hello #{name}!"
end

# Advanced: you can register handlers through classes if you prefer
Parse::Webhooks.route :function, :myFunc, MyClass.method(:my_func)
```

If you are creating `Parse::Object` subclasses, you may also register them there to keep common code and functionality centralized.

```ruby
class Song < Parse::Object

  webhook :function, :mySongFunction do
    the_user = user # available if a Parse user made the call
    params = params
    # ... do stuff ...
    true
  end

end

```

### Cloud Code Triggers
You can register webhooks to handle the different object triggers: `:before_save`, `:after_save`, `:before_delete` and `:after_delete`. The `payload` object, which is an instance of `Parse::Payload`, contains several properties that represent the payload. One of the most important ones is `parse_object`, which will provide you with the instance of your specific Parse object. In `:before_save` triggers, this object already contains dirty tracking information of what has been changed.

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
  Parse::Webhooks.route :after_save, "Artist" do
    puts "User: #{user.username}" if user.present? # Parse::User
    artist = parse_object # Artist
    # no need for return in after save
  end
```

For any `after_*` hook, return values are not needed since Parse does not utilize them. You may also register as many `after_save` or `after_delete` handlers as you prefer, all of them will be called.

`before_save` and `before_delete` hooks have special functionality. When the `error!` method is called by the provided block, the framework will return the correct error response to Parse with value provided. Returning an error will prevent Parse from saving the object in the case of `before_save` and will prevent Parse from deleting the object when in a `before_delete`. In addition, for a `before_save`, the last value returned by the block will be the value returned in the success response. If the block returns nil or an `empty?` value, it will return `true` as the default response. You can also return a JSON object in a hash format to override the values that will be saved for the object. For this, we recommend using the `payload_update` method. For more details, see [Cloud Code BeforeSave Webhooks](https://parse.com/docs/cloudcode/guide#cloud-code-advanced-beforesave-webhooks)

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
      # .. do something if `name` has changed
    end

    # *important* returns a special hash of changed values
    artist.payload_update
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
  # Rack in config.ru
  map "/webhooks" do
    run Parse::Webhooks
  end

  # Padrino (in apps.rb)
  Padrino.mount('Parse::Webhooks', :cascade => true).to('/webhooks')

  # Rails
  RailsApp::Application.routes.draw do
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

However, we have predefined a few rake tasks you can use in your application. Just require `parse/stack/tasks` in your `Rakefile` and call `Parse::Stack.load_tasks`. This is useful for web frameworks like `Padrino` and `Rails`.

```ruby
  # Rails Rakefile example
  require_relative 'config/application'
  require 'parse/stack/tasks' # add this line

  Rails.application.load_tasks
  Parse::Stack.load_tasks # add this line

```

Then you can see the tasks available by typing `rake -T`.

## Parse REST API Client
While in most cases you do not have to work with `Parse::Client` directly, you can still utilize it for any raw requests that are not supported by the framework. We provide support for most of the [Parse REST API](https://parse.com/docs/rest/guide#quick-reference) endpoints as helper methods, however you can use the `request()` method to make your own API requests. Parse::Client will handle header authentication, request/response generation and caching.

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
  client = Parse::Client.session #default client session
  client = Parse::Client.session(:other_session)

```

##### Options
- **app_id**: Your Parse application identifier.
- **api_key**: Your REST API key corresponding to the provided `application_id`.
- **master_key**: The master secret key for the application. If this is provided, `api_key` may be unnecessary.
- **logging**: A boolean value to add additional logging messages.
- **cache**: A [Moneta](https://github.com/minad/moneta) cache store that can be used to cache API requests. We recommend use a cache store that supports native expires like [Redis](http://redis.io). For more information see `Parse::Middleware::Caching`. Disabled by default.
- **expires**: When used with the `cache` option, sets the expiration time of cached API responses. The default is [3 seconds](https://parse.com/docs/cloudcode/guide#cloud-code-timeouts).
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
Parse::Client.session.clear_cache!

# or through the client accessor of a model
Song.client.clear_cache!

```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parse-stack'
```

or install it locally

```ruby
$ gem install parse-stack
```

## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
