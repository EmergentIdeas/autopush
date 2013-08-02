# Why

This script provides an easy way to setup up a batch process to add, commit, and push
changes in a git repository to a remote server. I'm using this because I have 
repos on a server that have file additions and changes which are being made by an
application that I want to make sure I "backed-up" (not lost by server crash). I've
decided I might as well push them to the repo. I've chosen to use the default branch
"deployed" so that, while the changes are saved, there are no potential problems of
having the remote branch ahead of the local branch, and thus having the push fail. Also,
this prevents a defacto "blessing" of the generated content if it were pushed to the "master"
branch (or whatever the locally deployed branch is).

# Setup

1. Install perl
2. If using the email support, install postfix and mailutils
3. Download the script https://raw.github.com/EmergentIdeas/autopush/master/autopush.pl
4. Modify and uncomment the email to/from/subject variables if you want to be sent emails.
5. Create /etc/autopush.conf
6. Add entries (as explained in the script) to autopush.conf like: &lt;path&gt; [&lt;repo&gt;] [&lt;branch_refspec&gt;]
7. Copy the script to /etc/cron.daily
8. Change x bit so it can be run.

