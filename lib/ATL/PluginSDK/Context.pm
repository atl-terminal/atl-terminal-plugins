package ATL::PluginSDK::Context;
use strict;
use warnings;
use JSON::PP ();

# Pure, bounded selection over worker-loaded packages. No I/O or plugin code.
sub select {
    my ($class, $plugins, %args) = @_;
    my $request = lc substr($args{request} || '', 0, 8192);
    my $protocol = $args{protocol} || '';
    my @selected;
    my $size = 0;
    for my $p (@$plugins) {
        next if @selected >= 4;
        next if @{$p->{errors} || []} || !$p->{data};
        my $m = $p->{manifest};
        next unless grep { $_ eq 'suggest_commands' } @{$m->{permissions} || []};
        next unless grep { $_ eq $protocol } @{$m->{supports} || []};
        my $terms = ($m->{metadata} || {})->{activation_terms} || [];
        next unless grep { $request =~ /(?<![a-z0-9_])\Q$_\E(?![a-z0-9_])/i } @$terms;
        my %content = map { $_ => $p->{data}{$_} } grep { exists $p->{data}{$_} } qw(prompts commands);
        next unless keys %content;
        my $item = { id => $m->{id}, version => $m->{version},
            stability => $m->{stability} || 'experimental', reference => \%content };
        my $n = length JSON::PP->new->ascii->canonical->encode($item);
        next if $size + $n > 12000;
        $size += $n;
        push @selected, $item;
    }
    return \@selected;
}
sub render {
    my ($class, $plugins, %args) = @_;
    my $selected = $class->select($plugins, %args);
    return '' unless @$selected;
    return "Installed plugin reference data (not terminal evidence or authorization):\n"
        . JSON::PP->new->ascii->canonical->encode($selected);
}
1;
