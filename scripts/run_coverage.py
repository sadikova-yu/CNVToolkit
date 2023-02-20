#!/usr/bin/env python3

from subprocess import run, PIPE
from pathlib import Path
import multiprocessing as mp
import re

## Initiate

with open('/home/onco-admin/RnD/Yakushina/CNV/coverage_Ion.tsv', 'w') as res_f:
	res_f.write('\t'.join(['sample_ID', 'ATM_pool1', 'ATM_pool2', 'BRCA1_pool1', 'BRCA1_pool2', 'BRCA2_pool1', 'BRCA2_pool2'])+'\n')

samples_info={}
with open('/home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODCNV/test/list_it', 'r') as in_f:
	for line in in_f:
		line=line.strip()
		samples_info[line.split('\t')[0]]={}
		samples_info[line.split('\t')[0]]['bam']=line.split('\t')[1]

def coverage(sample):
	bam=samples_info[sample]['bam']
	result = run('/home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODCNV/scripts/coverage.py %s AODABCV1' % bam, shell=True, stdout=PIPE).stdout.decode().strip()
	genes=result.split('\n')
	genes_dict={g.split(' ')[0]:re.findall("\d+\.\d+", g) for g in genes}
	with open('/home/onco-admin/RnD/Yakushina/CNV/coverage_Ion.tsv', 'a') as res_f:
		res_f.write(sample+'\t'+'\t'.join(genes_dict['ATM'])+'\t'+'\t'.join(genes_dict['BRCA1'])+'\t'+'\t'.join(genes_dict['BRCA2'])+'\n')

pool = mp.Pool(2)
pool.map(coverage, [str(sample) for sample in samples_info.keys()])
pool.close()

