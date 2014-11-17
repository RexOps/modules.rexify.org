#!/usr/bin/env perl -w

use strict;
use warnings;

use MIME::Base64;
use Mojo::UserAgent;
use Mojo::JSON;
use Data::Dumper;
use YAML;

my $index_server = ($ARGV[0] || "localhost");
my $index_port   = ($ARGV[1] || "9200");
my $index_dir    = ($ARGV[2] || "/tmp/$$/rex-recipes");

$|++;

system "rm -rf /tmp/$$";
system "mkdir -p /tmp/$$";
system "cd /tmp/$$ ; git clone https://github.com/RexOps/rex-recipes.git";


if(! $index_server) {
   print "You have to set the server where to store the index.\n";
   exit 1;
}

if(! $index_port) {
   print "You have to set the server's port where to store the index.\n";
   exit 2;
}

if(! $index_dir) {
   print "You have to set the directory you want to index.\n";
   exit 3;
}

for my $idx (qw/modules/) {
   # first delete index
   print "[+] Deleting index ($idx)\n";
   _delete("/$idx/");

   # create new index
   print "[-] creating index ($idx)";
   my $tx = _put("/$idx", {
      "settings" => {
            "number_of_shards" => 1,
            "number_of_replicas" => 0
      },
   });
   if($tx->success) {
      print "\r[+] creating index ($idx)                    \n";
   }
   else {
      print "\r[!] error creating index ($idx)                   \n";
      exit 1;
   }

   # create attachment options
   print "[+] creating attachment mapping for ($idx)\n";
   _put("/$idx/attachment/_mapping", {
      "attachment" => {
         "properties" => {
            "file" => {
               "type" => "attachment",
               "fields" => {
                  "title" => { "store" => "yes" },
                  "desc"  => { "store" => "yes" },
                  "module"  => { "store" => "yes" },
                  "tags"  => { "store" => "yes" },
                  "author"  => { "store" => "yes" },
                  "file"  => { "term_vector" => "with_positions_offsets", "store" => "yes" }
               }
            }
         }
      }
   });
}

my @dir = ($index_dir);

print "[+] Indexing files...\n";
for my $d (@dir) {
   opendir(my $dh, $d);
   while(my $entry = readdir($dh)) {
      next if($entry =~ m/^\./);

      if(-d "$d/$entry") {
         push(@dir, "$d/$entry");
         my $_d = "$d/$entry";
         index_module("$d/$entry");
         next;
      }

   }
   closedir($dh);
}

sub index_module {
   my ($dir) = @_;

   return if(! -f "$dir/meta.yml");

   my $yaml = eval { local(@ARGV, $/) = ("$dir/meta.yml"); <>; };
   $yaml .= "\n";
   my $ref = Load($yaml);

   my $module  = $ref->{Name};
   my $desc    = $ref->{Description};
   my $author  = $ref->{Author};
   my $license = $ref->{License};

   my @mod_dirs = ($dir);
   for my $m_dir (@mod_dirs) {
      opendir(my $dh2, $m_dir);
      while(my $entry = readdir($dh2)) {
         next if($entry =~ m/^\./);
         
         if(-d "$m_dir/$entry") {
            push(@mod_dirs, "$m_dir/$entry");
            next;
         }

         if($entry =~ m/\.pm$/) {
            index_modules_document({
               module  => $module,
               desc    => $desc,
               author  => $author,
               license => $license,
            }, "$m_dir/$entry");
         }
      }

      closedir($dh2);
   }
}

sub index_modules_document {
   my ($data, $doc) = @_;

   my $idx = "modules";

   print "   [-] $doc ($idx)   ";

   my $title = "";

   my @content = qx{pod2text $doc 2>/dev/null};
   chomp @content;

   my $base64_content = encode_base64(join("\n", @content));

   my $json = Mojo::JSON->new;
   my $fs = $doc;
   $fs =~ s/$index_dir\///;
   $fs =~ s/\/__module__\.pm$//;

   my $ref = {
      file  => $base64_content,
      desc => $data->{desc},
      fs    => $fs,
      title => $title,
      author => $data->{author},
      license => $data->{license},
      module => $data->{module},
      tags => [],
   };

   my $tx = _post("/$idx/attachment/", $ref);

   print "\r";
   print " "x80;

   if($tx->res->json && $tx->res->json->{ok}) {
      print "\r   [+] $doc ($idx)   \n";
   }
   else {
      print "\r   [!] $doc ($idx)   \n";
   }
}


sub _ua {
   my $ua = Mojo::UserAgent->new;
   return $ua;
}

sub _json {
   return Mojo::JSON->new;
}

sub _get {
   my ($self, $url) = @_;
   _ua->get("http://$index_server:$index_port$url");
}

sub _post {
   my ($url, $post) = @_;
   _ua->post("http://$index_server:$index_port$url", json => $post);
}

sub _put {
   my ($url, $put) = @_;
   _ua->put("http://$index_server:$index_port$url", _json->encode($put));
}

sub _delete {
   my ($url) = @_;
   my $tx = _ua->build_tx(DELETE => "http://$index_server:$index_port$url");
   _ua->start($tx);
}



