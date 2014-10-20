use MooseX::Declare;

use strict;
use warnings;

class LaneFastq extends Common {

#####////}}}}}

use FindBin qw($Bin);

use Agua::CLI::App;

use Conf::Yaml;

# Strings
has 'uuid'			=> 	( isa => 'Str|Undef', is => 'rw', required 	=> 0 );
has 'sleep'			=> 	( isa => 'Str|Undef', is => 'rw', default	=>	10 );
has 'version'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"v1.0.4" );

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );


method splitBam ($inputfile, $outputdir, $workdir, $version) {
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("workdir", $workdir);
	$self->logDebug("version", $version);

	$version	=	$self->version() if not defined $version;
	$self->logDebug("FINAL version", $version);
	
	my $package = $self->conf()->getKey("packages:pcap", undef);
	$self->logDebug("package", $package);
	my $installdir	=	$package->{$version}->{INSTALLDIR};
	$self->logDebug("installdir", $installdir);
	my ($basedir)		=	$installdir	=~	/^(.+?)\/[^\/]+$/;
	$self->logDebug("basedir", $basedir);
	my $bamtofastq	=	 "$basedir/apps-$version/bin/bamtofastq";
	$self->logDebug("bamtofastq", $bamtofastq);

	#### CREATE OUTPUTDIR
	`mkdir -p $outputdir` if not -d $outputdir;
	
	#### RUN
	my $command	= qq{$bamtofastq \\
outputperreadgroup=1 \\
gz=1 \\
level=1 \\
inputbuffersize=2097152000 \\
tryoq=1 \\
outputdir=$outputdir \\
T=`mktemp -p /tmp bamtofastq_XXXXXXXXX` \\
<  $inputfile
};
	$self->logDebug("command", $command);

	print "LaneFastq    command: $command\n";
	`$command`;
}



	
}

