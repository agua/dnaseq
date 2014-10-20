use MooseX::Declare;

use strict;
use warnings;

class Mutect extends Common {

#####////}}}}}

use FindBin qw($Bin);

use GT::Query;
use Conf::Yaml;

# Strings
has 'uuid'			=> 	( isa => 'Str|Undef', is => 'rw', required 	=> 	0 );
has 'sleep'			=> 	( isa => 'Str|Undef', is => 'rw', default	=>	10 );
has 'options'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	undef );
has 'version'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"v0.9.9.2" );

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );

method callVariants ($uuid, $tumourfile, $normalfile, $outputdir, $version, $intervalfile, $options, $reference, $cosmic, $dbsnp) {
	$self->logDebug("uuid", $uuid);
	$self->logDebug("tumourfile", $tumourfile);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("version", $version);
	$self->logDebug("intervalfile", $intervalfile);
	$self->logDebug("options", $options);
	$self->logDebug("reference", $reference);
	$self->logDebug("cosmic", $cosmic);
	$self->logDebug("dbsnp", $dbsnp);

	my $query	=	GT::Query->new({
		log			=> $self->log(),
		printlog	=>	$self->printlog()
	});
	$self->logDebug("query", $query);

	#### GET TCGA SAMPLE INFO
	my $info	=	$query->getAnalysisHash($uuid);
	$self->logDebug("info", $info);
	my $sampletype	=	$info->{sampletype};
	my $description	=	$query->getSampleDescription($sampletype);
	$self->logDebug("description", $description);
	
	#### QUIT IF NORMAL
	return if $self->isNormal($info);
	
	#### GET NORMAL MATE
	if ( not defined $normalfile ) {
		my $mate	=	$query->getMate($uuid);
		$normalfile	=	$self->getNormalFile($tumourfile, $mate);
	}
	$self->logDebug("normalfile", $normalfile);
	
	#### SET VERSION
	$version	=	$self->version() if not defined $version;
	$self->logDebug("FINAL version", $version);

	#### GET JAVA
	my $installdir	=	$self->getInstallDir("java");
	$self->logDebug("installdir", $installdir);
	my $java	=	"$installdir/bin/java";
	$self->logDebug("java", $java);
	print "App::Mutect    java installdir $installdir not found\n" and exit if not defined $installdir;

	#### GET MUTECT
	$package = $self->conf()->getKey("packages:mutect", undef);
	$self->logDebug("package", $package);
	print "App::Mutect    executable for version $version not found\n" and exit if not defined $package->{$version};
	$installdir	=	$package->{$version}->{INSTALLDIR};
	$self->logDebug("installdir", $installdir);
	my $executable	=	 "$installdir/mutect.jar";
	$self->logDebug("executable", $executable);

	my $bamfiles	=	$self->getBamFiles($tumourfile);
	$self->logDebug("bamfiles", $bamfiles);
	foreach my $bamfile ( @$bamfiles ) {
		$bamfile	=	"$tumourfile/$bamfile";
	}

	my $outputfile		=	"$outputdir/$uuid.vcf";
	$self->logDebug("outputfile", $outputfile);
	
	my $command	= qq{$java $executable \\
java -Xmx2g -jar muTect.jar \
--analysis_type MuTect \
--reference_sequence $reference \\
--cosmic $cosmic \\
--dbsnp $dbsnp \\
--intervals $intervalfile \\
--input_file:normal $normalfile \\
--input_file:tumor $tumourfile \\
--out $outputfile};
	
	$command	.=	qq{ \\
$options} if defined $options and $options ne "";

	print "command: $command\n";
	
	print `$command`;
}

method isNormal ($info) {
	$self->logDebug("info", $info);
	return	0 if $info->{sampletype} ne "10";
	
	1;	
}

method getNormalFile ($tumourfile, $mate) {
	my ($outputdir)	=	$tumourfile	=~	/^(.+?)\/[^\/]+\/[^\/]+$/;

	my $analysisid	=	$mate->{analysisid};
	my $filename	=	$mate->{filename};
	
	return "$outputdir/$uuid/"
}




}

