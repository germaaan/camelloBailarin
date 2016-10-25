package OSL::CamelloBailarin;
use Dancer2;
use DBI;
use File::Spec;
use File::Slurper qw/ read_text /;
use Template;

set 'database'     => File::Spec->catfile(File::Spec->tmpdir(), 'dancr.db');
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
    template 'show_entries.tt', {
        'msg' => get_flash(),
        'add_entry_url' => uri_for('/add'),
        'entries' => $sth->fetchall_hashref('id'),
    };
};

# get '/' => sub {
#     template 'index';
# };

post '/add' => sub {
    if ( not session('logged_in') ) {
        send_error("Not logged in", 401);
    }

    my $db = connect_db();
    my $sql = 'insert into entries (title, text) values (?, ?)';
    my $sth = $db->prepare($sql) or die $db->errstr;
    $sth->execute(params->{'title'}, params->{'text'}) or die $sth->errstr;

    set_flash('New entry posted!');
    redirect '/';
};

true;
