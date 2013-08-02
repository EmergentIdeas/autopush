#/usr/bin/perl

# The location of the config file that 
$configFileLocation = '/etc/autopush.conf';

# git defaults
$defaultRepo = 'origin';
$defaultBranch = 'master';

# handle command line parameters
if ( @ARGV > 0 ) {

	$parm1 = shift @ARGV;
	if($parm1 eq '--help' or $parm1 eq '-h') {
		printHelp();
		exit;
	}
	
	# check to see if the config file location exists
	-e $parm1 or die "The config file location $parm1 can not be found.\n" . getHelpMsg();
	$configFileLocation = $parm1;
}
else {
	# test the default location
	-e $parm1 or die "The config file location $configFileLocation can not be found.\n";
}



print $configFileLocation . "\n";


# load the locations to push
open LOCS, "< $configFileLocation" or die "unable to open configuration file: $configFileLocation";

while(<LOCS>) {
	chomp;
	(my $location, my $repo, my $branch) = split /\s+/;
	if(!$repo) {
		$repo = $defaultRepo;
	}
	if(!$branch) {
		$branch = $defaultBranch;
	}
	
	
	if(index($location, '*') != -1 or index($location, '?') != -1) {
			$findCommand = "ls -d $location 2>/dev/null";
			@expanded = `$findCommand`;
			foreach my $expdir (@expanded) {
				chomp $expdir;
				print "$expdir $repo $branch \n";
				processDirectory($expdir, $repo, $branch);
			}			
	}
	else {
		print "$location $repo $branch \n";
		processDirectory($location, $repo, $branch);
	}
}



sub printHelp {
		print getHelpMsg();
}

sub getHelpMsg() {
	"This program takes commands in the form of: autopush.pl <config-file-location>\n";
}

sub processDirectory {
	my $dir = shift @_;
	my $repo = shift @_;
	my $branch = shift @_;
	
	print `cd $dir`;
	print `git add -A`;
	print `git commit -m "now"`;
	print 'git push $repo $branch';
}