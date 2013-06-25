require 'fileutils'
require 'json'
require 'zlib'
require 'open-uri'
require 'digest'
require 'pathname'
require 'rubygems'


class ArchiveManager
  #desc "Package management for remote repository from nexus"

  attr_accessor :db, :pkg, :db_dir, :db_name

  def initialize(install_path, pkg_remote_url, remote_checksum_url='', database_dir='/tmp/db' )
    @unzips_in_root = true
    @pkg = {
        'install_path'       => install_path,
        'pkg_source_path'    => '',
        'pkg_remote_url'     => pkg_remote_url,
        'checksum'           => '',
        'remote_checksum_url' => remote_checksum_url,

    }
    @db_dir = database_dir
    @local_pkg = nil
    @remote_pkg = nil
    @db_name = 'unmanaged_packages'
  end



  # the remote version will always overwrite the local version if the checksum is different
  # if the remote checksum is unavailable download and verify its the lateset
  def latest?
    remote_checksum == local_checksum
  end

  ##
  # Extracts all the files in the gzipped tar archive +io+ into
  # +destination_dir+.
  #
  # If an entry in the archive contains a relative path above
  # +destination_dir+ or an absolute path is encountered an exception is
  # raised.

  def extract_tar_gz io, destination_dir # :nodoc:
    open_tar_gz io do |tar|
      tar.each do |entry|
        destination = install_location entry.full_name, destination_dir

        FileUtils.rm_rf destination

        FileUtils.mkdir_p File.dirname destination

        open destination, 'wb', entry.header.mode do |out|
          out.write entry.read
          out.fsync rescue nil # for filesystems without fsync(2)
        end

        say destination if Gem.configuration.really_verbose
      end
    end
  end

  # retrieve the remote checksum or fail back by downloading the package and computing a checksum which will take longer
  def remote_checksum(package=@pkg)
    # no checksum url provided, falling back to download and compute
    url = package['remote_checksum_url']
    checksum = nil
    if (url.nil? or url.empty?)
       url = package['pkg_remote_url']
       source =  download_to_temp(url)
       checksum = Digest::MD5.hexdigest(source.read)
    else
      source =  download_to_temp(url)
      checksum = source.read.chomp
    end
    FileUtils.rm_f(source.path)
    return checksum
  end

  ###### TESTED ###########

  def uninstall(pkg)
    remove_pkg_from_fs(pkg)
    remove_pkg_from_db(pkg)
  end

  def remove_pkg_from_fs(pkg)
    FileUtils.rm_rf(pkg['install_path'])
    FileUtils.rm_f(pkg['pkg_source_path'])
  end

  # verifies that the contents of the packages are the same
  def same_pkg?(package_a, package_b)
    (package_a.to_a - package_b.to_a).empty?
  end

  # return true if the package exists in the db and on the filesystem
  def exists?(package=@pkg)
    pkg_exists_in_db?(package) and pkg_exists_in_fs?(package)
  end

  def pkg_exists_in_db?(package)
    # Get the package from the local db
    !local_pkg(package).nil?
  end

  def pkg_exists_in_fs?(package)
    FileTest.exists?("#{package['install_path']}/.installed")
  end

  # assumes the archive file exists on the filesystem
  # moves the archive file to the install_path and extracts it
  def add_pkg_to_fs(package=@pkg)
    FileUtils.mkpath(package['install_path'])
    source = package['pkg_source_path']
    basename = Pathname.new(package['pkg_source_path']).basename
    dest = package['install_path']
    FileUtils.mv(source, "#{dest}/#{basename}")
    package['pkg_source_path'] = "#{dest}/#{basename}"
    extract(package)
  end

  # return boolean if installer runs correctly
  def install(package=@pkg)
    if source = download(package)
      if add_pkg_to_fs(package)
        add_pkg_to_db(package)
        touch_installed(package)
      end
    end
    #  no need to keep the archive file around
    FileUtils.rm_f(package['pkg_source_path'])
  end

  def touch_installed(pkg)
    source = pkg['install_path']
    File.open("#{source}/.installed", 'w') do |file|
      file.write("checksum=#{pkg['checksum']}\n")
      file.write("install_date=#{Time.now}\n")
      file.write("db_file=#{db_filepath(pkg)}")
    end
  end

  # Given a tar, zip, gzip file

  def dir_file_count(dir)
    directory = Dir.new(dir)
    if directory
      #Dir[('**/*')].count { |file| File.file?(file) }
      directory.count
    else
      0
    end
  end

  def extract(package=@pkg)
    source = package['pkg_source_path']
    type = package_type(package)
    install_path = package['install_path']
    FileUtils.mkpath(package['install_path'])
    # need to switch to using native ruby implementation
    # tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(pkg['pkg_source_path']))
    case type
      when 'tar.gz'
        command = "tar -zxf #{source} -C #{install_path}"
      when 'tar'
        command = "tar -xf #{source} -C #{install_path}"
      when 'zip'
        command = "unzip -o #{source} -d #{install_path}"
      else
        raise 'the archive type is unsupported'
    end
    if FileTest.exists?(source)
      result = `#{command}`
    else
      raise "Source file : #{source} does not exist"
    end
  end

  def package_type(package=@pkg)
    if package['package_type']
      return package['package_type']
    else
      source = @pkg['pkg_remote_url']
    end

    case source
      when /.*\.tar\.gz/
        package['package_type'] = "tar.gz"

      when /.*\.tar/
        package['package_type'] = "tar"

      when /.*\.zip/
        package['package_type'] = "zip"
      else
        raise "the archive type #{source} is unsupported"
    end
  end

  def db
    "#{@db_dir}/#{@db_name}"
  end

  # creates a unique filename for the given pkg object
  def db_filename(package)
    package['checksum']
  end

  def db_filepath(pkg)
    "#{db}/#{db_filename(pkg)}"
  end

  def create_db
    if ! FileTest.exists?(db)
      FileUtils.mkdir_p(db)
    end
    if ! FileTest.exists?(db)
      raise "Could not create file #{db_filepath}"
    end
  end

  def local_checksum
      @pkg['checksum']
  end

  def write_to_db(package)
    # create db if db doesn't already exist
    create_db
    File.open(db_filepath(package), 'w') do |file|
      file.write(JSON.pretty_generate(package))
    end
  end

  # adds the package filename to the database
  def add_pkg_to_db(package)
    write_to_db(package)
  end

  # removes the package filename to the database
  def remove_pkg_from_db(package)
      FileUtils.rm_f(db_filepath(package))
  end

  def local_pkg(package)
    if FileTest.exists?(db_filepath(package))
      File.open(db_filepath(package), 'r') do | file|
        json = file.read
        JSON.parse(json)
      end
    end
  end

  def download_to_temp(url)
    begin
      source = open(url)
    rescue
      raise "Could not download from #{url}"
    end
  end

  # downloads the url to a temporary location and adds the checksum of the file
  # returns nil if download was unsuccessful
  # uses
  def download(package=@pkg)
    begin
      type = package_type(package)
      source = download_to_temp(package['pkg_remote_url'])
      new_path = "#{source.path}.#{type}"
      FileUtils.mv(source.path, new_path )
      if source
        checksum = Digest::MD5.hexdigest(source.read)
        package["pkg_source_path"] = new_path
        if checksum
          package["checksum"] = checksum
          return package
        end
      end
    rescue
      raise
    end
  end
  ############

  def credentials
    @credentials ||= {:username => nil, :password => nil}
  end

  def query
    if FileTest.exists?()
      {:name => @resource[:name], :ensure => :present}
    end
  end


end