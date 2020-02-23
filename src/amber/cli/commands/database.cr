require "micrate"
require "pg"
require "mysql"
require "sqlite3"
require "../../support/file_encryptor"
require "../../server/environment_loader"

module Amber::CLI
  class MainCommand < ::Cli::Supercommand
    AMBER_ENV = (ENV["AMBER_ENV"] ||= "development")

    command "db", aliased: "database"

    class Database < ::Cli::Command
      command_name "database"

      class Options
        arg_array "commands", desc: "drop create migrate rollback redo status version seed"
        help
      end

      class Help
        caption "# Performs database maintenance tasks"
      end

      def run
        args.commands.each do |command|
          Micrate::Cli.setup_logger
          Micrate::DB.connection_url = database_url
          begin
            case command
            when "drop"
              drop_database
            when "create"
              create_database
            when "seed"
              `crystal db/seeds.cr`
              puts "Seeded database"
            when "migrate"
              Micrate::Cli.run_up
            when "rollback"
              Micrate::Cli.run_down
            when "redo"
              Micrate::Cli.run_redo
            when "status"
              Micrate::Cli.run_status
            when "version"
              Micrate::Cli.run_dbversion
            else
              Micrate::Cli.print_help
            end
          rescue e : Micrate::UnorderedMigrationsException
            exit! Micrate::Cli.report_unordered_migrations(e.versions), error: true
          rescue e : DB::ConnectionRefused
            exit! "Connection refused: #{Micrate::DB.connection_url}", error: true
          rescue e : Exception
            exit! e.message, error: true
          end
        end
      end

      private def drop_database
        url = Micrate::DB.connection_url.to_s
        if url.starts_with? "sqlite3:"
          path = url.gsub("sqlite3:", "")
          File.delete(path)
          puts "Deleted file #{path}"
        else
          name = set_database_to_schema url
          Micrate::DB.connect do |db|
            db.exec "DROP DATABASE IF EXISTS #{name};"
          end
          puts "Dropped database #{name}"
        end
      end

      private def create_database
        url = Micrate::DB.connection_url.to_s
        if url.starts_with? "sqlite3:"
          puts "For sqlite3, the database will be created during the first migration."
        else
          name = set_database_to_schema url
          Micrate::DB.connect do |db|
            db.exec "CREATE DATABASE #{name};"
          end
          puts "Created database #{name}"
        end
      end

      private def set_database_to_schema(url)
        uri = URI.parse(url)
        if path = uri.path
          Micrate::DB.connection_url = url.gsub(path, "/#{uri.scheme}")
          return path.gsub("/", "")
        else
          raise "could not determine database name"
        end
      end

      private def database_url
        ENV["DATABASE_URL"]? || begin
          EnvironmentLoader.new(AMBER_ENV, "./config/environments").settings.database_url
        end
      end
    end
  end
end
