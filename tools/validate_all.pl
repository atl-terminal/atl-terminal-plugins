use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use ATL::PluginSDK::Package;
use JSON::PP ();
my @files = sort glob('plugins/*/*/plugin.json');
my (@errors, %ids, %paths);
for my $file (@files) {
    my ($m, undef, $e) = ATL::PluginSDK::Package->load($file);
    push @errors, map { "$file: $_" } @$e;
    if (ref($m) eq 'HASH') {
        push @errors, "Duplicate id: $m->{id}" if $ids{$m->{id}}++;
        $paths{$file} = $m->{id};
    }
    print "OK $file\n" unless @$e;
}
push @errors, 'No plugins found' unless @files;
my $index = eval { JSON::PP->new->decode(ATL::PluginSDK::Package->read_text('plugin-index.json', 32768)) };
if (!$index || ref($index) ne 'HASH' || ($index->{api_version} || '') ne '1.0' || ref($index->{plugins}) ne 'ARRAY') {
    push @errors, 'Invalid plugin index';
} else {
    my %seen;
    for my $entry (@{$index->{plugins}}) {
        if (ref($entry) ne 'HASH') { push @errors, 'Invalid index entry'; next }
        my $path = $entry->{path} || '';
        push @errors, "Index path/id mismatch: $path" unless exists $paths{$path} && $paths{$path} eq ($entry->{id} || '');
        push @errors, "Duplicate index path: $path" if $seen{$path}++;
    }
    push @errors, "Missing index entry: $_" for grep { !$seen{$_} } keys %paths;
}
if (@errors) { print "INVALID\n", map { " - $_\n" } @errors; exit 1 }
print "Validated " . scalar(@files) . " plugin(s).\n";
