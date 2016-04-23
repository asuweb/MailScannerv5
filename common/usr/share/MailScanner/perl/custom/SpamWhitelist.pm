#
#   MailScanner - SMTP Email Processor
#   Copyright (C) 2006  Julian Field
#
#   $Id: SpamWhitelist.pm,v 1.1.2.1 2004/03/23 09:23:43 jkf Exp $
#
# 1.0	Initial implementation. Matches exact user@domain.com,
#	*@domain.com and domain.com.
# 1.1	Extra support for 10.2.3.4 complete IP addresses,
#	including IPv6 support.
#
#
# In your /etc/MailScanner/MailScanner.conf, set this line
# 
# Is Definitely Not Spam = &SpamWhiteList('/tmp/whitelist')
# 
# where /tmp/whitelist is wherever you have put your list of address for the spam whitelist.
# In there, you can have
# 
# blank lines
# # comments
# address@domain.com # comment
# *@domain.com
# domain.com # Has the same effect as the line above
# 10.2.3.4 # Complete exact IP address
# 
# You need to copy the
# cp SpamWhiteList.pm /usr/share/MailScanner/MailScanner/CustomFunctions/
# 
# and then restart MailScanner completely.
# 
# Any queries, drop me a line at jules@jules.fm.
# 


use FileHandle;

package MailScanner::CustomConfig;

use strict 'vars';
use strict 'refs';
no  strict 'subs'; # Allow bare words for parameter %'s

use vars qw($VERSION %addresses %domains);

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 1.1.2.1 $, 10;

%addresses = ();
%domains   = ();

sub InitSpamWhiteList {
  my($filename) = @_;
  # No initialisation needs doing here at all.
  MailScanner::Log::InfoLog("Initialising SpamWhitelist");

  #print STDERR "Reading Spam Whitelist from $filename\n";

  my $fh = new FileHandle;
  my($lines, $line, $addresses);
  $lines = 0;
  $addresses = 0;
  $fh->open("< $filename") or MailScanner::Log::DieLog("Could not open spam whitelist file $filename");

  while(defined($line=<$fh>)) {
    $lines++;
    $line =~ s/#.*$//g;    # Allow # comments
    $line =~ s/\s+$//g;    # Remove trailing white space
    $line =~ s/^\s+//g;    # Remote leading white space
    next if $line =~ /^$/; # Skip lines that are now blank

    $line =~ s/^\*@//; # Remove *@ from front of domain lines
    $line = lc($line);

    # Lines are now either
    #    user@domain.com
    # or domain.com
    $addresses++;
    if ($line =~ /@/) {
      $addresses{$line} = 1;
      #print STDERR "Read address $line\n";
    } else {
     $domains{$line} = 1;
     #print STDERR "Read domain $line\n";
    }
  }

  MailScanner::Log::InfoLog("Read %d spam whitelist addresses from %d lines in %s", $addresses, $lines, $filename);

  $fh->close;
}

#
sub EndSpamWhiteList {
  # No shutdown code needed here at all.
  # This function could log total stats, close databases, etc.
  MailScanner::Log::InfoLog("Ending SpamWhiteList");
}

## This will return 1 for all messages except those generated by this
## computer.
sub SpamWhiteList {
  my($message) = @_;
  return 0 unless $message; # Default if no message passed in
  return 1 if $domains{$message->{fromdomain}};
  return 1 if $domains{$message->{clientip}};
  #print STDERR "No domain match\n";
  return 1 if $addresses{$message->{from}};
  #print STDERR "No address match\n";
  return 0;
}

1;

