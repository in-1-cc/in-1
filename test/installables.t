#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::More;

my $root = tempdir(CLEANUP => 1);
my $makes = "$root/makes";
make_path($makes);

write_file(
    "$makes/alpha.mk",
    <<'MAKE',
ALPHA-VERSION ?= 1.2.3
# https://alpha.example/

ALPHA-DOWN := https://github.com/example/alpha
ALPHA-DOWN := $(ALPHA-DOWN)/releases/download/v$(ALPHA-VERSION)/alpha.tgz
MAKE
);
write_file(
    "$makes/beta.mk",
    <<'MAKE',
include $(MAKES)/alpha.mk
MAKE
);
write_file(
    "$makes/gamma.mk",
    <<'MAKE',
GAMMA-VERSION ?= 9.9.9
# https://gamma.example/
MAKE
);
write_file(
    "$makes/delta.mk",
    <<'MAKE',
DELTA-VERSION ?= 4.5.6
# https://github.com/example/delta
MAKE
);
write_file("$makes/init.mk", "# helper, not an installable\n");
write_file(
    "$makes/langs.yaml",
    <<'YAML',
Alpha:
  slug: alpha
  makes: true
YAML
);
write_file("$root/in-1", "tool_filter='init'\n");
write_file(
    "$root/tools.mk",
    <<'MAKE',
alpha-completion := bash zsh fish
alpha-auth := alpha-main
alpha-desc := Alpha language for testing generated tables
alpha-man := alpha
alpha-repo := https://github.com/example/alpha
alpha-site := https://alpha.example/
beta-auth := beta-main
beta-desc := Beta wrapper for the Alpha language
beta-repo := https://github.com/example/alpha
delta-auth := delta-main
delta-desc := Delta tool for testing commit fallbacks
delta-repo := https://github.com/example/delta
gamma-auth := gamma-main
gamma-desc := Gamma tool without available release activity
gamma-repo := https://github.com/example/gamma
MAKE
);
write_file(
    "$root/support.md",
    <<'MARKDOWN',
## Completion only

| Installable | Shells |
| --- | --- |
| `beta` | Bash |
MARKDOWN
);
write_file(
    "$root/releases.tsv",
    "alpha\t1.2.3\t2026-09-30\n",
);
write_file(
    "$root/commits.tsv",
    "https://github.com/example/delta\t2026-09-29\n",
);

open my $output, '-|',
    $^X, 'www/util/installables', $makes, "$root/in-1", "$root/tools.mk",
    "$root/support.md", "$makes/langs.yaml", "$root/releases.tsv",
    "$root/commits.tsv"
    or die "Can't run installables generator: $!\n";
my $page = do { local $/; <$output> };
close $output or die "Installables generator failed\n";

like $page,
    qr{<a href="https://alpha\.example/">alpha</a>},
    'Name links to the project website';
my $release_link = '<a href="https://github.com/example/alpha/' .
    'releases/tag/v1.2.3">1.2.3</a>';
like $page, qr{\Q$release_link\E},
    'Version links to the release page';
like $page,
    qr{data-sort-value="alpha".*?data-sort-value="2">
       <span\ class="support-yes".*?>&#8730;</span></td>
       .*?data-sort-value="2"><span\ class="support-yes"}sx,
    'Configured completion and man support are shown';
like $page, qr{<tr id="alpha" data-repository=},
    'Rows use the tool name as their stable ID';
my $order_link = '<a href="#alpha" aria-label="Link to alpha">' .
    '<strong>1</strong></a>';
like $page, qr{\Q$order_link\E},
    'Order numbers link to the tool ID';
like $page,
    qr{class="installable-type" data-sort-value="Language".*?&lt;/&gt;}s,
    'Language installables have a code icon';
like $page,
    qr{class="installable-type" data-sort-value="Tool".*?&#128296;}s,
    'Tool installables have a hammer icon';
like $page, qr{data-sort-value="2026-09-30">2026-09-30</td>},
    'Release date is shown for the matching version';
like $page,
    qr{data-sort-value="beta".*?data-sort-value="2026-09-30"}s,
    'Wrapper installables inherit the underlying release date';
like $page,
    qr{data-sort-value="delta".*?data-sort-value="2026-09-29".*?
       Latest\ repository\ commit\ date}sx,
    'Latest commit date is used when a release date is unavailable';
like $page,
    qr{href="https://github\.com/alpha-main".*?
       src="https://github\.com/alpha-main\.png\?size=64".*?
       alt="\@alpha-main"}sx,
    'Configured committer avatar links to the GitHub profile';
like $page,
    qr{data-sort-value="delta".*?href="https://github\.com/delta-main"}s,
    'Each installable uses its configured main committer';
like $page, qr{aria-label="Release date unavailable"},
    'Missing release dates are identified';
like $page,
    qr{data-sort-value="beta".*?data-sort-value="1\.2\.3"}s,
    'Wrapper installables inherit their tool version';
like $page,
    qr{data-sort-value="beta".*?data-sort-value="1">
       <span\ class="support-available".*?>&#8730;\*</span></td>
       .*?data-sort-value="0"><span\ class="support-no"}sx,
    'Available support is starred and dependency support is not inherited';
unlike $page, qr{data-sort-value="init"},
    'Helper modules are excluded';
like $page, qr{data-sort-key="name"},
    'Sortable column keys are generated';
like $page, qr{class="sort-marker" aria-hidden="true">&#8597;</span>},
    'Sortable headers have a visible marker';
like $page, qr{data-tooltip="Tab Completion".*?>\s*Comp\s}s,
    'Comp header has a descriptive tooltip';
like $page, qr{data-tooltip="Man Pages".*?>\s*Man\s}s,
    'Man header has a descriptive tooltip';
like $page, qr{data-tooltip="Installable name".*?>\s*Name\s}s,
    'Name header has a descriptive tooltip';
like $page,
    qr{data-sort-key="description".*?data-tooltip="Short project description"}s,
    'Description header has a descriptive tooltip';
like $page,
    qr{data-sort-key="by".*?>\s*By\s+<span}s,
    'By column uses the compact heading';
like $page,
    qr{data-sort-value="Alpha language for testing generated tables"},
    'Configured description is shown in the final column';

my $sort_script = read_file('www/docs/javascripts/installables.js');
like $sort_script,
    qr{column === columns\.completion \|\| column === columns\.man},
    'Dates and capability columns sort newest or supported first';
like $sort_script, qr{rect\.top - tooltip\.offsetHeight - 8},
    'Header tooltips are positioned above their labels';

my $table_style = read_file('www/docs/stylesheets/installables.css');
like $table_style,
    qr{table:not\(\[class\]\).*?min-width:\s*0.*?width:\s*100%}s,
    'Table uses the available page width';
like $table_style,
    qr{table:not\(\[class\]\) th,.*?min-width:\s*0.*?width:\s*1px}s,
    'Every column overrides the theme minimum width';
like $table_style,
    qr{\.installable-description.*?white-space:\s*normal.*?width:\s*auto}s,
    'Description cells use remaining width and can wrap';
my $target_highlight = '.installables-table tbody tr:target {' . "\n" .
    '  background-color: var(--md-typeset-table-color--light);';
like $table_style, qr{\Q$target_highlight\E},
    'A linked tool row uses the table hover highlight';
like $table_style,
    qr{max-width: 48rem.*?nth-child\(9\).*?display: none}s,
    'Narrow desktop view keeps columns through Man';
like $table_style,
    qr{max-width: 40rem.*?nth-child\(n \+ 8\).*?display: none}s,
    'Wide phone view keeps columns through Comp';
like $table_style,
    qr{max-width: 32rem.*?nth-child\(n \+ 5\).*?display: none}s,
    'Medium phone view keeps columns through Date';
like $table_style,
    qr{max-width: 24rem.*?nth-child\(n \+ 4\).*?display: none}s,
    'Narrow phone view keeps columns through Version';

done_testing;

sub write_file {
    my ($file, $content) = @_;
    open my $handle, '>', $file or die "Can't write '$file': $!\n";
    print {$handle} $content;
    close $handle or die "Can't close '$file': $!\n";
}

sub read_file {
    my ($file) = @_;
    open my $handle, '<', $file or die "Can't read '$file': $!\n";
    local $/;
    return <$handle>;
}
