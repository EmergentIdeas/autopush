# What

This script provides an easy way to setup up a batch process to add, commit, and push
changes in a git repository to a remote server. It uses the profile owning the ".git" 
directory to make the commits so that if the script is run by root (as might happen as a cron
job) a later luser doesn't find it impossible to make commits to the repo.


# Why

I like to use private git repos as a way to deploy code to servers because:

1. It's secure
2. It's easy to add a bunch of files atomically and version them
3. It's easy to deploy a new installation
4. If a particular build is f'd (which is only discovered on prod), all I have to do is checkout HEAD~1 and I'm back in business
5. It's easy to copy changes made on an installation back into a development environment

It's number 5 that's prompted this script. I'm using this because I have 
repos on a server that have file additions and changes which are being made by a
user that I want to make sure I "back-up" (not lost by server crash). I've
decided I might as well push them to the repo. This makes them available to me so that I can set
up a realistic test environment and I can be sure they aren't lost.

I've chosen to commit and push all the changes to a branch other the the one currently checked out. I'm using
the name "deployed", but you can use whatever you want. The important thing is that nothing else will ever try to
push to this branch. This way all the changes get saved and there are no potential problems of
having the remote branch ahead of the local branch, and thus having the push fail. Also,
this prevents a defacto "blessing" of the generated content if it were pushed to the "master"
branch (or whatever the locally deployed branch is).


# Setup

1. Install perl
2. If using the email support, install postfix and mailutils packages, or whatever it is that will allow the script to run the "mail" program from the command line.
3. Download the script https://raw.github.com/EmergentIdeas/autopush/master/autopush.pl
4. Modify and uncomment the email to and subject variables if you want to be sent emails.
5. Create /etc/autopush.conf
6. Add entries (as explained in the script) to autopush.conf like: &lt;path&gt; [&lt;repo&gt;] [&lt;branch_refspec&gt;]  See example below.
7. Copy or link the script to /etc/cron.daily
8. Change x bit so it can be run.


# Configuration

My /etc/autopush.conf file looks like this:

> /apps/* origin HEAD:deployed

Paths can use wildcards. Each path will be checked for a sub directory named ".git". If the sub directory does not exist no processing will be done
on the directory. This makes expansions pretty safe. "git init" will never be run. Make sure the ".git" directory is owned by the user you want 
to be making the adds, commits, and pushes.


