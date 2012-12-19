package Module;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
   my $self = shift;

   my @cfg = ("/etc/rex/modules-server.conf", "/usr/local/etc/rex/io/module-server.conf", "module-server.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }
   $self->plugin('Config', file => $cfg);
   $self->plugin('RenderFile');


   # Router
   my $r = $self->routes;

   # Normal route to controller
   $r->get('/')->to('frontpage#index');

   $r->get('/search')->to("frontpage#search");
   $r->get('/help')->to("frontpage#help");
   $r->get('/contribute')->to("frontpage#contribute");

   $r->get('/module/*module')->to("module#index");
   $r->get('/pod/*module/file/*file')->to("module#show_pod");

   $r->get('/api/#version/get/recipes')->to("api#get_recipes");
   $r->get('/api/#version/get/mod/*module')->to("api#get_module");
   $r->get('/api/#version/get/dep/*module')->to("api#get_dep_module");
}

1;
