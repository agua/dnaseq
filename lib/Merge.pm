use MooseX::Declare;

use strict;
use warnings;

class Merge extends Common with Agua::Common::Database {

#####////}}}}}

=doc

=head2	PURPOSE

	1. Merge all BAM files for the same individual into a single BAM file
	
	2. Handle Short Read Archive (SRA) Chinese bladder cancer samples from the BGI.

	3. Use biobambam's bammerge to merge files
	
=head2 	NOTES

bammerge USAGE

This is biobambam version 0.0.142.
biobambam is distributed under version 3 of the GNU General Public License.

Key=Value pairs:

I=<[filename]>           : input file, can be set multiple times
SO=<[coordinate]>]       : sort order (coordinate or queryname)
level=<[-1]>             : compression settings for output bam file (0=uncompressed,1=fast,9=best,-1=zlib default)
verbose=<[1]>            : print progress report
md5=<[0]>                : create md5 check sum (default: 0)
md5filename=<filename>   : file name for md5 check sum (default: extend output file name)
index=<[0]>              : create BAM index (default: 0)
indexfilename=<filename> : file name for BAM index file (default: extend output file name)
tmpfile=<filename>       : prefix for temporary files, default: create files in current directory

=cut

use FindBin qw($Bin);

use Agua::CLI::App;

use Conf::Yaml;

# Strings
has 'uuid'			=> 	( isa => 'Str|Undef', is => 'rw', required 	=> 0 );
has 'sleep'			=> 	( isa => 'Str|Undef', is => 'rw', default	=>	10 );
has 'version'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"v1.0.4" );

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );
has 'db'			=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );


method merge ($uuid, $inputdir, $outputdir, $filename, $workdir, $version) {
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("filename", $filename);
	$self->logDebug("version", $version);

	$version	=	$self->version() if not defined $version;
	$self->logDebug("FINAL version", $version);
	
	my $package = $self->conf()->getKey("packages:pcap", undef);
	$self->logDebug("package", $package);
	my $installdir	=	$package->{$version}->{INSTALLDIR};
	$self->logDebug("installdir", $installdir);
	$installdir		=~	s/\/[^\/]+$//;
	my $executable	=	"$installdir/apps-$version/bin/bammerge";

	#### GET FIRST SAMPLE IF MULTIPLE SAMPLES
	my $inputfiles	=	$self->getSampleFiles($inputdir, $uuid) ;
	$self->logDebug("inputfiles", $inputfiles);
	print "inputfiles not defined\n" and exit if not defined $inputfiles;
	
	#### CREATE OUTPUT DIR
	`mkdir -p $outputdir` if not -d $outputdir;
	
	#### RUN
	my $command		= qq{$executable \\\n};
	foreach my $inputfile ( @$inputfiles ) {
		$command 	.=	qq{I=$inputfile \\\n};
	}
	$command		.=	qq{SO=coordinate \\
level=1 \\
verbose=1 \\
md5=0 \\
index=0 \\
tmpfile=$workdir/tmp_  \\
> $outputdir/$filename
};
	$self->logDebug("command", $command);

	print "Merge    command: $command\n";
	`$command`;
}


method getSampleFiles ($inputdir, $uuid) {
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("uuid", $uuid);

	my $table	=	"srasample";
	$self->logDebug("table", $table);

	#### SET DATABASE HANDLE
	$self->setDbh();
	
	#### GET SAMPLE HASH
	my $samplehash	=	$self->getSampleHash($table, $uuid);
	$self->logDebug("samplehash", $samplehash);

	my $samplename	=	$samplehash->{samplename};
	$self->logDebug("samplename", $samplename);
	my $samples		=	undef;
	if ( defined $samplename ) {
		$samples		=	$self->getSamplesBySampleName($table, $samplename)
	}
	$self->logDebug("samples:");
	foreach my $sample ( @$samples ) {
		print "$sample->{sample}\n";
	}
	my $firstuuid	=	$$samples[0]->{sample};
	$self->logDebug("firstuuid", $firstuuid);
	
	return if $uuid ne $firstuuid;
	
	my $samplefiles	=	[];
	my ($basedir)	=	$inputdir	=~ /^(.+)\/[^\/]+$/;
	foreach my $sample ( @$samples ) {
		$self->logDebug("sample", $sample);
		my $id	=	$sample->{sample};
		push @$samplefiles, "$basedir/$id/$id-1.bam";
	}

	return $samplefiles;
}

method getSampleHash ($table, $sample) {
	my $query		=	qq{SELECT * FROM $table
WHERE sample='$sample'};
	my $samplehash	=	$self->db()->queryhash($query);
	$self->logDebug("samplehash", $samplehash);
	
	return $samplehash;
}

method getSamplesBySampleName ($table, $samplename) {
	$self->logDebug("samplename", $samplename);
	my $query		=	qq{SELECT * FROM $table
WHERE samplename='$samplename'
ORDER BY sample};

	my $samplehash	=	$self->db()->queryhasharray($query);
	$self->logDebug("samplehash", $samplehash);
	
	return $samplehash;
}

	
}

