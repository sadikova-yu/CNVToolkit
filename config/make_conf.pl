use strict;
use warnings;
use threads;
use Thread::Queue;

my $current_dir = '/home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODCNV/';
my $panel = "AODABCV1"; # make sure that corresponding folder exists
my $path_to_bam_list = "/home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODTKAbatch/conf_data/AODABCV1_testkit_ILLMN/list_bam";
my $path_to_AODBETA  = "/home/onco-admin//RnD/UEBAcall/";
my $path_to_panel_bed = "/home/onco-admin/ATLAS_software/aod-pipe/panel_info/$panel/$panel.designed.bed";
my @genes = qw(ATM BRCA1 BRCA2); # make sure that panel folder contains corresponding .vcf files

my %work;
foreach my $arg (@genes) {
	$work{$arg} = Thread::Queue->new;
	}
my $active_gene;
sub worker {
	while ( my $passed = $work{$active_gene}->dequeue ) {
		my $bam = $passed->[0];
		my $gene = $passed->[1];
		my $panel = $passed->[2];
		my $sample = $passed->[3];
		print STDERR "STARTED SAMPLE $sample\n";
		`perl $path_to_AODBETA/get_counts_for_sample.pl -s $bam -v ./$panel/$gene.vcf -p /home/onco-admin/ATLAS_software/aod-pipe/panel_info/$panel/$panel.designed.bed -n 10 -o ./$panel/tmp_$gene/$sample.cdata`;
		}
	}

`rm ./$panel/bdata`;

foreach my $gene (@genes) {
	goto YU;
	`rm -r ./$panel/tmp_$gene`;
	`mkdir ./$panel/tmp_$gene`;
	$active_gene = $gene;
	print "ACTIVE GENE - $active_gene\n";

	open (READ, "<$path_to_bam_list");
	threads->create( \&worker ) for 1 .. (15);

	while (<READ>) {
		chomp;
		my @mas = split/\t/;
		my $bam = $mas[1];
		my $sample = $mas[0];
		$work{$gene}->enqueue( [$bam, $gene, $panel, $sample] );
		}
	close READ;

	$work{$gene}->end;
	$_->join for threads->list;
	
	YU:
	open (READ, "<$path_to_bam_list");
	
	`rm -r ./$panel/tmp1233`;
	`mkdir ./$panel/tmp1233`;
	my %dict;
	while (<READ>) {
		chomp;
		my @mas = split/\t/;
		my $sample = $mas[0];
		open (CDATA, "<./$panel/tmp_$gene/$sample.cdata");
		while (<CDATA>) {
			chomp;
			my @mas = split/\t/;
			my $name = $mas[0]."@".$mas[1]."@".$mas[2];
			$dict{$name} = 1;
			my $ad = $mas[3];
			my $dp = $mas[4];
			next if $dp eq 0;
			next if ($ad/$dp) > 0.1;
			my $weight = log($mas[3] + 2.7183)*log($mas[4] + 2.7183)*log($mas[4] + 2.7183);
			my $cmd = "echo \"$ad\t$dp\t$weight\" >> './$panel/tmp1233/$name'";
			`$cmd`;
			}
		close CDATA;
		}
	
	close READ;
	foreach my $name (keys %dict) {
		`R --slave -f $path_to_AODBETA/YU_beta_error_approx.R --args $path_to_AODBETA/fitdistr/ '$current_dir/config/$panel/tmp1233/$name' 1 > temp_data`;
		my $data = `tail -n1 temp_data`;
		chomp $data;
		`rm temp_data`;
		my @mas = split/\t/, $data;
		my $bdata_string = "$name\t".join("\t", @mas);
		$bdata_string =~ s/ //g;
		`echo "$bdata_string" >> ./$panel/bdata`;
		}
	#`rm -r ./$panel/tmp1233`;
	}



















