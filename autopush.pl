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

# system information
$now = localtime;
$serverName = `hostname`;
chomp $serverName;


# git defaults
$defaultRepo = 'origin';
$defaultBranch = 'HEAD:deployed';

# A path to hold a script for running complex commands as another user
$scriptTempPath = "/tmp/autopushcommands.sh";

# variables for sending email
$emailTempPath = "/tmp/autopushmail";
$emailResponse = "An autopush from $serverName at $now. \n";


# email notification info, comment out for no email, uncomment to send email
#$emailTo = 'somebody@somewhere.com';
$emailFrom = 'somebody@somewhere.com';
$emailSubject = "autopush $now";


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
	-e $configFileLocation or die "The config file location $configFileLocation can not be found.\n";
}


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
		# expand any locations that have a wildcard so that a single conf rule can
		# be written for an entire class of files
		$findCommand = "ls -d $location 2>/dev/null";
		@expanded = `$findCommand`;
		foreach my $expdir (@expanded) {
			chomp $expdir;
			processDirectory($expdir, $repo, $branch);
		}			
	}
	else {
		processDirectory($location, $repo, $branch);
	}
}

# send an email if to/from/subject variables are set about what happened
sendResponseEmail();

# print the help message
sub printHelp {
		print getHelpMsg();
}

# gets the actual text that describes the command format
sub getHelpMsg() {
	"This program takes commands in the form of: autopush.pl <config-file-location>\n";
}

# add all new, updated, and deleted files, commit the changes, push the changes to a remote branch
sub processDirectory {
	my $dir = shift @_;
	my $repo = shift @_;
	my $branch = shift @_;
	
	my $gitdir = $dir . "/.git";
	
	# checking to see if there is a .git directory here
	# if not, we shouldn't process this directory since it will fail
	-e $gitdir or return;
	
	# returns the user id of the directory so that we can run the git process as that user
	# this will allow us to create and modify files without making them inaccessible to future use
	# and (hopefully) reuse ssh config files of the owner
	my $uid = (stat $gitdir)[4];
	
	my $cmd = "cd $dir 2>&1  \ngit add -A 2>&1 \ngit commit -m now 2>&1 \ngit push $repo $branch 2>&1";	
	open(CMDFILE, ">" . $scriptTempPath);
	print CMDFILE '#!/bin/bash' . "\n";
	print CMDFILE $cmd;
	close(CMDFILE);
	$cmd = "sudo -u \\#$uid bash $scriptTempPath";
	$emailResponse = $emailResponse . `$cmd` . "\n";
}

# create and send the response email. to/from/subject variables must be set
sub sendResponseEmail {
	if($emailTo and $emailFrom and $emailSubject) {
		open(MAIL, ">" . $emailTempPath);
		print MAIL "To: $emailTo\n";
		print MAIL "From: $emailFrom\n";
		print MAIL "Subject: $emailSubject\n\n";
		print MAIL $emailResponse;
		close(MAIL);
		issueSendEmailCommand();
	}
	else {
		print "No email sent. Messages are:\n". $emailResponse;
	}
}

# issue the actual command that mails our temp file
sub issueSendEmailCommand {
	my $cmd = "mail -s '$emailSubject' $emailTo < $emailTempPath";
	print `$cmd`;
}