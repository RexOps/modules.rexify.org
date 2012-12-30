package Module::Api;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::UserAgent;
use Mojo::JSON;
use Data::Dumper;
use Cwd qw(getcwd);
use YAML;
use Storable;

# This action will render a template
sub index {
   my $self = shift;

   $self->render;
}

sub get_recipes {
   my ($self) = @_;
   my $ua = Mojo::UserAgent->new;

   my $version = $self->param("version");

   if($version !~ m/^\d+\.\d+$/) {
      return $self->render_json({ok => 0}, status => 404);
   }

   my $ref = retrieve "modules.$version.db";
   $self->render_text(Dump($ref));
};


sub get_module {
   my ($self) = @_;

   my $cur_dir = getcwd;

   my $mod = $self->param("module");
   my $version = $self->param("version");

   my $mod_name = $mod . ".pm";

   if( ! -d "/tmp/scratch") {
      mkdir "/tmp/scratch";
   }

   chdir("/tmp/scratch");

   my $u = get_random(32, 'a' .. 'z');  
   system("git clone git://github.com/krimdomu/rex-recipes.git $u >/dev/null 2>&1");
   chdir("$u");
   system("git checkout $version");

   system("tar czf ../$u.tar.gz $mod $mod_name >/dev/null 2>&1");

   chdir($cur_dir);

   $self->render_file(filepath => "/tmp/scratch/$u.tar.gz");

}

sub get_dep_module {
   my ($self) = @_;

   my $module = $self->param("module");
   my $version = $self->param("version");

   if(-f "modules.$version.db") {
      my $all_ref = retrieve "modules.$version.db";
      my $ref = $all_ref->{$module};

      if(! exists $ref->{Require}) {
         return $self->render_json([]);
      }

      return $self->render_json($ref->{Require});
   }

   $self->render_json({ok => 0}, status => 404);   
}

sub get_dep_perl {
   my ($self) = @_;

   my $module = $self->param("module");
   my $version = $self->param("version");

   if(-f "modules.$version.db") {
      my $all_ref = retrieve "modules.$version.db";
      my $ref = $all_ref->{$module};

      if(! exists $ref->{PerlRequire}) {
         return $self->render_json([]);
      }

      return $self->render_json($ref->{PerlRequire});
   }

   $self->render_json({ok => 0}, status => 404);   
}

################################################################################
# FUNCTIONS
################################################################################

sub get_random {
	my $count = shift;
	my @chars = @_;
	
	srand();
	my $ret = "";
	for(1..$count) {
		$ret .= $chars[int(rand(scalar(@chars)-1))];
	}
	
	return $ret;
}



1;
