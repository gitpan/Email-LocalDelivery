package Email::LocalDelivery::Mbox;
use File::Path;
use File::Basename;
use Email::Simple;
use Fcntl ':flock';

our $VERSION = "1.03";

sub deliver {
    my ($class, $mail, @files) = @_;
    my @rv;
    for my $file (@files) {
        my $dir = dirname($file);
        next if ! -d $dir and not mkpath($dir);

        open my $fh, ">> $file"               || next;
        $class->getlock($fh)                  || next;
        seek $fh, 0, 2;
        print $fh $class->_from_line(\$mail); # Avoid passing $mail where poss.
        print $fh $mail;
        print $fh "\n";
        $class->unlock($fh)                   || next;
        close $fh                             || next;
        push @rv, $file
    }
    return @rv;
}

sub _from_line {
    my ($class, $mail_r) = @_;

    # The trivial way
    return if $$mail_r =~ /^From\s/;

    # The qmail way.
    return $ENV{UFLINE}.$ENV{RPLINE}.$ENV{DTLINE} if exists $ENV{UFLINE};
    
    # The boring way.
    return _from_line_boring(Email::Simple->new($$mail_r));
}

sub _from_line_boring {
    my $mail = shift;
    my $from = $mail->header("Return-path") ||
               $mail->header("Sender")      ||
               $mail->header("Reply-To")    ||
               $mail->header("From")        ||
               'root@localhost';
    $from = $1 if $from =~ /<(.*?)>/; # comment <email@address> -> email@address
    $from =~ s/\s*\(.*\)\s*//;        # email@address (comment) -> email@address
    $from =~ s/\s+//g; # if any whitespace remains, get rid of it.

    my $fromtime = localtime;
    $fromtime =~ s/(:\d\d) \S+ (\d{4})$/$1 $2/; # strip timezone.
    return "From $from  $fromtime\n";
}

sub getlock {
    my ($class, $fh) = @_;
    for (1..10) {
        return 1 if flock ($fh, LOCK_EX | LOCK_NB);
        sleep $_;
    }
    return 0 ;
}

sub unlock {
    my ($class,$fh) = @_;
    flock ($fh, LOCK_UN);
}

1;
