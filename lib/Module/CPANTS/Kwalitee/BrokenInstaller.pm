package Module::CPANTS::Kwalitee::BrokenInstaller;
use warnings;
use strict;
use File::Find;
use File::Spec::Functions qw(catdir catfile abs2rel);
use File::stat;

our $VERSION = '0.93_02';
$VERSION = eval $VERSION; ## no critic

sub order { 100 }

sub analyse {
    my $class = shift;
    my $me = shift;
    my $distdir = $me->distdir;
    
    # inc/Module/Install.pm file
    my $mi = catfile($distdir, 'inc', 'Module', 'Install.pm');
    
    # Must be okay if not using Module::Install
    return if not -f $mi;

    open my $ih, '<', $mi
      or die "Could not open file '$mi' for checking the bad_installer metric: $!";
    my $buf;
    read $ih, $buf, 100000 or die $!;
    close $ih;
    if ($buf =~ /VERSION\s*=\s*("|'|)(\d+|\d*\.\d+(?:_\d+)?)\1/m) {
        $me->d->{module_install}{version} = my $version = $2;
        my $non_devel = $version;
        $non_devel =~ s/_\d+$//;
        if ($non_devel < 0.61 or $non_devel == 1.04) {
            $me->d->{module_install}{broken} = 1;
        }
        if ($non_devel < 0.89) {
            my $makefilepl = catfile($distdir, 'Makefile.PL');
            return if not -f $makefilepl;
            
            open my $ih, '<', $makefilepl
              or die "Could not open file '$makefilepl' for checking the bad_installer metric: $!";
            local $/ = undef;
            my $mftext = <$ih>;
            close $ih;
            
            return if not defined $mftext;

            if ($mftext =~ /auto_install/) {
                $me->d->{module_install}{broken_auto_install} = 1;
            } else {
                return;
            }
            
            if ($non_devel < 0.64) {
                $me->d->{module_install}{broken} = 1;
            }
        }
    }
    else {
        # Unknown version (parsing $VERSION failed)
        $me->d->{module_install}{broken} = 1;
    }

    
    return;
}


sub kwalitee_indicators {
  return [
    {
        name=>'no_broken_module_install',
        error=>q{This distribution uses an obsolete version of Module::Install. Versions of Module::Install prior to 0.61 might not work on some systems at all. Additionally if your Makefile.PL uses the 'auto_install()' feature, you need at least version 0.64. Also, 1.04 is known to be broken.},
        remedy=>q{Upgrade the bundled version of Module::Install to the most current release. Alternatively, you can switch to another build system / installer that does not suffer from this problem. (ExtUtils::MakeMaker, Module::Build both of which have their own set of problems.)},
        code=>sub {
            my $d = shift;
            return 1 unless exists $d->{module_install};
            $d->{module_install}{broken} ? 0 : 1;
        },
        details=> sub {
            q{This distribution uses obsolete Module::Install version }.(shift->{module_install}{version});
        },
    },
    {
        name=>'no_broken_auto_install',
        error=>q{This distribution uses an old version of Module::Install. Versions of Module::Install prior to 0.89 do not detect correcty that CPAN/CPANPLUS shell is used.},
        remedy=>q{Upgrade the bundled version of Module::Install to at least 0.89, but preferably to the most current release. Alternatively, you can switch to another build system / installer that does not suffer from this problem. (ExtUtils::MakeMaker, Module::Build both of which have their own set of problems.)},
        code=>sub {
            my $d = shift;
            return 1 unless exists $d->{module_install};
            $d->{module_install}{broken_auto_install} ? 0 : 1;
        },
        details=> sub {
            q{This distribution uses obsolete Module::Install version }.(shift->{module_install}{version});
        },
    },
];
}


1

__END__

=encoding UTF-8

=head1 NAME

Module::CPANTS::Kwalitee::BrokenInstaller - Check for broken Module::Install

=head1 SYNOPSIS

Find out whether the distribution uses an outdated version of Module::Install.

=head1 DESCRIPTION

=head2 Methods

=head3 order

Defines the order in which Kwalitee tests should be run.

Returns C<100>, as data generated by this should not be
used by any other tests.

=head3 analyse

C<MCK::BrokenInstaller> checks whether the distribution uses Module::Install
and if so whether it uses a reasonably current version of it (0.61 or later).

It also checks whether the F<Makefile.PL> uses the C<auto_install> feature.
If so, C<Module::Install> should be at least version 0.64.

=head3 kwalitee_indicators

Returns the Kwalitee Indicators datastructure.

=over

=item * no_broken_module_install

=item * no_broken_auto_install

=back

=head1 SEE ALSO

L<Module::CPANTS::Analyse>

=head1 AUTHOR

L<Steffen Müller|https://metacpan.org/author/smueller>

L<Thomas Klausner|https://metacpan.org/author/domm>

=head1 COPYRIGHT AND LICENSE

Copyright © 2003–2009 L<Thomas Klausner|https://metacpan.org/author/domm>

Copyright © 2006 L<Steffen Müller|https://metacpan.org/author/smueller>

You may use and distribute this module according to the same terms
that Perl is distributed under.
