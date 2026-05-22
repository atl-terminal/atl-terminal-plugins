use strict;
use warnings;
use JSON::PP qw(decode_json);
use File::Find;
use File::Spec;

my %type = map { $_ => 1 } qw(device tool tui code);
my %permission = map { $_ => 1 } qw(
  read_terminal
  suggest_commands
  send_commands
  parse_output
  file_transfer
  read_files
  write_files
);

my @files;
find({
    wanted => sub {
        push @files, $File::Find::name if $File::Find::name =~ /(?:^|[\\\/])plugin\.json\z/;
    },
    no_chdir => 1,
}, 'plugins');

my @errors;
for my $file (sort @files) {
    my ($ok, $messages) = validate_plugin($file);
    if ($ok) {
        print "OK $file\n";
    } else {
        push @errors, map { "$file: $_" } @$messages;
    }
}

if (!@files) {
    push @errors, 'No plugin manifests found under plugins/';
}

if (@errors) {
    print "INVALID\n";
    print " - $_\n" for @errors;
    exit 1;
}

print "Validated " . scalar(@files) . " plugin(s).\n";
exit 0;

sub validate_plugin {
    my ($path) = @_;
    my @errors;

    open my $fh, '<:encoding(UTF-8)', $path
        or return (0, ["Cannot open plugin manifest: $!"]);
    my $json = do { local $/; <$fh> };
    close $fh;

    my $data = eval { decode_json($json) };
    if (!$data || ref($data) ne 'HASH') {
        return (0, ["Invalid JSON: " . ($@ || 'not an object')]);
    }

    for my $field (qw(id name type api_version version)) {
        push @errors, "Missing required field: $field"
            if !defined $data->{$field} || $data->{$field} eq '';
    }

    if (defined $data->{id} && $data->{id} !~ /\A[a-z0-9][a-z0-9_.-]*\z/) {
        push @errors, "Invalid id format: $data->{id}";
    }

    if (defined $data->{type} && !$type{$data->{type}}) {
        push @errors, "Unsupported plugin type: $data->{type}";
    }

    if (defined $data->{api_version} && $data->{api_version} ne '1.0') {
        push @errors, "Unsupported plugin API version: $data->{api_version}";
    }

    if (defined $data->{permissions}) {
        if (ref($data->{permissions}) ne 'ARRAY') {
            push @errors, "permissions must be an array";
        } else {
            for my $perm (@{ $data->{permissions} }) {
                push @errors, "Unsupported permission: $perm" if !$permission{$perm};
            }
        }
    }

    for my $field (qw(supports)) {
        push @errors, "$field must be an array"
            if defined $data->{$field} && ref($data->{$field}) ne 'ARRAY';
    }

    for my $field (qw(entry ui metadata)) {
        push @errors, "$field must be an object"
            if defined $data->{$field} && ref($data->{$field}) ne 'HASH';
    }

    my (undef, $dir, undef) = File::Spec->splitpath(File::Spec->rel2abs($path));

    if (defined $data->{logo}) {
        if ($data->{logo} =~ /[\\\/]/ || $data->{logo} !~ /\.(?:bmp|png|jpe?g|gif|txt)\z/i) {
            push @errors, "logo must be a local filename with a supported extension";
        } else {
            my $logo_path = File::Spec->catfile($dir, $data->{logo});
            push @errors, "logo file not found: $data->{logo}" if !-f $logo_path;
        }
    }

    if (ref($data->{entry}) eq 'HASH') {
        for my $field (keys %{ $data->{entry} }) {
            my $entry = $data->{entry}{$field};
            if (!defined $entry || $entry =~ /[\\\/]/) {
                push @errors, "entry $field must be a local filename";
                next;
            }
            my $entry_path = File::Spec->catfile($dir, $entry);
            push @errors, "entry file not found: $entry" if !-f $entry_path;
        }
    }

    return (!@errors, \@errors);
}
