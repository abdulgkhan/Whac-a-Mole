#!/usr/bin/perl -w -T
use strict;

# This script will periodically check to make sure all that
# the data files for game moves are not so old that the user
# should be timed out.

# If the opponent's has put his whack pattern in
# and the gamefile is older than 36 hours (1.5 days) the values
# 0,0,0,0,0 will be put in the gamefile
print "Content-type: text/html\n\n<html>";

while (1) {
        open READFILE, '<', "passwd" or logit("Unable to open passwd file");
        my $name;
        my $untainted_name;
        my @players;
        while (my $line = <READFILE> ) {
                ($name) = split(/\s+/, $line);
                ($untainted_name) = ($name =~ /^([a-zA-Z0-9_.]{1,20})$/);
                push @players, $untainted_name;
        }
        close( READFILE );
        for my $i ( 0 .. $#players ) {
                for my $j ( 0 .. $#players ) {
                        if ($i != $j) {
                                my $gamefile = $players[$i] . "_" . $players[$j];
                                my $opponent = $players[$j] . "_" . $players[$i];
                                my $gamefilesize = (-s $gamefile);
                                my $opponentsize = (-s $opponent);

                                #print $gamefile . " " . $opponent . " " . $gamefilesize . " "
                                #       . $opponentsize . " " . (-M $gamefile) . "\n"
                                #       if (defined $gamefilesize && defined $opponentsize);
                                if (defined $gamefilesize && defined $opponentsize
                                                && $gamefilesize < $opponentsize
                                                && $gamefilesize % 20
                                                && -M $gamefile > 1.5) {
                                        print "Timing out user " . $players[$i] . " in his game against player " . $players[$j] . "</html>\n";
                                        open GAMEFILE, '>>', $gamefile or die "<html>can't open " . $gamefile . "</html>";
                                        flock GAMEFILE, 2;
                                        print GAMEFILE "0,0,0,0,0" . "\n";
                                        close GAMEFILE;
                                        print "Done";
                                }
                        }
                }
        }
        sleep 60;
}
