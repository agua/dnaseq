use MooseX::Declare;

use strict;
use warnings;

class Aspera extends Common {

#####////}}}}}

use FindBin qw($Bin);

use Agua::CLI::App;
use Conf::Yaml;

# Integers
has 'sleep'			=> 	( isa => 'Str|Undef', is => 'rw', default	=>	10 );

# Strings
has 'keyfile'		=> 	( isa => 'Str|Undef', is => 'rw', required	=>	1 );
has 'uuid'			=> 	( isa => 'Str|Undef', is => 'rw', required 	=> 	0 );
has 'version'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"3.3.3.81344" );
has 'options'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"-l200m" );

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', lazy => 1, builder => "setConf" );

method download ($url, $outputdir, $outputfile, $version, $options) {
	$self->logDebug("url", $url);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("version", $version);
	$self->logDebug("options", $options);
	
	#### SET DEFAULT VERSION
	$version	=	$self->version() if not defined $version;
	$self->logDebug("FINAL version", $version);

	#### GET OPTIONS
	$options	=	$self->options() if not defined $options;
	$self->logDebug("options", $options);

	#### GET KEY FILE	
	my $keyfile		=	$self->keyfile();
	$self->logDebug("keyfile", $keyfile);
	
	#### GET EXECUTABLE
	my $installdir	=	$self->getInstallDir("aspera");
	$self->logDebug("installdir", $installdir);
	my $executable	=	"$installdir/bin/ascp";
	
	#### CREATE OUTPUT DIR
	`mkdir -p $outputdir` if not -d $outputdir;
	
	my $srafile	=	"$outputdir/$outputfile";
	if ( -f $srafile ) {
		if ( $self->validateFile($srafile) ) {
			print "Skipping download because downloaded file found and validated: $srafile\n";
			print "\n";
			return;
		}
	}

	#### RUN
	my $command		= qq{$executable \\
-i $keyfile  \\
$options \\
$url  \\
$outputdir/$outputfile
};
	$self->logDebug("command", $command);

	#### PRINT COMMAND
	print "\n$command\n";

	`$command`;
}

method validateFile ($srafile) {

=doc

=head2 	SUBROUTINE	fileValidate

=head2	PURPOSE		Return 1 if SRA file validates, otherwise return 0

=cut

	my $installdir	=	$self->getInstallDir("sra");
	
	my $executable	=	"$installdir/bin/vdb-validate";
	my $outputfile	=	"$srafile.validate";
	my $command		=	"$executable $srafile 2> $outputfile";
	$self->logDebug("command", $command);
	`$command`;
	
	my $contents	=	$self->fileContents($outputfile);
	$self->logDebug("contents", $contents);
	
	return 0 if not defined $contents or $contents =~ /^\S*$/;

	my $lines;
	@$lines		=	split "\n", $contents;

	foreach my $line ( @$lines ) {
		if ( $line !~ /ok$/ and $line	!~	/is consistent$/ ) {
			$self->logDebug("returning 0");
			return 0;
		}
	}
	
	$self->logDebug("returning 1");
	return 1;
}

	
}

