use MooseX::Declare;

use strict;
use warnings;

class Common with (Logger, Agua::Common::Util) {

#####////}}}}}

# Integers
has 'log'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 5 );

# Objects
has 'ops'		=> ( isa => 'Agua::Ops', is => 'rw', lazy => 1, builder => "setOps" );
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );
has 'synapse'	=> ( isa => 'Synapse', is => 'rw', lazy => 1, builder => "setSynapse" );

use Conf::Yaml;
use Agua::Ops;

method latestVersion ($package) {
	#$self->logDebug("package", $package);
	my $subkey	=	undef;
	my $installations	=	$self->conf()->getKey("packages:$package", $subkey);
	my $versions;
	@$versions	=	keys %$installations;
	#$self->logDebug("versions", $versions);

	$versions	=	$self->ops()->sortVersions($versions);
	$self->logDebug("versions", $versions);
	
	my $latest	=	$$versions[ scalar(@$versions) - 1];
	$self->logDebug("latest", $latest);
	
	return $latest;
}

method setConf {
	my $conf 	= Conf::Yaml->new({
		backup		=>	1,
		log			=>	$self->log(),
		printlog	=>	$self->printlog()
	});
	
	$self->conf($conf);
}

method setOps {
	my $ops = Agua::Ops->new({
		conf		=>	$self->conf(),
		log			=>	$self->log(),
		printlog	=>	$self->printlog()
	});

	$self->ops($ops);	
}

method getHomeDir {
	return $ENV{"HOME"};
}

method getUserName {
	return $ENV{"USER"};
}

method getCpus {
	my $cpus	=	`cat /proc/cpuinfo | grep processor | wc -l`;
	$cpus 	=~ s/\s+$//;

	return $cpus;
}

#### DIRECTORY
method getInstallDir ($packagename) {
	$self->logDebug("packagename", $packagename);

	my $packages = $self->conf()->getKey("packages:$packagename", undef);
	$self->logDebug("packages", $packages);
	my $version	=	undef;
	foreach my $key ( %$packages ) {
		$version	=	$key;
		last;
	}

	my $installdir	=	$packages->{$version}->{INSTALLDIR};
	$self->logDebug("installdir", $installdir);
	
	return $installdir;
}

method changeDir($directory) {
	$self->logNote("directory", $directory);
	my $cwd = $self->cwd();
	if ( defined $cwd and $directory !~ /^\// ) {
		$cwd =~ s/\/$//;
		$cwd = "$cwd/$directory";
		return 0 if not $self->foundDir($cwd);
		return 0 if not chdir($cwd);
		$self->cwd($cwd);
	}
	else {
		return 0 if not $self->foundDir($directory);
		return 0 if not chdir($directory);
		$self->cwd($directory);
		$cwd = $directory;
	}
	
	return 1;
}

method foundDir($directory) {
	return 1 if -d $directory;
	return 0;
}

#### GET FILES
method fileContents ($file) {
	$self->logNote("file", $file);
	open(FILE, $file) or $self->logCritical("Can't open file: $file") and exit;
	my $temp = $/;
	$/ = undef;
	my $contents = 	<FILE>;
	close(FILE);
	$/ = $temp;

	return $contents;
}

method getFastqGzFiles ($directory) {
	$self->logDebug("directory", $directory);
	my $regex	=	"\\.fq\\.gz\$";
	
	return $self->getFilesByRegex($directory, $regex);
}

method getBamFiles ($directory) {
	$self->logDebug("directory", $directory);
	my $regex	=	"\\.bam\$";
	
	return $self->getFilesByRegex($directory, $regex);
}

method getFilesByRegex ($directory, $regex) {
	my $files	=	$self->getFiles($directory);
	$self->logDebug("files", $files);
	
	for ( my $i = 0; $i < @$files; $i++ ) {
		if ( $$files[$i] !~ /$regex/ ) {
			splice (@$files, $i, 1);
			$i--;
		}
	}
	$self->logDebug("Returning files", $files);
	
	return $files;
}


method getFiles ($directory) {
	$self->logDebug("directory", $directory);

	opendir(DIR, $directory) or $self->logDebug("Can't open directory", $directory);
	my $files;
	@$files = readdir(DIR);
	closedir(DIR) or $self->logDebug("Can't close directory", $directory);

	for ( my $i = 0; $i < @$files; $i++ ) {
		if ( $$files[$i] =~ /^\.+$/ ) {
			splice @$files, $i, 1;
			$i--;
		}
	}

	for ( my $i = 0; $i < @$files; $i++ ) {
		my $filepath = "$directory/$$files[$i]";
		if ( not -f $filepath ) {
			splice @$files, $i, 1;
			$i-- 
		}
	}

	return $files;
}



#### COMMAND
method runCommand ($command) {
	$self->logDebug("command", $command);
	
	return `$command`;
}


}

