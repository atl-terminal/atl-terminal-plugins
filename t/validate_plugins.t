use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use File::Find;

my @plugins;
find({
    wanted => sub {
        push @plugins, $File::Find::name if $File::Find::name =~ /(?:^|[\\\/])plugin\.json\z/;
    },
    no_chdir => 1,
}, 'plugins');

ok(@plugins >= 6, 'curated plugin manifests are present');

my $output = `"$^X" tools/validate_all.pl 2>&1`;
is($? >> 8, 0, 'all plugins validate');
like($output, qr/Validated \d+ plugin\(s\)\./, 'validator reports count');

my %ids;
my %families;
for my $plugin (@plugins) {
    open my $fh, '<:encoding(UTF-8)', $plugin or die "Cannot open $plugin: $!";
    my $data = decode_json(do { local $/; <$fh> });
    close $fh;

    ok(!$ids{$data->{id}}++, "$data->{id} is unique");
    $families{$data->{type}}++;
}

for my $family (qw(device tool tui code)) {
    ok($families{$family}, "$family family has at least one plugin");
}

open my $index_fh, '<:encoding(UTF-8)', 'plugin-index.json'
    or die "Cannot open plugin-index.json: $!";
my $index = decode_json(do { local $/; <$index_fh> });
close $index_fh;

is(scalar(@{ $index->{plugins} || [] }), scalar(@plugins), 'plugin index covers every plugin');

done_testing;
