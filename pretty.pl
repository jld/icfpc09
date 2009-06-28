#!/usr/bin/perl
while (<>) {
    /(.*?): \[(.*?)\] (\S+) ?(.*)/;
    $i=hex($1);
    $data[$i] = 0.0 + $2;
    $insn[$i] = $3;
    $args[$i] = [map { hex } split / /,$4];
    $ioop[$i] = $insn[$i] =~ /put$/;
    $noop[$i] = $insn[$i] =~ /(^Noop|^Output|Z)$/;
}

$max = $#insn;
for $i (0..$max) {
    for $arg (@{$args[$i]}) {
	next if $ioop[$i] and $arg==0;
	$state[$arg]=1 if $arg >= $i;
	++$refs{$arg};
    }
}

for $i (0..$max) {
    $name[$i] = "v$i" if $state[$i] or $refs{$i}>1;
}

sub forvalue {
    my ($i,$top) = @_;
    return "0" if $i > $max;
    return $data[$i] if $noop[$i];
    return $name[$i] if defined $name[$i] and not $top;
    return "in$args[$i][0]" if $insn[$i] eq "Input";
    my $fun = {
	Sqrt => sub { "sqrt($_[0])" },
	Copy => sub { $_[0] },
	Add => sub { "($_[0] + $_[1])" },
	Sub => sub { "($_[0] - $_[1])" },
	Mult => sub { "$_[0] * $_[1]" },
	Div => sub { "$_[0] / $_[1]" },
	Phi => sub { "($stat ? $_[0] : $_[1])" }
    }->{$insn[$i]};
    return $fun->(map { forvalue($_) } @{$args[$i]});
}

sub foreffect {
    my ($i) = @_;
    return "" if $insn[$i] eq "Noop";
    my $dfl = sub {
	if (defined $name[$i]) {
	    my $v = forvalue($i,1);
	    return "$name[$i] = $v;\n";
	} else {
	    return "";
	}
    };
    my $cmp = sub {
	my ($op) = @_;
	sub {
	    my $l = forvalue($_[0]);
	    $stat = "$l $op 0";
	    return "";
	}
    };
    my $fun = {
	Output => sub {
	    my $v = forvalue($_[1]);
	    return "out$_[0] = $v;\n";
	},
	LTZ => $cmp->("<"),
	LEZ => $cmp->("<="),
	EQZ => $cmp->("=="),
	GEZ => $cmp->(">="),
	GTZ => $cmp->(">")
    }->{$insn[$i]};
    $fun = $dfl unless defined $fun;
    return $fun->(@{$args[$i]});
}

$stat = "XXX";
for $i (0..$max) {
    print foreffect($i);
}
