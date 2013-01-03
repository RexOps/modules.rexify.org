package Module::Module;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::UserAgent;
use Mojo::JSON;
use Data::Dumper;
use YAML;

sub index {
   my $self = shift;

   my $module = $self->param("module");
   my $module_path = $module;
   $module_path =~ s/::/\//g;

   my $module_base_path = $self->config->{"module_directory"};

   my $pod = _get_pod("$module_base_path/$module_path/__module__.pm");

   my @dirs = ("$module_base_path/$module_path");
   my @files = ();

   for my $d (@dirs) {
      opendir(my $dh, $d);
      while(my $entry = readdir($dh)) {
         next if ($entry =~ m/^\./);
         next if ($entry =~ m/__module__\.pm/);

         if(-d "$d/$entry") {
            push(@dirs, "$d/$entry");
            next;
         }

         my $push_f = "$d/$entry";
         $push_f =~ s/^$module_base_path\///;

         if(-f "$d/$entry") {
            if(open(my $fh, "<", "$d/$entry")) {
               while(my $line = <$fh>) {
                  if($line =~ m/^# !no_doc!/) {
                     next;
                  }
               }
               close($fh);
            }
         }
         push(@files, $push_f);
      }
      closedir($dh);
   }

   if(-f "$module_base_path/$module_path/meta.yml") {
      my $yaml = eval { local(@ARGV, $/) = ("$module_base_path/$module_path/meta.yml"); <>; };
      my $ref = Load($yaml);

      return $self->render("module/index", pod => $pod, module => $ref, files => \@files);
   }

   else {
      return $self->render("not_found", status => 404);
   }
   

}

sub show_pod {
   my ($self) = @_;

   my $file = $self->param("file");

   my $module = $self->param("module");
   my $module_path = $module;
   $module_path =~ s/::/\//g;

   my $module_base_path = $self->config->{"module_directory"};

   my $pod = _get_pod("$module_base_path/$module_path/$file");

   my @dirs = ("$module_base_path/$module_path");
   my @files = ();

   for my $d (@dirs) {
      opendir(my $dh, $d);
      while(my $entry = readdir($dh)) {
         next if ($entry =~ m/^\./);
         next if ($entry =~ m/__module__\.pm/);

         if(-d "$d/$entry") {
            push(@dirs, "$d/$entry");
            next;
         }

         my $push_f = "$d/$entry";
         $push_f =~ s/^$module_base_path\///;

         push(@files, $push_f);
      }
      closedir($dh);
   }

   if(-f "$module_base_path/$module_path/meta.yml") {
      my $yaml = eval { local(@ARGV, $/) = ("$module_base_path/$module_path/meta.yml"); <>; };
      my $ref = Load($yaml);

      return $self->render("module/index", pod => $pod, module => $ref, files => \@files);
   }

   else {
      return $self->render("not_found", status => 404);
   }
 

}

sub _get_pod {
   my ($file) = @_;

   if($file !~ m/\.pm$/) {
      return "";
   }

   my @pod = qx{pod2html $file 2>/dev/null};
   chomp @pod;

   for (@pod) {
      s/<ul>/<ul class="simple-list">/gms;
      s/<hr.*>/<div class="vspace"><\/div>/gms;
      s/<pre>/<div class="black-box"><pre class="perl">/gms;
      s/<dl>/<div class="vspace"><\/div><ul class="simple-list">/g;
      s/<\/dl>/<\/ul>/g;
      s/<dd>//g;
      s/<\/dd>//g;
      s/<dt>/<li>/g;
      s/<\/dt>/<\/li>/g;
      s/<\/pre>/<\/pre><\/div><div class="vspace"><\/div>/g;
      s/<p><a name="__index__"><\/a><\/p>/<h1>TABLE OF CONTENTS<\/h1>/g;
      s/<div class="vspace"><\/div><ul class="simple-list">/<ul class="simple-list">/gms;
   }

   my $pod = join("\n", @pod);
   $pod =~ s/.*<body[^>]+>(.*?)<\/body>.*/$1/gms;
   $pod =~ s/"perl">\n/"perl">/gms;
   $pod =~ s/<h1>TABLE OF CONTENTS.*?<\/ul>/_gen_toc($pod)/egms;
   #$pod =~ s/<p>\s*<\/p>//gms;
   $pod =~ s/<div class="vspace"><\/div>\s*<div class="vspace"><\/div>/<div class="vspace"><\/div>/gms;

   if(! $pod) {
      $pod = "No documentation found.";
   }

   return $pod;
}

sub _gen_toc {
   my ($pod) = @_;

   my @headers = ($pod =~ m/<h1>(.*?)<\/h1>/g);

   my $ret = '<ul class="simple-list">';

   for (@headers) {
      next if m/TABLE OF CON/;
      $_ =~ s/name="([^"]+)"/href="#$1"/;
      $ret .= "<li>$_</li>";
   }

   $ret .= '<li><a href="#files">ADDITIONAL FILES</a></li>';

   $ret .= "</ul>";


   return $ret;
}

1;
