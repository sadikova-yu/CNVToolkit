use strict;
use warnings;
use Statistics::Basic::Median;
use Storable 'dclone';;
use Data::Dumper;

my $input = $ARGV[0];
die unless defined $input;

open (READ, "<$input");
my @mas;
while (<READ>) {
	chomp;
	push (@mas, $_)
	}
close READ;

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

sub go_forw {
	my @mas = @_;

	my @value;
	my $skip_count = 0;
	my $stop = -1;
	my @array;
	my $count_padding = 0;
	my $skip_cont_count = 0;
	for (my $i = 0; $i < scalar @mas; $i++) {
		my $sum_diff = 0;
		my $aver_diff = 0;
		my $diff = 0;
		my $count10 = 0;
		my $median = 0;
		if (($stop eq 0)or($stop eq -1)) {
			$median = median([(@array, $mas[$i])]);
			foreach my $arg ((@array, $mas[$i])) {
				$diff = abs($arg - $median);
				$sum_diff += $diff;
				}
			$aver_diff = $sum_diff/(scalar(@array) + 1);
			$diff = abs($mas[$i] - $median);
				if ((($mas[$i] >= 45)or($mas[$i] - median([@mas]) > 20))
					and($stop eq -1)
					and(median([@mas]) < 45)) {
					} elsif (($mas[$i] < 45)
					and((abs($mas[$i] - $median) < 15)
					or(abs($mas[$i] - median([@mas])) < 15)
					or($aver_diff < $value[((scalar @value) - 1)]))) {
					$stop = 0;
					push @value, $aver_diff;
					push @array, $mas[$i];
					$skip_cont_count = 0;
					} elsif (($skip_cont_count < (scalar(@array)/3))and
					(($skip_count < ((scalar(@array) + 1)/2))or(abs(median([@array]) - median([@mas]) < 10)))) {
						#push @value, $aver_diff;
						#push @array, $mas[$i];
						$skip_count += 1;
						$skip_cont_count += 1;
						}else {
						$stop = 1;
					}
			}
		if (($stop eq 1)or($stop eq -1)) {
			++$count_padding;
			}
		#print "$mas[$i]\t$median\t$aver_diff\t$stop\t$skip_count\t$skip_cont_count\t$count_padding\n";
		}
	$count_padding += $skip_cont_count;
	$skip_count -= $skip_cont_count;
	
	if (scalar(@array eq 0)) {
		return (0, 50, 1);
		}
	
	my @final_array;
	my $median = median([@array]);
	my $mean = mean([@array]);
	my $start = 0;
	my $end = scalar(@array) - 1;
	for (my $i = 0; $i < scalar @array; $i++) {
		if ($array[$i] > 40) {
			if ($array[$i] - $mean < 10) {
				$end = $i;
				last;
				}
			} elsif ($array[$i] - $mean < 15) {
			$start = $i;
			last;
			}
		}
	for (my $i = scalar(@array) - 1; $i > -1; $i--) {
		if ($array[$i] > 40) {
			if ($array[$i] - $mean < 10) {
				$end = $i;
				last;
				}
			} elsif ($array[$i] - $mean < 15) {
			$end = $i;
			last;
			}
		}
	#print "$start - $end\n";
	@final_array = @array[$start..$end];
	#print join("\n",@final_array),"\n";
	my $aver_dif;
	foreach my $arg (@final_array) {
		$aver_dif += abs(median([@final_array]) - $arg);
		}
	$aver_dif = $aver_dif / (scalar @final_array);
	#print "$skip_count\t",(scalar @array),"\t",(scalar @final_array),"\t$count_padding\n";
	my $penalty = 0.5*int($aver_dif) + 2*$skip_count + 3*((scalar @array) - (scalar @final_array) + $count_padding);
	return (scalar(@final_array), median([@final_array]), $penalty);
	#print "",(median([@final_array])),"\t$penalty\n";
	}


my @result;

sub iterate {
	my $input = shift;
	my $index = shift;
	if ($index eq scalar(@{$input})) {
		my $struct = dclone $input;
		push @result, $struct;
		} elsif (($input->[$index]->[2]) eq 'P') {
		iterate($input, $index + 1);
		} else {
		my $struct1 = dclone $input;
		my $struct2 = dclone $input;
		$struct1->[$index]->[2] = 'S';
		$struct2->[$index]->[2] = 'A';
		iterate($struct1, $index + 1);
		iterate($struct2, $index + 1);
		}
	}

sub print_status {
	my $inp = shift;
	for (my $i = 0; $i < scalar(@{$inp}); $i++) {
		print "",$inp->[$i]->[2],"\t";
		}
	}

sub score {
	my $inp = shift;
	my $is_devided = shift;
	my $s = shift;
	my $p = shift;
	my @active;
	my @skip;
	my @padding;
	my $prev_status = 'NA';

	for (my $i = 0; $i < scalar(@{$inp}); $i++) {
		my $status = $inp->[$i]->[2];
		my $value = $inp->[$i]->[1];
		if ($status eq 'A') {push @active, $value}
		if ($status eq 'S') {
			push @skip, $value;
			}
		if ($status eq 'P') {
			push @padding, $value;
			}
		$prev_status = $status;
		}
	my $mean = mean([@active]);
	my $sum_diff = 0;
	foreach my $arg (@active) {
		$sum_diff += abs($mean - $arg);
		}
	my $penalty_a = 0;
	my $penalty_s = 0;
	my $penalty_p = 0;
	if (scalar(@active) eq 0) {
		$penalty_a = 0;
		} else {
		$penalty_a = $sum_diff;#/(scalar @active);
		if ($is_devided eq 1) {
			$penalty_a = $penalty_a/(scalar @active);
			}
		#$penalty_a = $penalty_a*$penalty_a;
		#$penalty_a = $penalty_a - scalar(@active);
		}
	$penalty_s = $s*(scalar @skip);
	$penalty_p = $p*(scalar @padding);
	my $penalty = $penalty_a + $penalty_s + $penalty_p;
	return ($penalty);
	}

my $struct = [];

open (READ, "<$input");
my $index;
while (<READ>) {
	chomp;
	my @mas = split/\t/;
	push @{$struct}, [$mas[0], $mas[1], 'A'];
	}
close READ;

for (my $start = 0; $start < scalar(@{$struct}); $start++) {
	for (my $end = scalar(@{$struct}); $end > $start; $end--){
		my $tmp = dclone $struct;
		for (my $i = 0; $i < $start; $i++) {
			$tmp->[$i]->[2] = 'P';
			}
		for (my $i = $end; $i < (scalar(@{$struct})); $i++) {
			$tmp->[$i]->[2] = 'P';
			}
		iterate($tmp, 0);
		#print_status($tmp);
		}
	}

#for (my $i = 0; $i < scalar(@{$struct}); $i++) {
#	print "",$struct->[$i]->[0],"\t";
#	}
#print "\n";
#for (my $i = 0; $i < scalar(@{$struct}); $i++) {
#	print "",$struct->[$i]->[1],"\t";
#	}
#print "\n";

my $main;
foreach my $arg (sort {score($b, 0, 20, 15) <=> score($a, 0, 20, 15)} @result) {
#foreach my $arg (@result) {
#	print_status($arg);
#	print "",score($arg, 0, 20, 15),"";
#	print "\n";
	$main = $arg;
	}
#print_status($main);
my @active;
for (my $i = 0; $i < scalar(@{$main}); $i++) {
	my $status = $main->[$i]->[2];
	my $value = $main->[$i]->[1];
	if ($status eq 'A') {push @active, $value}
	}

my $mean = int(mean([@active]));
my $length = scalar(@{$main});
my $score = int(score($main, 1, 5, 5));

print "$mean\t$length\t$score\n";





























