#!/usr/bin/perl -w -T
use strict;
use CGI;
use CGI::Session qw/-ip-match/;

sub logit { 
        open LOGFILE, '+>>', 'logfile';
        print LOGFILE localtime(time) . " " . $_[0] . "\n";
        close LOGFILE;   
} 

sub getHits {
        my ($hits, $holes) = @_;
        my $numOfHits=0;
        my $i=0;
        my @hit_array = split(/,/, $hits); 
        my @hole_array = split(/,/, $holes);
        for $i (0..4) {
                #print "testing " . $hit_array[$i] . "==" . $hole_array[$i];
                if ($hit_array[$i] == $hole_array[$i]) { 
                        $numOfHits++;
                };
        }
        return $numOfHits;
}       

sub printInvalidInput {
        print q[<html><h1> Invalid input detected.  Please fix and retry </h1></html>] . "\n";
}
sub validateName {
        return (@_[0] = (@_[0] =~ /^([a-zA-Z0-9_.]{1,20})$/));
}

# $username must be defined and can't be equal to the opponents names and both names mus pass whitelist
#sub validateNames {
#       my ($username, $opponent) = @_;
#       return (defined $username && validateName($username) && (!defined $opponent || (validateName($opponent) && ($username ne $opponent))));
#}
sub validateNames {
        return (defined @_[0] && validateName(@_[0]) && (!defined @_[1] || (validateName(@_[1]) && (@_[0] ne @_[1]))));
}

sub validatePattern {
        return (!defined $_[0] || $_[0] =~ /^([1-5],){4,4}[1-5]$/); #also need to check to make sure pattern was never used before
}sub printGameHistory {
        my ($username, $opponent) = @_;
        my $gamefile = $username . "_" . $opponent;
        my $opponentfile = $opponent . "_" . $username;

        open GAMEFILE, '<', $gamefile or do {
                print q[<center>] . $username . " and " . $opponent . " have not played any games together" . q[</center>];
                return;
        };
        open OPPONENT, '<', $opponentfile;

        my $pattern;
        my $move;
        my $opponent_pattern;
        my $opponent_move;
        print qq[<center>This is the Move History between $username and $opponent<br>First line has the holes the moles appeared<br>Second line has the whacks the user made<br>The one that whacked the most number of moles wins!<table border=1><tr><td>] . $username . q[</td><td>] . $opponent . q[</td><td>Winner</td></tr>] ;
        # may need to check length of line in case a partial write occured before reading it
        while ( defined ($pattern = <GAMEFILE>) && defined ($move = <GAMEFILE>)) {
                if ( defined ($opponent_pattern = <OPPONENT>) && defined ($opponent_move = <OPPONENT>) ) {
                        print qq[<tr><td>$opponent_pattern<br>$move</td><td>$pattern<br>$opponent_move</td><td>];
                        if (getHits($move, $opponent_pattern) == getHits($opponent_move, $pattern)) {
                                print "TIE!";
                        } elsif (getHits($move, $opponent_pattern) > getHits($opponent_move, $pattern)) {
                                print $username;
                        } elsif (getHits($move, $opponent_pattern) < getHits($opponent_move, $pattern)) {
                                print $opponent;
                        }
                }
                print q[</td></tr>];
        }
        close GAMEFILE;
        close OPPONENT;
        print q[</table></center>];
}
sub getWins {
        my ($username, $opponent) = @_;

        my $wins=0;
        my $ties=0;
        my $losses=0;

        my $gamefile = $username . "_" . $opponent;
        my $opponentfile = $opponent . "_" . $username;

        open GAMEFILE, '<', $gamefile or return 0,0,0;
        open OPPONENT, '<', $opponentfile or return 0,0,0;

        my $pattern;
        my $move;
        my $opponent_pattern;
        my $opponent_move;
        # may need to check length of line in case a partial write occured before reading it
        while ( defined ($pattern = <GAMEFILE>) && defined ($move = <GAMEFILE>)) {
                if ( defined ($opponent_pattern = <OPPONENT>) && defined ($opponent_move = <OPPONENT>) ) {
                        if (getHits($move, $opponent_pattern) == getHits($opponent_move, $pattern)) {
                                $ties++;
                        } elsif (getHits($move, $opponent_pattern) > getHits($opponent_move, $pattern)) {
                                $wins++;
                        } elsif (getHits($move, $opponent_pattern) < getHits($opponent_move, $pattern)) {
                                $losses++;
                        }
                }
        }
        close GAMEFILE;
        close OPPONENT;
        return $wins, $ties, $losses;
}

sub printGameStats {
        open READFILE, '<', "passwd" or die "Unable to open passwd file";
        my $name;
        my $opponent;
        my %players;
        while (my $line = <READFILE> ) {
                ($name) = split(/\s+/, $line);
                $players{$name} = [0,0,0];
        }
        close( READFILE );
        foreach $name ( keys %players ) {
                foreach $opponent ( keys %players ) {
                        if ($name ne $opponent ) {
                                my ($wins, $ties, $losses) = getWins($name, $opponent);
                                $players{$name}[0] += $wins;
                                $players{$name}[1] += $ties;
                                $players{$name}[2] += $losses;
                        }
                }
        }
        print q[<center>These are the Win/Tie/Loss Statistics for the Players<br><table border=1><tr><td>Player</td><td>Win</td><td>Ties</td><td>Losses</td><td>Win percentage</td></tr>] ;
        foreach $name ( keys %players ) {
                print qq[<tr><td>$name</td><td>$players{$name}[0]</td><td>$players{$name}[1]</td><td>$players{$name}[2]</td><td>];
                my $games = $players{$name}[0] + $players{$name}[1] + $players{$name}[2];
                print (($games == 0 ? 0 : $players{$name}[0] / $games) * 100);
                print "%";
                print q[</td></tr>];
        }
        print q[</table></center>];
}

sub printAllStats {
        print q[<h1><center>The Move Histories of All Players</center></h1>];
        print q[<br><br><hr><hr>];
          open READFILE, '<', "passwd" or logit("Unable to open passwd file");
  my $name;
  my @players;
  while (my $line = <READFILE> ) {
    ($name) = split(/\s+/, $line);
    push @players, $name;
  }
  close( READFILE );
  for my $i ( 0 .. $#players-1 ) {
    for my $j ( $i+1 .. $#players ) {
                        printGameHistory($players[$i], $players[$j]);
                        print q[<br><br><hr><hr>];
                }
        }

}
my $cgi = CGI->new;

print "Content-type: text/html\n\n";

my $session = new CGI::Session(undef, $cgi, {Directory=>'/Library/WebServer/CGI-Executables'});

my $username = $session->param( 'username' );
my $opponent = (defined $session->param( 'opponent' ) ? $session->param( 'opponent' ) : $cgi->param( 'opponent' ));
my $pattern = $cgi->param( 'pattern' );

if (!validateNames($username, $opponent)) {
        #input did not pass validation whitelists
        logit("Invalid Names for game play " . $username . " vs. " . $opponent);
        printInvalidInput();
        exit(0);
}

logit("Valid Names for game play " . $username . " vs. " . $opponent);

if ( !defined $username ) {
        print q[<html> <center> <h1> You do not have a valid session!] . "\n";
        print q[<br><a href="home.pl">Login to Whac-A-Mole</a></h1> </center> </html>] . "\n";
        exit 0;
} else {
        print q[<html> Welcome ] . $username . "!  ";
        print "Thanks for playing" . (defined $opponent ? " " . $opponent . "." : "!");
        print " With pattern " . $pattern unless (!defined $pattern);
        print " Could not cancel game, " . $opponent . " has moved" unless (!defined $opponent || !defined $cgi->param('newopponent'));
        print q[<br><br>];
}

# if the user is looking for a new opponent we may have to
# remove his last move if it is a pattern for the opponent to match
# The timeout script will add 0,0,0,0,0 to the opponent's file if
# this user's last move was a whacking move, allowing him to win
# or tie if he didn't get any matches
if (defined $opponent && defined $cgi->param('newopponent')) {
        my $numOfLines=0;
        my $numOfOpponentMoves=0;
        my $addr;
        open GAMEFILE, "+<", $username . "_" . $opponent;
        open OPPONENT, "+<", $opponent . "_" . $username;
        if ( fileno(GAMEFILE) != -1) {
                if ( fileno(OPPONENT) != -1) {
                        #trick to prevent deadlocks
                        my $locked = 0;
                        while ($locked == 0) {
                                if (flock( GAMEFILE, 2 | 4)) {
                                        if (flock( OPPONENT, 2 | 4)) {
                                                $locked = 1;
                                        } else {
                                                flock(GAMEFILE, 8);
                                        }
                                #need sleep and max retries
                                }
                        }
                        while (<GAMEFILE>) {
                                $addr = tell(GAMEFILE) unless eof(GAMEFILE);
                                $numOfLines++;
                        }
                        #remove last line of file if it
                        if ($numOfLines % 2 != 0) {
                                while (<OPPONENT>) {
                                        $numOfOpponentMoves++;
                                }
                                if ($numOfLines == $numOfOpponentMoves + 1) {
                                        truncate(GAMEFILE, $addr);
                                        $opponent = undef;
                                }
                        }
                } else {
                        truncate(<GAMEFILE>, 0);
                        $opponent = undef;
                }
        }
}

$session->param( 'opponent', $opponent );


if ( !validatePattern($pattern) )  {
        print q[<html>Invalid Pattern.  Please enter 5 numbers seperated by only a comma</html>];
        $pattern = undef;
}

logit("Valid Pattern " . $pattern . " entered in the " . $username . " vs. " . $opponent . " game.");

if (!defined $opponent) {
        my $name = $username;
        #check to see if there is a game in progress

        print q[<html><center><h1> Choose an opponent to play Whac-A-Mole against </h1></center></html>];
        print q[<form action="play.pl" method="POST"><h1><center><select name="opponent">];
        open READFILE, '<', "passwd" or exit 0;
        while (my $line = <READFILE> ) {
                if ( $line =~ /^($username) (.*)$/ ) {
                        next; #do not let player play against himself
                }
                ($name) = split(/\s+/, $line);
                print q[  <option value="] . $name . q[">] . $name . q[</option>] . "\n";
        }
        close READFILE;
        print q[</select><br><br><input type="submit" value="Play!"></center></h1></form></html>];
        print q[<br><br><hr><hr>];
        printGameStats();
        print q[<br><br><hr><hr>];
        printAllStats();

} else { # $opponent is defined

        # This is a player's move where their raw data file is updated for their turn

        # The number of moves in each file is verified to ensure the user is allowed
        # to take a turn and add another pattern to thier raw data file associated with their opponnent

        my $gamefile = $username . "_" . $opponent;
        my $opponentfile = $opponent . "_" . $username;

        my $numberOfMoves=0;
        my $opponentMoves=0;
        my $last_move = undef;
        my $last_pattern = undef;

        # count the lines in each file to verify that this is a valid move
        logit("Opening " . $gamefile);
        open GAMEFILE, '+>>', $gamefile or logit("Could not open " . $gamefile);
        logit("Opened " . $gamefile);
        seek GAMEFILE, 0, 0;
        logit("Opening " . $opponentfile);
        open OPPONENT, '+>>', $opponentfile or die "Could not open " . $opponentfile;
        seek OPPONENT, 0, 0;
        my $locked = 0;
        while ($locked == 0) {
                if (flock( GAMEFILE, 2 | 4)) {
                        if (flock( OPPONENT, 2 | 4)) {
                                $locked = 1;
                        } else {
                                flock(GAMEFILE, 8);
                        }
                #need sleep and max retries
                }
        }
        while ( <GAMEFILE> ) {
                chomp;
                $numberOfMoves++;
                $last_move = $_;
                #print $last_move . "==" . $pattern;
                if (defined $pattern && $last_move eq $pattern) {
                        print q[<html><center><h1>The pattern ] . $pattern;
                        print q[ was already used on your move number ] . $numberOfMoves . q[ </h1></center></html> ];
                        $pattern=undef;
                }
        };
        while ( <OPPONENT> ) {
                $opponentMoves++;
                $last_pattern = $_ unless ($opponentMoves % 2 == 0); #make sure you don't pick up opponent whacks
        };
        close( OPPONENT );

        if ( $numberOfMoves != $opponentMoves && $numberOfMoves != $opponentMoves-1 )  {
                close(GAMEFILE);
                print q[<html> <center> <h1> Waiting for your opponent to make their next move. </h1> </center>];
                print q[<form action="play.pl" method="POST"><h1><center>];
                print q[<input type="submit" value="Check If Opponent Has Made His Move"></center></h1></form></html>];
                print qq[<html><center><h1><form action="play.pl" method="POST"><input type="hidden" name="newopponent" value="yes"><input type="submit" value="Give up on this player and play someone else"></form></center></h1></html>];
        }
        elsif (!defined $pattern) {
                close(GAMEFILE);
                if ( $numberOfMoves % 2 == 0 ) {
                        print q[<html> <center> <h1> Enter the holes you want the moles to appear for your opponent ] . $opponent;
                        print q[<br><br>Enter five numbers from 1-5 separated by a comma.<br><br></h1> ];
                        print q[<form action="play.pl" method="POST"><h1><center><input name="pattern" type="text"><br><br><input type="submit"></center></h1></form></html>];
                } else {
                        print q[<html> <center> <h1> Enter the pattern you want to hit the mole holes! </h1> </center>];
                        print q[<form action="play.pl" method="POST"><h1><center>];
                        print q[<input name="pattern" type="text"><br><br>];
                        print q[<input type="submit" value="Whack those Moles!"></center></h1></form></html>];
                }
        } else {
                if ( $numberOfMoves % 2 == 0 ) {
                        print GAMEFILE $pattern . "\n";
                        print q[<html> <center> <h1> You have entered a valid pattern! <br> Waiting for your opponent to pick their pattern. </h1> </center>];
                        print q[<form action="play.pl" method="POST"><h1><center>];
                        print q[<input type="submit" value="Check If Opponent Has Choosen a Pattern"></center></h1></form></html>];
                } else {
                        #this pattern was the whack attempt of this user
                        $last_move = $pattern;
                        print q[<html> <center> <h1> You hit ] . getHits($last_move, $last_pattern) . q[ moles <br><br>];
                        print q[<html> The moles came up like ] . $last_pattern . q[ and you whacked the holes like ] . $last_move;
                        print q[<form action="play.pl" method="POST"><h1><center><input type="submit" value="Check if opponent has made his move"></center></h1></form></html>];
                        print q[<html><center><h1><form action="play.pl" method="POST"><input type="hidden" name="newopponent" value="yes"><input type="submit" value="Give up on this player and play someone else"></form></center></h1></html>];
                        print GAMEFILE $pattern . "\n";
                }
                close( GAMEFILE );
        }
        print q[<br><br><hr><hr></h1>];
        printGameHistory($username, $opponent);
}


