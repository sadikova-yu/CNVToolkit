#!/usr/bin/env python3

import sys
from subprocess import run, PIPE
import numpy as np
import os
config_dir = os.path.dirname(os.path.realpath(__file__)) + '/../config/'

## Initiate
bam = sys.argv[1]
panel = sys.argv[2]

genes={}
genes_coverage={}
result={}
with open(f"{config_dir}/{panel}/gene_list.bed") as panel_bed_f:
    for line in panel_bed_f:
        line=line.strip()
        (chrom, start, stop, gene) = line.split('\t')[0:4]
        genes[gene] = {'chr':chrom, 'start':int(start), 'stop':int(stop)}
        genes_coverage[gene] = {'pool_1':[], 'pool_2':[]}
        result[gene] = []


#genes={'ATM':{'chr':'chr11', 'start':108098366, 'stop':108236254}, 'BRCA1':{'chr':'chr17', 'start':41196312, 'stop':41277500}, 'BRCA2':{'chr':'chr13', 'start':32890575, 'stop':32972891}}
#genes_coverage={'ATM':{'pool_1':[], 'pool_2':[]}, 'BRCA1':{'pool_1':[], 'pool_2':[]}, 'BRCA2':{'pool_1':[], 'pool_2':[]}}
#result={'ATM':[], 'BRCA1':[], 'BRCA2':[]}

### Read from file with coefficients (median coverage per loci over all sample):
coef=open(f"{config_dir}/{panel}/cov_average_coef.csv", 'r').read().strip().split('\n')[1:]
coefdict={}
for item in coef:
	coefdict[item.split('\t')[0]]=float(item.split('\t')[1])

### calc cov

def calc_cov(bam,p):
	cov=run(f"samtools depth %s -b {config_dir}/{panel}/{panel}.designed.%s.grep.bed" % (bam, p), shell = True, stdout=PIPE).stdout.strip().decode().split('\n')
	cov_dict={}
	for i in cov:
		cov_dict[':'.join(i.split('\t')[0:2])]=int(i.split('\t')[2])	
	cov_normalise={}
	for (name, val) in cov_dict.items():
		cov_normalise[name]=100*(val/sum(cov_dict.values()))/coefdict[name]
	for gene in genes.keys():
		for (name, v) in cov_normalise.items():
			if genes[gene]['chr'] in name and int(name.split(':')[1]) in range(genes[gene]['start'],genes[gene]['stop']+1):
				genes_coverage[gene][p].append(v)
		result[gene].append(np.mean(genes_coverage[gene][p]))
	
for p in ['pool_1', 'pool_2']:
	calc_cov(bam,p)

for (gene, value) in result.items():
	print(gene, value)
