use MooseX::Declare;

use strict;
use warnings;

class FreeBayes extends Common with Agua::Common::Database {

#####////}}}}}

use FindBin qw($Bin);

use Agua::CLI::App;
use Synapse;

use Conf::Yaml;

# Strings
has 'uuid'			=> 	( isa => 'Str|Undef', is => 'rw', required 	=> 	0 );
has 'sleep'			=> 	( isa => 'Str|Undef', is => 'rw', default	=>	10 );
has 'options'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"--min-alternate-fraction 0.03 --no-complex" );
has 'version'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"v9.9.13" );

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );
has 'db'			=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );

method callVariants ($uuid, $inputdir, $outputdir, $reference, $version, $target, $options, $workdir) {
	$self->logDebug("uuid", $uuid);
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("version", $version);
	$self->logDebug("reference", $reference);
	$self->logDebug("target", $target);
	$self->logDebug("options", $options);
	$self->logDebug("workdir", $workdir);

	#### SET VERSION
	$version	=	$self->version() if not defined $version;
	$self->logDebug("FINAL version", $version);
	
	#### GET EXECUTABLE
	my $installdir	=	$self->getInstallDir("freebayes");
	$self->logDebug("installdir", $installdir);
	my $executable	=	 "$installdir/bin/freebayes";
	$self->logDebug("executable", $executable);

	print "Returning because SRA ID ($uuid) is not first in sample\n" and return if $uuid	=~	/^SRR/ and not $self->isFirstSample($uuid);

	#### GET BAM FILES IN INPUT DIR
	my $bamfiles 	= $self->getBamFiles($inputdir);
	print "bamfiles not defined\n" and exit if not defined $bamfiles;

	#### CREATE OUTPUT DIR
	`mkdir -p $outputdir` if not -d $outputdir;
	
	if ( defined $workdir ) {
		#### SET OUTPUT FILE
		my $outputfile		=	"$workdir/$uuid.vcf";
		$self->logDebug("outputfile", $outputfile);
	
		#### GET DEFAULT OPTIONS
		$options	=	$self->options() if not defined $options;
		
		#### COPY BAM FILES
		my $bamfiles	=	$self->copyBamFiles($bamfiles, $inputdir, $workdir);
	
		my $command	= qq{$executable \\
-f $reference \\
$options \\
@$bamfiles \\
> $outputfile};
		
		$command	= qq{$executable \\
-f $reference \\
-t $target \\
--min-alternate-fraction 0.03 \\
@$bamfiles \\
> $outputfile} if defined $target;
		
		print "$command\n";
		print `$command`;
	
		#### COPY FILE TO OUTPUT DIR
		$command	=	"mv $outputfile $outputdir/$uuid.vcf";
		print "$command\n";
		print `$command`;
		
		#### DELETE COPIED BAM FILES
		foreach my $bamfile ( @$bamfiles ) {
			my $command	=	"rm -fr $bamfile*";
			print "$command\n";
			print `$command`;
		}
	}
	else {
		
		#### SET FULL PATHS
		foreach my $bamfile ( @$bamfiles ) {
			$bamfile	=	"$inputdir/$bamfile";
		}

		#### SET OUTPUT FILE
		my $outputfile		=	"$outputdir/$uuid.vcf";
		$self->logDebug("outputfile", $outputfile);
	
		#### GET DEFAULT OPTIONS
		$options	=	$self->options() if not defined $options;
	
		my $command	= qq{$executable \\
-f $reference \\
$options \\
@$bamfiles \\
> $outputfile};
		
		$command	= qq{$executable \\
-f $reference \\
-t $target \\
--min-alternate-fraction 0.03 \\
@$bamfiles \\
> $outputfile} if defined $target;
		
		print "$command\n";
		print `$command`;
	}
}

method copyBamFiles ($bamfiles, $inputdir, $workdir) {
	$self->logDebug("bamfiles", $bamfiles);
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("workdir", $workdir);

	#### COPY FILES
	foreach my $bamfile ( @$bamfiles ) {
		my $command	=	"cp $inputdir/$bamfile* $workdir";
		$self->logDebug("command", $command);
		`$command`
	}

	#### SET FULL PATHS
	foreach my $bamfile ( @$bamfiles ) {
		$bamfile	=	"$workdir/$bamfile";
	}

	return $bamfiles;	
}

method isFirstSample ($uuid) {
	$self->logDebug("uuid", $uuid);

	#### TABLE	
	my $table	=	"srasample";
	$self->logDebug("table", $table);

	#### SET DATABASE HANDLE
	$self->setDbh() if not defined $self->db();
	
	#### GET SAMPLE HASH
	my $samplehash	=	$self->getSampleHash($table, $uuid);
	$self->logDebug("samplehash", $samplehash);

	my $samplename	=	$samplehash->{samplename};
	$self->logDebug("samplename", $samplename);
	my $samples		=	$self->getSamplesBySampleName($table, $samplename);
	print "No samples for uuid: $uuid\n" and exit if not defined $samples;	

	#$self->logDebug("samples:");
	#foreach my $sample ( @$samples ) {
	#	print "$sample->{sample}\n";
	#}

	my $firstuuid	=	$$samples[0]->{sample};
	$self->logDebug("firstuuid", $firstuuid);
	
	return 0 if $uuid ne $firstuuid;
	return 1;
}

method getSampleHash ($table, $sample) {
	my $query		=	qq{SELECT * FROM $table
WHERE sample='$sample'};
	$self->logDebug("query", $query);
	my $samplehash	=	$self->db()->queryhash($query);
	$self->logDebug("samplehash", $samplehash);
	
	return $samplehash;
}

method getSamplesBySampleName ($table, $samplename) {
	$self->logDebug("samplename", $samplename);
	my $query		=	qq{SELECT * FROM $table
WHERE samplename='$samplename'
ORDER BY sample};
	$self->logDebug("query", $query);

	my $samplehash	=	$self->db()->queryhasharray($query);
	$self->logDebug("samplehash", $samplehash);
	
	return $samplehash;
}


	
}

