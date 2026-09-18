package ATL::PluginSDK::Package;
use strict;
use warnings;
use JSON::PP ();
use File::Spec;
use Cwd qw(abs_path);
our $VERSION = '0.2.0';

sub _text { defined $_[0] && !ref($_[0]) }
sub _filename { _text($_[0]) && $_[0] =~ /\A[A-Za-z0-9][A-Za-z0-9_.-]*\z/ }
sub _list {
    my ($v, $max, $len) = @_;
    return ref($v) eq 'ARRAY' && @$v <= $max
        && !grep { !_text($_) || length($_) > $len || /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/ } @$v;
}
sub validate {
    my ($class, $m) = @_;
    return ['Manifest must be an object'] unless ref($m) eq 'HASH';
    my @e;
    my %allowed = map { $_ => 1 } qw(id name type api_version version description logo entry supports permissions safe_by_default ui metadata stability release_note);
    push @e, "Unknown field: $_" for grep { !$allowed{$_} } keys %$m;
    for my $k (qw(id name type api_version version)) {
        push @e, "Missing or invalid field: $k" unless _text($m->{$k}) && length($m->{$k}) && length($m->{$k}) <= 200;
    }
    push @e, 'Invalid id' if _text($m->{id}) && $m->{id} !~ /\A[a-z0-9][a-z0-9_.-]*\z/;
    push @e, 'Unsupported type' if _text($m->{type}) && $m->{type} !~ /\A(?:device|tool|tui|code)\z/;
    push @e, 'Unsupported API version' if _text($m->{api_version}) && $m->{api_version} ne '1.0';
    push @e, 'Invalid version' if _text($m->{version}) && $m->{version} !~ /\A[0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9_.-]+)?\z/;
    for my $k (qw(description release_note)) {
        push @e, "Invalid $k" if exists $m->{$k} && (!_text($m->{$k}) || length($m->{$k}) > 2000);
    }
    if (exists $m->{stability}) {
        push @e, 'Invalid stability' unless _text($m->{stability}) && $m->{stability} =~ /\A(?:stable|beta|unstable|experimental)\z/;
    }
    if (exists $m->{safe_by_default}) {
        push @e, 'safe_by_default must be boolean' unless JSON::PP::is_bool($m->{safe_by_default});
    }
    for my $k (qw(supports permissions)) {
        next unless exists $m->{$k};
        if (!_list($m->{$k}, 16, 80)) { push @e, "$k must be a bounded string array"; next }
        my %seen;
        push @e, "Duplicate $k entry" if grep { $seen{$_}++ } @{$m->{$k}};
        if ($k eq 'permissions') {
            push @e, "Unsupported permission: $_" for grep { !/\A(?:read_terminal|suggest_commands|send_commands|parse_output|file_transfer|read_files|write_files)\z/ } @{$m->{$k}};
        }
    }
    for my $k (qw(entry ui metadata)) {
        push @e, "$k must be an object" if exists $m->{$k} && ref($m->{$k}) ne 'HASH';
    }
    if (ref($m->{entry}) eq 'HASH') {
        for my $k (keys %{$m->{entry}}) {
            push @e, "Unsupported entry: $k" unless $k =~ /\A(?:commands|prompts|device_rules)\z/;
            push @e, "Invalid local filename: $k" unless _filename($m->{entry}{$k});
        }
    }
    if (ref($m->{ui}) eq 'HASH') {
        for my $k (keys %{$m->{ui}}) {
            push @e, "Invalid ui field: $k" unless $k =~ /\Abadge_(?:bg|fg)\z/
                && _text($m->{ui}{$k}) && $m->{ui}{$k} =~ /\A#?[0-9a-fA-F]{6}\z/;
        }
    }
    if (exists $m->{logo}) {
        push @e, 'Invalid logo filename' unless _filename($m->{logo}) && $m->{logo} =~ /\.(?:bmp|png|jpg|jpeg|gif|txt)\z/i;
    }
    my $terms = ref($m->{metadata}) eq 'HASH' ? $m->{metadata}{activation_terms} : undef;
    push @e, 'Invalid activation_terms' if defined($terms) && (!_list($terms, 24, 80) || grep { !length } @$terms);
    return \@e;
}
sub read_text {
    my ($class, $path, $limit) = @_;
    die "Not a regular local file\n" unless -f $path && !-l $path;
    die "File exceeds $limit bytes\n" if -s $path > $limit;
    open my $fh, '<:raw', $path or die "Cannot read file: $!\n";
    my $n = read($fh, my $bytes, $limit + 1);
    close $fh;
    die "Cannot read bounded file\n" unless defined($n) && $n <= $limit;
    require Encode;
    my $text = Encode::decode('UTF-8', $bytes, Encode::FB_CROAK());
    die "Control characters in data\n" if $text =~ /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/;
    return $text;
}
sub load {
    my ($class, $path) = @_;
    my ($m, $data);
    my $ok = eval {
        $m = JSON::PP->new->decode($class->read_text($path, 16384));
        1;
    };
    return (undef, {}, ["Invalid manifest: " . ($@ || 'read failed')]) unless $ok;
    my $errors = $class->validate($m);
    return ($m, {}, $errors) if @$errors;
    my (undef, $dir) = File::Spec->splitpath(File::Spec->rel2abs($path));
    $dir = abs_path($dir);
    $data = {};
    my %files = %{$m->{entry} || {}};
    $files{logo} = $m->{logo} if $m->{logo};
    for my $kind (sort keys %files) {
        my $file = File::Spec->catfile($dir, $files{$kind});
        my $real = abs_path($file);
        if (!$real || -l $file || File::Spec->canonpath($real) ne File::Spec->canonpath($file) || !-f $file) {
            push @$errors, "Missing or nonlocal $kind file";
            next;
        }
        if ($kind eq 'logo') {
            push @$errors, 'Logo exceeds 512 KiB' if -s $file > 524288;
            next;
        }
        my $limit = $kind eq 'prompts' ? 8192 : 16384;
        my $success = eval {
            my $text = $class->read_text($file, $limit);
            if ($kind eq 'prompts') {
                die "Empty guidance\n" unless $text =~ /\S/;
                $data->{$kind} = $text;
            } else {
                my $obj = JSON::PP->new->decode($text);
                die "Entry must be an object\n" unless ref($obj) eq 'HASH';
                my %keys = map { $_ => 1 } ($kind eq 'commands'
                    ? qw(read_only caution destructive confirm_required safe_actions fallbacks notes)
                    : qw(prompt_patterns os_hints device_types protocols));
                for my $k (keys %$obj) {
                    die "Unsupported $kind key: $k\n" unless $keys{$k};
                    die "Invalid $kind list: $k\n" unless _list($obj->{$k}, 64, 2048);
                }
                $data->{$kind} = $obj;
            }
            1;
        };
        push @$errors, "Invalid $kind: $@" unless $success;
    }
    return ($m, @$errors ? {} : $data, $errors);
}
1;
