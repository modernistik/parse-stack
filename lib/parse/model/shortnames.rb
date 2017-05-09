
require_relative 'object'

# Simple include to use short verion of core class names
::Installation = Parse::Installation unless defined?(::Installation)
::Role = Parse::Role unless defined?(::Role)
::Product = Parse::Product unless defined?(::Product)
::Session = Parse::Session unless defined?(::Session)
::User = Parse::User unless defined?(::User)
