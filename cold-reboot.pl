#!/usr/bin/perl -w

# Drag in path stuff so we can find emulab stuff.
BEGIN { require "/etc/emulab/paths.pm"; import emulabpaths; }

my $HOME        = $ENV{"HOME"};

#
# HOME will not be defined until new images are built.
#
if (!defined($HOME)) {
    $HOME = "/users/geniuser";
    $ENV{"HOME"} = $HOME;
    $ENV{"USER"} = "geniuser";
}
my $OS_RELEASE = `lsb_release -r | awk '{print \$2}'`;
chomp($OS_RELEASE);
my $REBOOT;
my $GENIGET     = "/usr/bin/geni-get";
if ($OS_RELEASE eq '22.04') {
    $REBOOT = "/usr/bin/node_reboot";
} elsif ($OS_RELEASE eq '20.04') {
    $REBOOT = "/usr/local/bin/node_reboot";
} else {
    die("Unsupported OS version: $OS_RELEASE");
}

my $nodeID = `cat $BOOTDIR/nodeid`;
if ($?) {
    fatal("Could not get nodeID");
}
chomp($nodeID);

if (! -e "$HOME/.ssl/emulab.pem") {
    if (! -e "$HOME/.ssl") {
	if (!mkdir("$HOME/.ssl", 0750)) {
	    die("Could not mkdir $HOME/.ssl: $!");
	}
    }
    system("$GENIGET rpccert > $HOME/.ssl/emulab.pem");
    if ($?) {
	die("Could not geni-get xmlrpc cert/key");
    }
}
#system("$REBOOT -s $nodeID");
system("$REBOOT --server=boss -s $nodeID");
sleep(15);
# Still here? Bad.
die("Power cycle failed!");
