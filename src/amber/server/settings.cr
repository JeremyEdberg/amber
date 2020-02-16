require "./cluster"
require "./configuration"
require "./ssl"

module Amber
  class Settings
    include Amber::DSL::Server
    property port_reuse : Bool
    property log : ::Logger
    property color : Bool = true
    property process_count : Int32
    property secret_key_base : String
    property port : Int32
    property name : String
    property host : String
    property ssl_key_file : String? = nil
    property ssl_cert_file : String? = nil
    property redis_url = ""
    property database_url = ""
    property session : Hash(Symbol, Symbol | String | Int32)

    # Loads environment yml settings from the current AMBER_ENV environment variable
    # and defaults to development environment
    {{ run("../scripts/environment_loader.cr") }}
  end
end
