require 'rubygems'
require 'fileutils'

module Logicminds
  module ArchiveManager
    class Database

      attr_reader :db_path

      def initialize(dir, name)
        @db_path = create_db(dir,name)

      end

      # lists all the files in the database directory
      def list
         Dir.entries(db_path)
      end

      def remove(name)
         FileUtils.rm_f(File.join(@db_path,name))
      end

      # reads text from file
      def read(name)
        File.open(File.join(@db_path,name), 'r') do |file|
          file.read
        end
      end

      # writes test to file
      def write(name, content)
        # create db if db doesn't already exist
        File.open(File.join(@db_path,name), 'w') do |file|
          file.write(content)
        end
      end

      private
      def create_db(dir, name)
        path = "#{@db_dir}/#{@db_name}"
        if ! File.exists?(path)
          begin
            FileUtils.mkdir_p(path)
          rescue
            log.error("Could not create db directory #{path}")
          end
        end
        path
      end

      def log
        unless @log.nil?
          file = open("#{@db_dir}/archive_manager.log", File::WRONLY | File::APPEND | File::CREAT)
          @log = Logger.new(file)
          @log.level = Logger::WARN
        end
        @log
      end

    end
  end
end
