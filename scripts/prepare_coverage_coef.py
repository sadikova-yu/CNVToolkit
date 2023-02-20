#!/usr/bin/env python3

import sys
from subprocess import run, PIPE
import numpy as np

with open('/home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODCNV/config/AODABCV1/cov_average_coef.csv', 'w') as outf:
	outf.write('### median normalized coverage (count/total counts) per loci over all sample (script for calculation here)\n')

sample_list=[]
with open('/home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODCNV/test/list_illmn', 'r') as outf:
	for line in outf:
		line=line.strip()
		sample_list.append(line.split('\t')[1])

for p in ['pool_1', 'pool_2']:
	cov_dict_all={}
	for sample in sample_list:
		cov=run('samtools depth %s -b /home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODCNV/config/AODABCV1/AODABCV1.designed.%s.grep.bed' % (sample, p), shell = True, stdout=PIPE).stdout.strip().decode().strip().split('\n')
		cov_dict={}
		for i in cov:
			cov_dict[':'.join(i.split('\t')[0:2])]=int(i.split('\t')[2])
		cov_normalise_total_counts={}
		for (name, val) in cov_dict.items():
			cov_normalise_total_counts[name]=100*(val/sum(cov_dict.values()))
		for (name, val) in cov_normalise_total_counts.items():
			if  name not in cov_dict_all.keys():
				cov_dict_all[name]=[val]
			else:
				cov_dict_all[name].append(val)
	cov_coef={}
	for (name, val) in cov_dict_all.items(): 
		cov_coef[name]=np.median(val)
	with open('/home/onco-admin/ATLAS_software/aod-pipe/Pipe/AODCNV/config/AODABCV1/cov_average_coef.csv', 'a') as outf:
		for (k, val) in cov_coef.items():
			outf.write(k+'\t'+str(val)+'\n')
