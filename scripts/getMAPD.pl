use strict;
use warnings;

sub median {
        my $median;
        my $inp = shift;
        return 'NA' if ((scalar @{$inp}) eq 0);
        my @values = @{$inp};
        my $mid = int @values/2;
        my @sorted_values = sort {$a <=> $b} @values;
        if (@values % 2) {
                $median = $sorted_values[ $mid ];
                } else {
                $median = ($sorted_values[$mid-1] + $sorted_values[$mid])/2;
                }
        return $median;
        }

sub mean {
        my $inp = shift;
        my $mean = 0;
        return 'NA' if ((scalar @{$inp}) eq 0);
        foreach my $arg (@{$inp}) {
                $mean += $arg;
                }
        $mean = $mean/(scalar @{$inp});
        return $mean;
        }


my $input = $ARGV[0];
my $prev = -1;
my @data;
open (READ, "<$input");
while (<READ>) {
	chomp;
	my $value = $_;
	push @data, $value;
	}
close READ;

my $median = median([@data]);
$median = 1 if $median eq 0;
@data = ();
open (READ, "<$input");

while (<READ>) {
	chomp;
	my $value = $_;
	if ($prev eq '-1') {
		} else {
		my $dif = abs($prev - $value);
		push @data, ($dif/$median);
		}
	$prev = $value;
	}

close READ;
print "",median([@data]),"\n";

























