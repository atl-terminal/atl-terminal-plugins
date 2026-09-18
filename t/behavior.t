use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib 'lib';
use ATL::PluginSDK::Package;
use ATL::PluginSDK::Context;
my @plugins;
for my $file (sort glob('plugins/*/*/plugin.json')) {
    my ($m, $data, $e) = ATL::PluginSDK::Package->load($file);
    push @plugins, { manifest => $m, data => $data, errors => $e };
}
my $cases = JSON::PP->new->decode(ATL::PluginSDK::Package->read_text('t/fixtures/selection.json', 32768));
for my $c (@$cases) {
    my $chosen = ATL::PluginSDK::Context->select(\@plugins, request => $c->{request}, protocol => $c->{protocol});
    is_deeply([sort map { $_->{id} } @$chosen], [sort @{$c->{ids}}], $c->{name});
    my $text = ATL::PluginSDK::Context->render(\@plugins, request => $c->{request}, protocol => $c->{protocol});
    like($text, qr/\Q$c->{contains}\E/, "$c->{name}: actual entry content delivered") if $c->{contains};
}
my ($docker) = grep { $_->{manifest}{id} eq 'atl.tool.docker' } @plugins;
my %bad = (%$docker, errors => ['invalid package']);
is_deeply(ATL::PluginSDK::Context->select([\%bad], request => 'docker', protocol => 'ssh'), [], 'disabled plugin excluded');
my %no_permission = (%$docker, manifest => { %{$docker->{manifest}}, permissions => [] });
is_deeply(ATL::PluginSDK::Context->select([\%no_permission], request => 'docker', protocol => 'ssh'), [], 'no undeclared guidance permission');
my $all = ATL::PluginSDK::Context->select(\@plugins, request => 'code cisco linux nano vim docker git systemd nmap', protocol => 'ssh');
cmp_ok(scalar(@$all), '<=', 4, 'selection count bounded');
cmp_ok(length(JSON::PP->new->ascii->encode($all)), '<=', 12010, 'total serialized reference bounded');
for my $p (grep { $_->{manifest}{id} =~ /atl\.tool\.(?:docker|git|systemd)\z/ } @plugins) {
    for my $cmd (@{$p->{data}{commands}{read_only}}) {
        unlike($cmd, qr/\b(?:prune|restart|reset|clean|--follow)\b/, 'new inspection catalog contains no mutation/live follow');
        like($cmd, qr/command -v|timeout 15s/, 'external calls have a discovery step or deadline');
    }
}
done_testing;
