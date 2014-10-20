use MooseX::Declare;

use strict;
use warnings;

class SraToBam extends Common {

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


method convert ($inputfile, $outputfile, $reference) {
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("workdir", $reference);
	
	#### GET SAM-DUMP
	my $installdir	=	$self->getInstallDir("sra");
	my $samdump		=	"$installdir/bin/sam-dump";
	$self->logDebug("samdump", $samdump);

	#### GET SAMTOOLS
	$installdir		=	$self->getInstallDir("samtools");
	my $samtools	=	"$installdir/samtools";	

	#### CREATE OUTPUTDIR
	my ($outputdir)	=	$outputfile	=~	/^(.+?)\/[^\/]+$/;
	$self->logDebug("outputdir", $outputdir);
	`mkdir -p $outputdir` if not -d $outputdir;
	
	#### RUN
	my $command	= qq{$samdump $inputfile \\
| $samtools view -bT \\
$reference - \\
> $outputfile
};
	$self->logDebug("command", $command);

	print "LaneFastq    command: $command\n";
	`$command`;
}



	
}

