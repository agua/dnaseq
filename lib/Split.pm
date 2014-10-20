use MooseX::Declare;

use strict;
use warnings;

class Split extends Common {

#####////}}}}}

use FindBin qw($Bin);

use Agua::CLI::App;

use Conf::Yaml;

# Strings
has 'uuid'			=> 	( isa => 'Str|Undef', is => 'rw', required 	=> 0 );
has 'sleep'			=> 	( isa => 'Str|Undef', is => 'rw', default	=>	10 );
has 'version'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"0.0.1" );

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );


method split ($uuid, $inputfile, $outputdir, $workdir, $version) {
	$self->logDebug("uuid", $uuid);
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("workdir", $workdir);
	$self->logDebug("version", $version);

	$version	=	$self->version() if not defined $version;
	$self->logDebug("FINAL version", $version);
	
	my $package = $self->conf()->getKey("packages:pancancer", undef);
	$self->logDebug("package", $package);
	my $installdir	=	$package->{$version}->{INSTALLDIR};
	$self->logDebug("installdir", $installdir);
	my $executable	=	 "$installdir/pcap_split/pcap_split.py";

	#### SET THREADS	
	my $threads		=	$self->getCpus();
	print "threads: $threads\n";
	
	#### RUN
	my $command	= qq{$executable \\
--bam_path $inputfile \\
--output_dir $outputdir \\
--work_dir $workdir/$uuid \\
--tumor_id $uuid \\
--normal_id $uuid
};
	$self->logDebug("command", $command);

	print "Bwa    command: $command\n";
	`$command`;
}


	
}

