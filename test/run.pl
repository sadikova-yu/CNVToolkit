use strict;
use warnings;
use threads;
use Thread::Queue;

my $input = $ARGV[0];
$input = 'list_illmn' unless defined $input;
my $current_dir = '/home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODCNV/test/';

my $work = Thread::Queue->new;

#goto JOINR;

sub worker {
        while ( my $passed = $work->dequeue ) {
                my $bam = $passed->[1];
		my $sample = $passed->[0];
                print STDERR "STARTED SAMPLE $sample\n";
		#my $cmd = "perl $current_dir/../scripts/get_snp.pl -bam $bam -panel AODABCV1 -output vaf > $current_dir/tmp/$sample.vaf";
		#print "$cmd\n";
		`perl $current_dir/../scripts/get_snp.pl -bam $bam -panel AODABCV1 -output vaf > $current_dir/tmp/$sample.vaf`;
		`perl $current_dir/../scripts/get_snp.pl -bam $bam -panel AODABCV1 -output desc > $current_dir/tmp/$sample.desc`;
		`perl $current_dir/../scripts/get_qc.pl -bam $bam -panel AODABCV1 > $current_dir/tmp/$sample.qc`;
		`python3 $current_dir/../scripts/coverage.py $bam > $current_dir/tmp/$sample.cov`;
                }
        }

threads->create( \&worker ) for 1 .. (10);
open (READ, "<$input");
while (<READ>) {
	chomp;
	my @mas = split/\t/;
	$work->enqueue( [$mas[0], $mas[1]] );
	}
close READ;
$work->end;
$_->join for threads->list;

JOINR:

open (READ, "<$input");
while (<READ>) {
	chomp;
	my @mas = split/\t/;
	my $sample = $mas[0];
	my $res;
	print "$sample";
	$res = `cat $current_dir/tmp/$sample.vaf`;chomp $res;print "\t$res";
	$res = `cat $current_dir/tmp/$sample.desc`;chomp $res;print "\t$res";
	$res = `cat $current_dir/tmp/$sample.qc`;chomp $res;print "\t$res";
	my $cov = `cat $current_dir/tmp/$sample.cov`;
	my @data = split/\n/, $cov;
	my @result;
	my @genes = qw(ATM BRCA1 BRCA2);
	for (my $i = 0; $i < 3; $i++) {
		if ($data[$i] =~ /(\S+)\s+\[(\S+),\s+(\S+)\]/) {
			die unless $1 eq $genes[$i];
			push @result, int(100*$2)/100;
			push @result, int(100*$3)/100;
			}
		}
	print "\t",join("\t", @result),"\n";
	}
close READ;














