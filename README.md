ArchiveManager (An archive package manager for nonroot users)
==============
WHY
--------------
Because some people don't have root access to install tar archives.  Installing via RPM, DEB package would be preferred but not always possible.

HOW
--------------
By using similar techniques as RPM and YUM to maintain the state of a packaged archive on a system

While this project is still in alpha stages it aims to bring a RPM / YUM like manager to the non root user. Installation of a application tar archive has always been a pain and this code aaims to ease the pain.  This code can eventually be used either directly on the command line or in a future native puppet type/provider.  Chef, ansible, salt stack contributions welcomed.
I haven't' started with the native puppet type/provider yet but my plans are to create a base provider that can easily be overloaded by providers to point to different download endpoints.

So imagine having a new kind of base package provider that doesn't require root and retrieves from any kind of server you can imagine. 
This package manager would be OS agnostic and only require ruby.

Code like the following would install, download and maintain the state of the archive

Examples
-----------------

Example native puppet type/provider  that has not been written yet

```
archivemanager{"freeipmi":
	provider => 'base',
	ensure   => 'present',
        install_path => '/usr/local/freeipmi',
        version => '1.3.2',
        source_path => 'http://ftp.gnu.org/gnu/freeipmi/freeipmi-1.3.2.tar.gz',
        package_type => 'tar.gz',
        overwrite => 'true',
}

archivemanager{"theforeman":
	provider => 'github',
	ensure => 'present',
	install_path => '/usr/local/freeipmi',
	version => '1.3',
        package_type => 'tar.gz',
	source => 'theforeman/foreman',
}

archivemanager{"jenkins":
	provider => 'nexus',
	ensure => 'present',
	version => '1.3.9',
	group => 'org.jclouds.labs',
	package_type => 'jar',
	server => 'http://nexusserver.company.com/nexus',
	classifier => 'exec-war',
}
```

