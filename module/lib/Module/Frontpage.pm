package Module::Frontpage;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::UserAgent;
use Mojo::JSON;
use Data::Dumper;

# This action will render a template
sub index {
   my $self = shift;

   $self->render;
}

sub search {
   my $self = shift;

   my $term = $self->param("q");

   my $ua = Mojo::UserAgent->new;
   my $tx = $ua->post("http://localhost:9200/modules/_search?pretty=true", json => {
      query => {
         query_string => {
            default_field => "file",
            query => $term,
         },
      },
      fields => [qw/fs title author desc module/],
      highlight => {
         fields => {
            file => {},
         },
      },
   });

   if(my $json = $tx->res->json) {
      return $self->render("search", hits => $json->{hits});
   }
   else {
      return $self->render("search", hits => { total => 0, });
   }

   $self->render;
}

sub help {
   my ($self) = @_;
   $self->render;
}

sub contribute {
   my ($self) = @_;
   $self->render;
}
1;
