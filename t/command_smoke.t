use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use lib 'lib';
use ATL::PluginSDK::Package;
plan skip_all => 'Set ATL_PLUGIN_COMMAND_SMOKE=1 on a Linux sandbox with git, Docker and systemd'
    unless $ENV{ATL_PLUGIN_COMMAND_SMOKE} && $^O eq 'linux';
my $root = getcwd;
my $tmp = tempdir(CLEANUP => 1);
# All created files and Git state stay in a disposable directory.
local $ENV{HOME} = $tmp;
local $ENV{GIT_CONFIG_NOSYSTEM} = 1;
local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_COUNT} = 0;
local $ENV{GIT_DIR};
local $ENV{GIT_WORK_TREE};
local $ENV{GIT_INDEX_FILE};
chdir $tmp or die $!;
is(system('git', 'init', '-q'), 0, 'initialize disposable repository');
for my $slug (qw(git systemd docker)) {
    my ($m, $data, $e) = ATL::PluginSDK::Package->load("$root/plugins/tools/$slug/plugin.json");
    is_deeply($e, [], "$slug package loads");
    for my $cmd (@{$data->{commands}{read_only}}) {
        # Use the exact catalog command, not a hand-written approximation.
        # Pipefail exposes permission/daemon failures instead of passing on head's exit.
        my @args = ('timeout', '25s', 'bash', '-o', 'pipefail', '-c', "( $cmd ) 2>&1");
        open my $fh, '-|', @args or die $!;
        my $output = do { local $/; <$fh> };
        close $fh;
        my $exit = $? >> 8;
        if ($slug eq 'git' && $cmd =~ /git --no-pager log/) {
            isnt($exit, 0, 'empty repository is reported as an error, not invented commits');
            like($output, qr/does not have any commits/, 'empty history has real diagnostic');
        } elsif ($slug eq 'docker' && $cmd =~ /docker ps/ && $exit) {
            like($output, qr/(?:connect|permission denied|daemon)/i, 'unavailable daemon produces real error');
            diag('Docker daemon success path NOT verified on this host; negative connection path verified.');
        } else {
            is($exit, 0, "$slug command runs successfully");
            diag(substr($output, 0, 500)) if $exit;
        }
        cmp_ok(length($output), '<=', 32768, "$slug output bounded");
    }
}
chdir $root or die $!;
done_testing;
