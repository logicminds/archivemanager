require 'spec_helper'

describe Logicminds::ArchiveManager::Manager, "Manager" do


  before(:all) do

    @url = 'https://github.com/logicminds/devops/archive/master.zip'
    @manager = Logicminds::ArchiveManager::Manager.new('/tmp/testlocation')
    @archive = Logicminds::ArchiveManager::Archive.new('testarchive',
                                                   '/tmp/install_path', 'http://www.archive.org/testarchive.tar.gz',
                                                   'zip', '1.2.3','http://www.archive.org/testarchive.tar.gz.sha1' )
    @archive.checksum = '1234567890abc'
  end


  before(:each) do
    FakeFS::FileSystem.clear
    @fs = FakeFS::FileSystem
    FileUtils.mkdir_p "/home/marun/bootstrap"
  end
  after(:each) do

  end
  after :all do

  end


  it 'can initialize' do
    @manager.should_not be_nil
  end

  it 'should create a database file' do
    @manager.create_db
    File.exists?(@manager.db).should_not be_false
  end

  it "should create the correct file path" do
    value = @manager.db_filepath(@archive)
    value.should == "#{@manager.db}/#{@archive.checksum}"
  end

  it "should write a package to the database" do
    @manager.write_to_db(@archive)
    File.exists?(@manager.db_filepath(@archive)).should be_true
  end

  it "should add a package to the database" do
    @manager.add_pkg_to_db(@archive)
    File.exists?(@manager.db_filepath(@archive)).should be_true
  end

  #it 'should not find its local package and return nil' do
  #  @manager.remove_pkg_from_db(@archive)
  #  localpkg = @manager.local_pkg(@archive)
  #  localpkg.should be_false
  #end
  #
  #it "should download and create checksum" do
  #  @archive.pkg_remote_url = @url
  #  @manager.download(@archive)
  #  @archive.should_not be_nil
  #  @archive.checksum.should_not be_nil
  #  @archive['pkg_source_path'].should_not be_nil
  #
  #end
  #
  #it "should not download and create checksum" do
  #  @archive.pkg_remote_url = @url + 'bogus'
  #  expect { @manager.download(@archive)  }.to raise_exception
  #end
  #
  #it 'should extract archive to install path' do
  #  @archive.pkg_remote_url = @url
  #  @manager.download(@archive)
  #  File.exists?(@archive['pkg_source_path']).should be_true
  #  @manager.extract(@archive)
  #  File.exists?(@archive['install_path']).should be_true
  #  files = @manager.dir_file_count(@archive["install_path"])
  #  files.should >= 2
  #end
  #
  #it 'should return correct package type' do
  #  @manager.package_type.should eq('zip')
  #end
  #
  #it 'should add a package to a filesystem' do
  #  @archive.pkg_remote_url = @url
  #  @manager.download(@archive)
  #  @manager.add_pkg_to_fs(@archive)
  #  File.exists?(@archive['install_path']).should be_true
  #
  #end
  #
  #it 'should install item to db and fs' do
  #  @archive.pkg_remote_url = @url
  #  @manager.install(@archive)
  #  File.exists?(@archive['install_path']).should be_true
  #  File.exists?(@manager.db_filepath(@archive)).should be_true
  #end
  #
  #it "should be able to detect if the given package already exists" do
  #  @manager.install(@archive)
  #  @manager.pkg_exists_in_db?(@archive).should be_true
  #  @manager.pkg_exists_in_fs?(@archive).should be_true
  #  @manager.exists?(@archive).should be_true
  #end
  #
  it "should be able to detect if the given package doesn't exist" do
    @manager.uninstall(@archive)
    @manager.exists?(@archive).should be_false
  end
  #
  #it 'should be able to remove a package from the database' do
  #  @archive.pkg_remote_url = @url
  #  @archive.checksum = 'blahblahblah'
  #  @manager.add_pkg_to_db(@archive)
  #  @manager.pkg_exists_in_db?(@archive).should be_true
  #  @manager.remove_pkg_from_db(@archive)
  #  @manager.pkg_exists_in_db?(@archive).should be_false
  #end
  #
  #it 'should be able to remove a package from the filesystem' do
  #  @archive.pkg_remote_url = @url
  #  @manager.install(@archive)
  #  @manager.exists?(@archive).should be_true
  #  @manager.remove_pkg_from_fs(@archive)
  #  @manager.pkg_exists_in_fs?(@archive).should be_false
  #end
  #
  #it 'should be able to uninstall a package' do
  #  @manager.install(@archive)
  #  @manager.exists?(@archive).should be_true
  #  @manager.uninstall(@archive)
  #  @manager.exists?(@archive).should be_false
  #
  #end
  #
  #it "should return a remote checksum when no remote checksum url is provided" do
  #  @manager.install(@archive)
  #  @manager.remote_checksum(@archive).should eq(@archive.checksum)
  #end
  #
  #it 'should be able to determine if the installed package is the latest' do
  #  @manager.install(@archive)
  #  @manager.latest?.should be_true
  #end

  # I am expecting that I don't have to add the logic to not download already installed items.
  #it 'should not download and install package if the latest is installed' do
  #  @manager.should_receive(:download).exactly(1).times
  #  @manager.install
  #  @manager.install
  #
  #
  #end
  #
  #it 'should not redownload a package if the package is already installed when checksum is provided' do
  #  fail
  #end


end
