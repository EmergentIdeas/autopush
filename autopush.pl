#!/usr/bin/perl

# This script provides an easy way to setup up a batch process to add, commit, and push
# changes in a git repository to a remote server. I'm using this because I have 
# repos on a server that have file additions and changes which are being made by an
# application that I want to make sure I "backed-up" (not lost by server crash). I've
# decided I might as well push them to the repo. I've chosen to use the default branch
# "deployed" so that, while the changes are saved, there are no potential problems of
# having the remote branch ahead of the local branch, and thus having the push fail. Also,
# this prevents a defacto "blessing" of the generated content if it were pushed to the "master"
# branch (or whatever the locally deployed branch is).


# The location of the config file that tells what to push
# The format of this file is one line per backup instruction
# The instructions are in the format:
# <path> [<repo>] [<branch_refspec>]
# Wildcards are allowed in the path spec
# An example would be:
# /tmp/two origin HEAD:deployed
# Note here the branch spec says to push the current branch (whatever it is)
# to the branch named "deployed". If the current branch is not specified then
# git sometimes returns an error that it doesn't know what to push. 
$configFileLocation = '/etc/autopush.conf';

# git defaults
$defaultRepo = 'origin';
$defaultBranch = 'HEAD:deployed';

$emailTo = 'dan@emergentideas.com';
$emailFrom = 'dan@emergentideas.com';
$emailSubject = 'autopush';

$now = localtime;
$serverName = `hostname`;
$emailTempPath = "/tmp/autopushmail";
$emailResponse = "An autopush from $serverName at $now. \n";

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
#				print "$expdir $repo $branch \n";
				processDirectory($expdir, $repo, $branch);
			}			
	}
	else {
#		print "$location $repo $branch \n";
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
	
	my $cmd = "cd $dir; git add -A; git commit -m now; git push $repo $branch";
	$emailResponse = $emailResponse . `$cmd` . "\n";
}

sub sendResponseEmail {
	if($emailTo and $emailFrom and $emailSubject) {
		open(MAIL, $emailTempPath);
		print MAIL "To: $emailTo\n";
		print MAIL "From: $emailFrom\n";
		print MAIL "Subject: $emailSubject\n";
		print MAIL $emailResponse;
		close(MAIL);
		issueSendEmailCommand();
	}
}

sub issueSendEmailCommand {
	print `mail $emailTo < $emailTempPath`;
}