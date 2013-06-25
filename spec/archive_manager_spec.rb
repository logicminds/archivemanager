require 'archive_manager'

describe ArchiveManager, "Package Tests" do

  before(:all) do
    @url = 'https://github.com/logicminds/devops/archive/master.zip'
  end
  before(:each) do
    @pack = ArchiveManager.new('/tmp/testlocation',@url)
    @pkg = @pack.pkg
  end
  after(:each) do
    FileUtils.rm_rf(@pack.db_dir)
    FileUtils.rm_rf('/tmp/testlocation')
    @pkg.delete @pkg['pkg_source_path']

  end


  it 'can initialize' do
    @pack.should_not be_nil
  end

  it 'should create a database file' do
    @pack.create_db
    File.exists?(@pack.db).should_not be_false
  end

  it "should create the correct file path" do
    @pkg['checksum'] = 'blahblahblah'
    value = @pack.db_filepath(@pkg)
    value.should == "#{@pack.db}/#{@pkg['checksum']}"
  end

  it "should write a package to the database" do
    @pkg['checksum'] = 'blahblahblah'
    @pack.write_to_db(@pkg)
    FileTest.exists?(@pack.db_filepath(@pkg)).should be_true
  end

  it "should add a package to the database" do
    @pkg['checksum'] = 'blahblahblah'
    @pack.add_pkg_to_db(@pkg)
    FileTest.exists?(@pack.db_filepath(@pkg)).should be_true
  end

  it 'should find its local package' do
    @pkg['checksum'] = 'blahblahblah'
    @pack.add_pkg_to_db(@pkg)
    localpkg = @pack.local_pkg(@pkg)
    # compates the contents of the hashs via array since hashes are unordered
    (localpkg.to_a - @pkg.to_a).empty?.should be_true
  end

  it 'should not find its local package and return nil' do
    @pkg['checksum'] = 'blahblahblah'
    @pack.remove_pkg_from_db(@pkg)
    localpkg = @pack.local_pkg(@pkg)
    localpkg.should be_false
  end

  it "should download and create checksum" do
    @pkg['pkg_remote_url'] = @url
    @pack.download(@pkg)
    @pkg.should_not be_nil
    @pkg['checksum'].should_not be_nil
    @pkg['pkg_source_path'].should_not be_nil

  end

  it "should not download and create checksum" do
    @pkg['pkg_remote_url'] = @url + 'bogus'
    expect { @pack.download(@pkg)  }.to raise_exception
  end

  it 'should extract archive to install path' do
    @pkg['pkg_remote_url'] = @url
    @pack.download(@pkg)
    FileTest.exists?(@pkg['pkg_source_path']).should be_true
    @pack.extract(@pkg)
    FileTest.exists?(@pkg['install_path']).should be_true
    files = @pack.dir_file_count(@pkg["install_path"])
    files.should >= 2
  end

  it 'should return correct package type' do
    @pack.package_type.should eq('zip')
  end

  it 'should add a package to a filesystem' do
    @pkg['pkg_remote_url'] = @url
    @pack.download(@pkg)
    @pack.add_pkg_to_fs(@pkg)
    FileTest.exists?(@pkg['install_path']).should be_true

  end

  it 'should install item to db and fs' do
    @pkg['pkg_remote_url'] = @url
    @pack.install(@pkg)
    FileTest.exists?(@pkg['install_path']).should be_true
    FileTest.exists?(@pack.db_filepath(@pkg)).should be_true
  end

  it "should be able to detect if the given package already exists" do
    @pack.install(@pkg)
    @pack.pkg_exists_in_db?(@pkg).should be_true
    @pack.pkg_exists_in_fs?(@pkg).should be_true
    @pack.exists?(@pkg).should be_true
  end

  it "should be able to detect if the given package doesn't exist" do
    @pack.uninstall(@pkg)
    @pack.exists?(@pkg).should be_false
  end

  it 'should be able to remove a package from the database' do
    @pkg['pkg_remote_url'] = @url
    @pkg['checksum'] = 'blahblahblah'
    @pack.add_pkg_to_db(@pkg)
    @pack.pkg_exists_in_db?(@pkg).should be_true
    @pack.remove_pkg_from_db(@pkg)
    @pack.pkg_exists_in_db?(@pkg).should be_false
  end

  it 'should be able to remove a package from the filesystem' do
    @pkg['pkg_remote_url'] = @url
    @pack.install(@pkg)
    @pack.exists?(@pkg).should be_true
    @pack.remove_pkg_from_fs(@pkg)
    @pack.pkg_exists_in_fs?(@pkg).should be_false
  end

  it 'should be able to uninstall a package' do
    @pack.install(@pkg)
    @pack.exists?(@pkg).should be_true
    @pack.uninstall(@pkg)
    @pack.exists?(@pkg).should be_false

  end

  it "should return a remote checksum when no remote checksum url is provided" do
    @pack.install(@pkg)
    @pack.remote_checksum(@pkg).should eq(@pkg['checksum'])
  end

  it 'should be able to determine if the installed package is the latest' do
      @pack.install(@pkg)
      @pack.latest?.should be_true
  end

  # I am expecting that I don't have to add the logic to not download already installed items.
  #it 'should not download and install package if the latest is installed' do
  #  @pack.should_receive(:download).exactly(1).times
  #  @pack.install
  #  @pack.install
  #
  #
  #end
  #
  #it 'should not redownload a package if the package is already installed when checksum is provided' do
  #  fail
  #end


end
