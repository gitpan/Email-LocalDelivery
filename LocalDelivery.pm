package Email::LocalDelivery;

require 5.005_62;
use strict;
use warnings;
use Email::FolderType qw(folder_type);
use Carp;
our $VERSION = '0.02';

=head1 NAME

Email::LocalDelivery - Deliver a piece of email - simply

=head1 SYNOPSIS

  use Email::LocalDelivery;
  my $delivery_agent = Email::LocalDelivery->deliver($mail, @boxes);

=head1 DESCRIPTION

This is the second module produced by the "Perl Email Project", a
reaction against the complexity and increasing bugginess of the
C<Mail::*> modules. It delivers an email to a list of mailboxes.

=head1 METHODS

=head2 deliver

This takes an email, as a plain string, and a list of mailboxes to
deliver that mail to. It returns the list of boxes actually written to.
If no boxes are given, it assumes the standard Unix mailbox. (Either
C<$ENV{MAIL}>, F</var/spool/mail/you>, F</var/mail/you>, or
F<~you/Maildir/>)

=cut

sub deliver {
    my ($class, $mail, @boxes) = @_;
    croak "Mail argument to deliver should just be a plain string"
        if ref $mail;
    if (!@boxes) {
        my $default_unixbox = ( grep { -d $_ } qw(/var/spool/mail/ /var/mail/) )[0] . getpwuid($>);
        my $default_maildir = ((getpwuid($>))[7])."/Maildir/";

        @boxes = $ENV{MAIL}
            || (-e $default_unixbox && $default_unixbox)
            || (-d $default_maildir."cur" && $default_maildir);

    }
    my %to_deliver;
    push @{$to_deliver{folder_type($_)}}, $_ for @boxes;
    my @rv;
    for my $method (keys %to_deliver) {
        eval "require Email::LocalDelivery::$method";
        croak "Couldn't load a module to handle $method mailboxes" if $@;
        push @rv,
        "Email::LocalDelivery::$method"->deliver($mail,
                                                @{$to_deliver{$method}});
    }
    return @rv;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
