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

sub get_AF_from_info {
	my $info = shift;
	my @data = split/;/, $info;
	if ($info =~ /AODAF=([^;]+)/) {
		return $1;
		}
	return 0;
	}

sub run {
	my $options = shift;
	my $bam = $options->{bam};
	my $panel = $options->{panel};
	my $tmp_folder = $options->{tmp_folder};
	my $AODBETA = $options->{AODBETA};
	my $current_dir = $options->{current_dir};
	my $seed = $options->{seed};
	open (GENELIST, "<$current_dir/../config/$panel/gene_list");
	my @genes;
	while (<GENELIST>) {
		chomp;
		my $gene = $_;
		push @genes, $gene;
		`perl $AODBETA/get_counts_for_sample.pl -s $bam -v $current_dir/../config/$panel/$gene.vcf -p $current_dir/../config/$panel/$panel.designed.bed -n 10 -o $tmp_folder/$gene$seed.cdata`;
		`perl $AODBETA/make_call.pl -v $current_dir/../config/$panel/$gene.vcf -bdata $current_dir/../config/$panel/bdata -cdata $tmp_folder/$gene$seed.cdata > $tmp_folder/$gene$seed.calls`;
		`perl $AODBETA/makeVCF.pl -input $tmp_folder/$gene$seed.calls -output $tmp_folder/$gene$seed.vcf -sample $bam`;
		`perl $AODBETA/filterVCF.pl -input $tmp_folder/$gene$seed.vcf`;
		}
	close GENELIST;

	if ($options->{output} eq 'vaf') {
		my @data;
		for (my $i = 0; $i < scalar @genes; $i++) {
			open (READ, "<$tmp_folder/$genes[$i]$seed.vcf");
			while (<READ>) {
				chomp;
				next if m!^#!;
				my @mas = split/\t/;
				if ($mas[6] eq 'FAIL') {
					push @data, 0;
					} else {
					my $vaf = get_AF_from_info($mas[7]);
					$vaf = int($vaf*100);
					if ($vaf > 50) {$vaf = 100-$vaf};
					push @data, $vaf;
					}
				}
			close READ;
			`rm $tmp_folder/$genes[$i]$seed.vcf`;
			}
		print "",join("\t", @data),"\n";
		} else {
		my @result;
		for (my $i = 0; $i < scalar @genes; $i++) {
			my $gene = $genes[$i];
			open (READ, "<$tmp_folder/$gene$seed.vcf");
			open (WRITE, ">$tmp_folder/$gene$seed.res");
			
			my $count = 0;
			while (<READ>) {
				chomp;
				next if m!^#!;
				my @mas = split/\t/;
				if ($mas[6] eq 'PASS') {
					my $ad = 0;
					my $dp = 0;
					if ($mas[7] =~ /AODAD=(\d+),(\d+);/) {
						$ad = $1;
						$dp = $2;
						}
					if ($dp > 0) {
						if (($ad/$dp < 0.90)and($ad/$dp > 0.1)) {
							my $vaf = get_AF_from_info($mas[7]);
							$vaf = int($vaf*100);
							$vaf = 100 - $vaf if $vaf > 50;
							my $name = "$mas[0]:$mas[1]$mas[3]>$mas[4]";
							print WRITE "$name\t$vaf\n";
							++$count;
							}
						}
					}
				}
			
			close WRITE;
			close READ;
			if ($count eq 0) {
				push @result, 50;
				push @result, 0;
				push @result, 0;
				}else {
				my $measure = `perl $current_dir/measure.pl $tmp_folder/$gene$seed.res`;
				chomp $measure;
				$measure = [split/\t/, $measure];
				push @result, $measure->[0];
				push @result, $measure->[1];
				push @result, $measure->[2];
				}
			`rm $tmp_folder/$gene$seed.vcf`;
			`rm $tmp_folder/$gene$seed.res`;
			`rm $tmp_folder/$gene$seed.cdata`;
			`rm $tmp_folder/$gene$seed.calls`;
			}
		print "",join("\t", @result),"\n";
		}
	

	}


sub option_builder {
        my ($factory) = @_;
        my %opts;
        &GetOptions (
                'h|help'        => \$opts{'h'},
                'bam|bam=s'   => \$opts{'bam'},
                'panel|panel=s' => \$opts{'panel'},
		'output|output=s' => \$opts{'output'},
                'seed|seed=s'   => \$opts{'seed'}
        );
        pod2usage(0) if($opts{'h'});
        pod2usage(1) if(!$opts{'bam'});
        pod2usage(1) if(!$opts{'panel'});
	if (!$opts{'output'}) {
		$opts{'output'} = 'desc';
		}
	if (($opts{'output'} eq 'desc')or($opts{'output'} eq 'vaf')) {
		} else {
		$opts{'output'} = 'desc';
		}
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

MAIN SNP DESC

=head1 SYNOPSIS

Get descriptors for SNPs for CNV calling
OUTPUT FORMAT:
vaf: .tsv file; one value for one snp. Gene order as in gene_list file 
(you may find it in conf/panel folder)
desc: .tsv file; three value for each genes. Gene order as in gene_list
file (you may find it in conf/panel folder). For each genes printed:
mean vaf value, count of heterozygote SNPs, score for SNP vaf concordance

Options:

    -bam    [REQUIRED] - input .bam file
    -panel  [REQUIRED] - amplicon panel [AODABCV1]
    -output [OPTIONAL] - type of output. Use 'vaf' - to print snp vaf's; 'desc' [DEFAULT] - to print descriptors)

