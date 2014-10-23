require 'rubygems'
require 'json'

module Logicminds
  module ArchiveManager

    class Archive
      attr_accessor :name, :install_path, :pkg_remote_url, :checksum, :remote_checksum_url
      attr_accessor :pkg_remote_url, :package_type, :version


      def initialize(pkgname, pkg_install_path, pkg_remote_source, type, version_str,pkg_remote_checksum_url='' )
        @name = pkgname;
        @install_path = pkg_install_path
        @pkg_remote_url = pkg_remote_source
        @remote_checksum_url = pkg_remote_checksum_url
        @package_type = type
        @version = version_str

      end

      def filename
        checksum
      end

      def self.from_json(json)
        data = JSON.parse(json)
        new_archive = Archive.new(data[:name],
                    data[:install_path],
                    data[:pkg_remote_url],
                    data[:package_type],
                    data[:version],
                    data[:remote_checksum_url]
        )
        new_archive.checksum = data[:checksum]
        new_archive
      end


      def to_a
        arr = []
        self.instance_variables.each do |var|
          arr << var.to_s.gsub('@', '')
          value = self.instance_variable_get var
          arr << value
        end
        arr
      end

      def to_s
        to_json
      end

      def to_json
        hash = {}
        self.instance_variables.each do |var|
          name = var.to_s.gsub('@', '')
          hash[name] = self.instance_variable_get var
        end
        JSON.pretty_generate(hash)
      end

      #def self.from_json string
      #  JSON.load(string).each do |var, val|
      #    self.instance_variable_set var, val
      #  end
      #end
    end
  end
end
