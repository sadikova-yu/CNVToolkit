use strict;
use warnings;
use Dir::Self;
use Data::Dumper;
use threads;
use Storable qw ( freeze thaw );
use List::Util qw(min);
use List::MoreUtils qw(uniq);
use Thread::Queue;
use Getopt::Long 'GetOptions';
use Pod::Usage;

sub generate_seed {
	my @set = ('0' ..'9', 'A' .. 'Z', 'a' .. 'z');
	my $str = join '' => map $set[rand @set], 1 .. 15;
	return $str
	}


sub round_q {
	my $inp = shift;
	$inp = int($inp*1000)/1000;
	}

sub run {
	my $options = shift;
	my $bam = $options->{bam};
	my $panel = $options->{panel};
	my $tmp_folder = $options->{tmp_folder};
	my $current_dir = $options->{current_dir};
	my $seed = $options->{seed};
	
	my $pool1 = "$current_dir/../config/$panel/$panel.designed.pool_1.grep.bed";
	my $pool2 = "$current_dir/../config/$panel/$panel.designed.pool_2.grep.bed";

	`samtools depth -b $pool1 $bam | awk '{print \$3}' > $tmp_folder/$seed.1.depth.3`;
	`samtools depth -b $pool2 $bam | awk '{print \$3}' > $tmp_folder/$seed.2.depth.3`;
	`cat $tmp_folder/$seed.1.depth.3 > $tmp_folder/$seed.depth.3`;
	`cat $tmp_folder/$seed.2.depth.3 >> $tmp_folder/$seed.depth.3`;
	my $E = `R --slave -f $current_dir/getE.R --args $tmp_folder/$seed.depth.3`;chomp $E;$E = round_q($E);
	my $C = `R --slave -f $current_dir/getC.R --args $tmp_folder/$seed.depth.3`;chomp $C;
	my $MAPD = `perl $current_dir/getMAPD.pl $tmp_folder/$seed.depth.3`;chomp $MAPD;$MAPD = round_q($MAPD);
	my $E1 = `R --slave -f $current_dir/getE.R --args $tmp_folder/$seed.1.depth.3`;chomp $E1;$E1 = round_q($E1);
	my $C1 = `R --slave -f $current_dir/getC.R --args $tmp_folder/$seed.1.depth.3`;chomp $C1;
	my $MAPD1 = `perl $current_dir/getMAPD.pl $tmp_folder/$seed.1.depth.3`;chomp $MAPD1;$MAPD1 = round_q($MAPD1);
	my $E2 = `R --slave -f $current_dir/getE.R --args $tmp_folder/$seed.2.depth.3`;chomp $E2;$E2 = round_q($E2);
	my $C2 = `R --slave -f $current_dir/getC.R --args $tmp_folder/$seed.2.depth.3`;chomp $C2;
	my $MAPD2 = `perl $current_dir/getMAPD.pl $tmp_folder/$seed.2.depth.3`;chomp $MAPD2;$MAPD2 = round_q($MAPD2);
	print "$E\t$MAPD\t$C\t$E1\t$MAPD1\t$C1\t$E2\t$MAPD2\t$C2\n";
	}


sub option_builder {
        my ($factory) = @_;
        my %opts;
        &GetOptions (
                'h|help'        => \$opts{'h'},
                'bam|bam=s'   => \$opts{'bam'},
                'panel|panel=s' => \$opts{'panel'},
                'seed|seed=s'   => \$opts{'seed'}
        );
        pod2usage(0) if($opts{'h'});
        pod2usage(1) if(!$opts{'bam'});
        pod2usage(1) if(!$opts{'panel'});
        return \%opts;
        }

{
        my $options = option_builder();
        my $current_dir = __DIR__;
        $options->{current_dir} = $current_dir;
        $options->{tmp_folder} = "$current_dir/../tmp";
	open (READ, "<$current_dir/../resources.csv");
	while (<READ>) {
		chomp;
		my @mas = split/,/;
		if ($mas[0] eq 'AODBETA') {
			$options->{AODBETA} = $mas[1];
			}
		}
	close READ;
        $options->{seed} = generate_seed() unless defined($options->{seed});

        eval {run($options)};
        if ($@) {
                print STDERR "$@\n";
                } else {
                }

}


__END__

=head1 NAME

MAIN QC DESC

=head1 SYNOPSIS

Get qualty measure descriptors for CNV calling
OUTPUT FORMAT:

Options:

    -bam    [REQUIRED] - input .bam file
    -panel  [REQUIRED] - amplicon panel [AODABCV1]

