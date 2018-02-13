package App::MIDI::Ngram;
use Dancer ':syntax';

use Carp;
use File::Basename;
use MIDI::Ngram;

our $VERSION = '0.1';

get '/' => sub {
    template 'index' => {
        title => 'App::MIDI::Ngram',
    };
};

post '/generate' => sub {
    my $midi_file = upload('midi_file');

    my $filename = '';
    if ( $midi_file ) {
        $midi_file->copy_to('MIDI/');
        $filename = 'MIDI/' . basename( $midi_file->tempname );
    }

    my $ngram_size      = params->{ngram_size};
    my $max_phrases     = params->{max_phrases};
    my $bpm             = params->{bpm};
    my $durations       = params->{durations} || ['qn'];
    my $pause           = params->{pause};
    my $weight          = params->{weight};
    my $loop            = params->{loop} || 4;
    my $random_patch    = params->{random_patch};
    my $shuffle_phrases = params->{shuffle_phrases};
    my $single_phrases  = params->{single_phrases};

    # General MIDI patches that are audible and aren't horrible
    my @patches = qw(
        0 1 2 4 5 7 8 9
        13 16 21 24 25 26
        32 34 35 40 42 60
        68 69 70 71 72 73
        74 79
    );

    my $analysis; # Text string of the ngram analysis
    my $playback; # Text string of the phrase playback

    if ( $midi_file ) {
        my $mng = MIDI::Ngram->new(
            file            => $filename,
            size            => $ngram_size,
            max             => $max_phrases,
            bpm             => $bpm,
            durations       => ref $durations eq 'ARRAY' ? $durations : [ $durations ],
            out_file        => 'public/midi-ngram.mid',
            pause           => $pause,
            randpatch       => $random_patch ? 1 : 0,
            loop            => $loop,
            weight          => $weight ? 1 : 0,
            shuffle_phrases => $shuffle_phrases ? 1 : 0,
            single          => $single_phrases ? 1 : 0,
            patches         => \@patches,
        );

        $analysis = $mng->process;
        $playback = $mng->populate;
        $mng->write;

        unlink $filename
            or croak "Can't unlink $filename: $!";
    }

    template 'index' => {
        title           => 'App::MIDI::Ngram',
        ngram_size      => $ngram_size,
        max_phrases     => $max_phrases,
        bpm             => $bpm,
        durations       => $durations,
        out_file        => 'midi-ngram.mid',
        pause           => $pause,
        weight          => $weight,
        loop            => $loop,
        random_patch    => $random_patch,
        shuffle_phrases => $shuffle_phrases,
        single_phrases  => $single_phrases,
        analysis        => $analysis,
        playback        => $playback,
    };
};

true;
