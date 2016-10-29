package OSL::CamelloBailarin;
use Dancer2;
use DBI;
use File::Spec;
use File::Slurper qw/ read_text /;
use Template;

set 'database'     => 'dancr.db';
set 'session'      => 'Simple';
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;
set 'username'     => 'admin';
set 'password'     => 'password';
set 'layout'       => 'main';

our $VERSION = '0.1';

my $flash;

sub set_flash {
    my $message = shift;

    $flash = $message;
}

sub get_flash {
    my $msg = $flash;
    $flash = "";

    return $msg;
}

sub connect_db {
  my $dbh = DBI->connect("dbi:SQLite:dbname=".setting('database')) or
     die $DBI::errstr;

  return $dbh;
}

sub init_db {
  my $db = connect_db();
  my $schema = read_text('./schema.sql');
  $db->do($schema) or die $db->errstr;
}

hook before_template_render => sub {
    my $tokens = shift;

    $tokens->{'css_url'} = request->base . 'css/style.css';
    $tokens->{'login_url'} = uri_for('/login');
    $tokens->{'logout_url'} = uri_for('/logout');
};

get '/' => sub {
    my $db = connect_db();
    my $sql = 'select id, title, text from entries order by id desc';
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute or die $sth->errstr;
    template 'data.tt', {
        'msg' => get_flash(),
        'add_entry_url' => uri_for('/add'),
        'entries' => $sth->fetchall_hashref('id'),
    };
};

post '/add' => sub {
    if ( not session('logged_in') ) {
        send_error("Sin iniciar sesión.", 401);
    }

    my $db = connect_db();
    my $sql = 'insert into entries (title, text) values (?, ?)';
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute(params->{'title'}, params->{'text'}) or die $sth->errstr;

    set_flash('Nueva entrada añadida.');
    redirect '/';
};

any ['get', 'post'] => '/login' => sub {
    my $err;

    if ( request->method() eq "POST" ) {
        if ( params->{'username'} ne setting('username') ) {
            $err = "Usuario no válido.";
        }
        elsif ( params->{'password'} ne setting('password') ) {
            $err = "Password no válido.";
        }
        else {
            session 'logged_in' => true;
            set_flash('Sesión iniciada.');
            return redirect '/';
        }
   }

   template 'login.tt', {
       'err' => $err,
   };
};

get '/logout' => sub {
   app->destroy_session;
   set_flash('Sesión finalizada.');
   redirect '/';
};

init_db();
start;
