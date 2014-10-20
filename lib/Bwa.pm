use MooseX::Declare;

use strict;
use warnings;

class Bwa extends Common {

#####////}}}}}

use FindBin qw($Bin);

use Agua::CLI::App;

use Conf::Yaml;

# Strings
has 'batchsize'		=> 	( isa => 'Int|Undef', is => 'rw', default	=>	5 );

# Strings
has 'sleep'			=> 	( isa => 'Str|Undef', is => 'rw', default	=>	10 );
has 'version'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"v1.0.4" );

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );


method align ($inputdir, $inputsuffix, $filename, $outputdir, $reference, $threads, $workdir, $version, $batchsize) {
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("inputsuffix", $inputsuffix);
	$self->logDebug("filename", $filename);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("workdir", $workdir);
	$self->logDebug("version", $version);
	$self->logDebug("reference", $reference);

	#### SET VERSION
	$version	=	$self->version() if not defined $version;
	$self->logDebug("FINAL version", $version);
	
	#### GET EXECUTABLE
	my $installdir	=	$self->getInstallDir("pcap");
	$self->logDebug("installdir", $installdir);
	my $executable	=	 "$installdir/bin/bwa_mem.pl";

	#### GET INPUT FILES
	my $regex		=	$inputsuffix;
	$regex			=~	s/\./\\./g;
	$regex			.= 	"\$";
	$self->logDebug("regex", $regex);
	my $inputfiles	=	$self->getFilesByRegex($inputdir, $regex);
	$self->logDebug("inputfiles", $inputfiles);
	foreach my $inputfile ( @$inputfiles ) {
		$inputfile	=	"$inputdir/$inputfile";
	}

	#### SET FILE STUB
	my ($filestub)	=	$filename	=~ /^(.+)\.[^\.]+$/;
	$self->logDebug("filestub", $filestub);
	
	#### SET THREADS	
	$threads		=	$self->getCpus() if not defined $threads;
	print "threads: $threads\n";
	
	#### RUN
	$batchsize	=	$self->batchsize() if not defined $batchsize;
	$self->logDebug("batchsize", $batchsize);

	#### CREATE OUTPUTDIR
	`mkdir -p $outputdir` if not -d $outputdir;
	
	my $counter 	= 	1;
	while ( scalar(@$inputfiles) > 0 ) {
		my $batch;
		@$batch		=	splice(@$inputfiles, 0, $batchsize);
		$self->logDebug("batch", $batch);
		
		my $outfile	=	$filestub . "-$counter";
		my $command	= "$executable -r $reference -t $threads -o $outputdir -s $outfile @$batch -workdir $workdir";
		$self->logDebug("command", $command);
	
		print "Bwa    command: $command\n";
		
		`$command`;

		$counter++;
	}
}




	
}

