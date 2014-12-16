#!/usr/bin/perl -w -T

# This is the home page of the Whac-A-Mole game

# It contains a form that accepts a user name and password
# It will submit the username and password to login.pl

print "Content-type: text/html\n\n";

print q[<html><body><h1>Login to Whac-A-Mole</h1>];

print q[<form action="/cgi-bin/login.pl" method="POST">];

print q[ Username: <input type="text" name="username">];
print q[ Password: <input type="password" name="password">];

print q[<input type="submit" value="Submit"></form></body></html>];
