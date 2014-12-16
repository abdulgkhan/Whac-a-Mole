#!/usr/bin/perl -w -T

# This code will accept a username and password from home.pl

# It will validate the username and password to ensure they
# only contain alphanumeric characters

# It will see if the username password combination exist
# in the "passwd" file.  The password will be encrypted
# using the SHA-512 algorithm with a salted hash. 

# If the username does not exist in the passwd file a
# new account will be created

# If the password does not match what is stored in the passwd file
# for that username a Login Failed message will appear.

# If the username and password pass Authentication a new CGI::Session
# is created for the user to play Whac-A-Mole and a form is given
# to them that will put the session id cookie into their browser and
# redirect them to play.pl when they submit it. 

use strict;
use CGI;
use CGI::Session;
use Crypt::SaltedHash;

sub validateName {
        return ($_[0] =~ /^[a-zA-Z0-9_.]{1,20}$/);
}
sub validatePassword {
        return ($_[0] =~ /^[a-zA-Z0-9_.]{1,20}$/);
}
sub checklogin {
        my ($username,$password) = @_;
        my $crypt = Crypt::SaltedHash->new(alogrithm=>'SHA-512');
        open READFILE, '<', "passwd";
        if ( fileno(READFILE) != -1 ) {
                while ( my $line = <READFILE> ) {
                        if ( $line =~ /^$username (.*)/ ) {
                                #verify salted hash
                                my ($storedsaltedhash) = ($1);
                                if ($crypt->validate($storedsaltedhash, $password) == 1) {
                                        return 0;
                                } else {
                                        return -1;
                                }
                        }
                }
                close READFILE;
        }
        # username is not yet in database
        # generate salted hash
        $crypt->add($password);
        open WRITEFILE, '>>', "passwd" or return -2;
        print WRITEFILE $username . " " . $crypt->generate() . "\n";
        close WRITEFILE;
        return 0;
}


my $query = CGI->new;

if (!validateName($query->param('username'))) {
        print "Content-type: text/html\n\n";
        print qw[<html><h1>];
        print "Invalid username " . $query->param('username') . ".  username must be alphanumeric, max 20 characters.";
        print qw[</h1></html>];
        exit 0;
}
if (!validatePassword($query->param('password'))) {
        print "Content-type: text/html\n\n";
        print qw[<html><h1>];
        print "Invalid password. The password must be alphanumeric. Between 8 and 20 characters. ";
        print qw[</h1></html>];
        exit 0;
}
if (checklogin($query->param('username'), $query->param('password')) != 0) {
        print "Content-type: text/html\n\n";
        print qw[<html><h1>];
        print "Login Failed for user " . $query->param('username');
        print qw[</h1></html>];
        exit 0;
}

#Create session for user
my $session = new CGI::Session(undef, undef, {Directory=>'/Library/WebServer/CGI-Executables'});


$session->param("username", $query->param('username'));
$session->param("opponent", undef); #Seems like opponent session data is saved even though we start a new session

my $cookie = $query->cookie(CGISESSID => $session->id);
print $query->header( -cookie=>$cookie );
print qw[<html> <center> <h1> Welcome];
print " " . $session->param('username') . "! \n<br> Are you ready to play Whac-A-Mole?";
print q[<form action="play.pl" method="POST"><input type="submit" value="yes"></form>];
print qw[</h1></center>];
print q[</html>];
