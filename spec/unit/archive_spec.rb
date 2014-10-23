require 'spec_helper'

describe Logicminds::ArchiveManager::Archive do

  before :all do
    @archive = Logicminds::ArchiveManager::Archive.new('testarchive',
      '/tmp/install_path', 'http://www.archive.org/testarchive.tar.gz', 'zip', '1.2.3',
      'http://www.archive.org/testarchive.tar.gz.sha1' )
  end

  it 'can initialize' do
    @archive.should_not be_nil
    @archive.name.should eq('testarchive')
    @archive.install_path.should eq('/tmp/install_path')
    @archive.pkg_remote_url.should eq('http://www.archive.org/testarchive.tar.gz')
    @archive.remote_checksum_url.should eq('http://www.archive.org/testarchive.tar.gz.sha1')
    @archive.version.should eq('1.2.3')
    @archive.package_type.should eq('zip')

  end

  it 'should return array' do
    @archive.to_a.should be_instance_of(Array)
    @archive.to_a.length.should == 12
  end

  it 'spits out valid json' do
    JSON.parse(@archive.to_json).should_not be_nil
  end

  it 'spits out valid json' do
    JSON.parse(@archive.to_s).should_not be_nil
  end
end
