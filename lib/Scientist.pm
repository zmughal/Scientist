package Scientist;

use strict;
use warnings;
# VERSION

use Moo;
use Test::Deep::NoTest qw/deep_diag cmp_details/;
use Time::HiRes 'time';
use Types::Standard qw/Bool Str CodeRef HashRef/;

use namespace::clean;

# ABSTRACT: Perl module inspired by https://github.com/github/scientist
# https://github.com/lancew/Scientist

has 'context' => (
    is       => 'rw',
    isa      => HashRef,
);

has 'enabled' => (
    is       => 'rw',
    isa      => Bool,
    default  => 1,
);

has 'experiment' => (
    is       => 'ro',
    isa      => Str,
    builder  => 'name',
);

has 'use' => (
    is       => 'rw',
    isa      => CodeRef,
);

has 'result' => (
    is       => 'rw',
    isa      => HashRef,
);

has 'try' => (
    is       => 'rw',
    isa      => CodeRef,
);

sub name {
    return 'experiment';
}

sub publish {
    my $self = shift;
    # Stub publish sub, extend this to enable your own own
    # unique publishing requirements
    return;
}

sub run {
    my $self = shift;

    # If experiment not enabled just return the control code results.
    return $self->use->() unless $self->enabled;

    my %result = (
        context    => $self->context,
        experiment => $self->experiment,
    );

    my $wantarray = wantarray;

    my ( @control, @candidate );
    my $run_control = sub {
        my $start = time;
        @control = $wantarray ? $self->use->() : scalar $self->use->();
        $result{control}{duration} = time - $start;
    };

    my $run_candidate = sub {
        my $start = time;
        @candidate = $wantarray
            ? eval { $self->try->() }
            : eval { scalar $self->try->() };
        $result{candidate}{duration} = time - $start;
    };

    if ( rand > 0.5 ) {
        $run_control->();
        $run_candidate->();
    }
    else {
        $run_candidate->();
        $run_control->();
    }

    my ($ok, $stack)    = cmp_details( \@candidate, \@control );
    $result{matched}    = $ok ? 1 : 0;
    $result{mismatched} = $ok ? 0 : 1;

    $result{observation}{candidate} = $wantarray ? @candidate : $candidate[0];
    $result{observation}{control}   = $wantarray ? @control : $control[0];

    if ($result{mismatched}){
        $result{observation}{diagnostic} = deep_diag($stack);
    }

    $self->result( \%result );
    $self->publish;

    return $wantarray ? @control : $control[0];
}

1;

=head1 LICENSE

This software is Copyright (c) 2016 by Lance Wicks.

This is free software, licensed under:

  The MIT (X11) License

The MIT License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall
be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
