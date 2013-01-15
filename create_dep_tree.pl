#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Cwd qw(getcwd);
use YAML;
use Storable;

my $version = $ARGV[0];

if(! $version) {
   print "Usage: $0 <version>\n";
   exit 1;
}

my $cwd = getcwd;

if(-d "/tmp/gen_deps") {
   system "rm -rf /tmp/gen_deps";
}

mkdir "/tmp/gen_deps";
chdir "/tmp/gen_deps";

system "git clone git://github.com/krimdomu/rex-recipes.git";
chdir "rex-recipes";
system "git checkout $version";

my @dir = (".");

my $dep_tree = {};


print "[+] Indexing files...\n";
for my $d (@dir) {
   opendir(my $dh, $d) or die($!);
   while(my $entry = readdir($dh)) {
      next if( $entry =~ m/^\./ );
      if(-d "$d/$entry") {
         push(@dir, "$d/$entry");
      }

      if($entry =~ m/meta\.yml/) {
         my $yaml = eval { local(@ARGV, $/) = ("$d/$entry"); <>; };
         my $ref = Load($yaml . "\n");

         print "   [-] " . $ref->{Name};
         
         $dep_tree->{$ref->{Name}} = $ref;

         print "\r   [+] " . $ref->{Name} . "                   \n";
      }
   }
   closedir($dh);
}

print "\n";

chdir $cwd;

system "rm -rf /tmp/gen_deps";

store $dep_tree, "modules.$version.db";


