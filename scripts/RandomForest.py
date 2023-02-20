#!/usr/bin/env python3
# Wrapper script to process the whole pipeline

import sys
from pathlib import Path
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, accuracy_score, roc_curve, plot_confusion_matrix, confusion_matrix, ConfusionMatrixDisplay
import matplotlib.pyplot as plt
import joblib
from ML_func import accuracy_f

### Initiate
(set, out) = sys.argv[1:3]
#lable_name can be either 'QC', 'BRCA1', 'BRCA2'
Path(out).mkdir(exist_ok = True)
mode='apply'
if len(sys.argv) >3:
	(mode) = sys.argv[3]


ds=pd.read_csv(set, sep = '\t')

vrbls=['ATM_VAF', 'ATM_number', 'ATM_concord', 'BRCA1_VAF', 'BRCA1_number', 'BRCA1_concord', 'BRCA2_VAF', 'BRCA2_number', 'BRCA2_concord', 'E', 'MAPD', 'C', 'E1', 'MPD1', 'C1', 'E2', 'MPD2', 'C2', 'ATM_pool1_cverage', 'ATM_pool2_cverage', 'BRCA1_pool1_cverage', 'BRCA1_pool2_cverage', 'BRCA2_pool1_cverage', 'BRCA2_pool2_cverage']

for lable_name in ['QC', 'BRCA1', 'BRCA2']:
	### Add Predictions to source dataset
	model = joblib.load('%sRFmodel_%s.joblib' %('/home/onco-admin/RnD/Yakushina/CNV/',lable_name))
	vals = ds[vrbls]
	if lable_name != 'QC':
		#ds = ds[ds['QC']=='POS']
		vals = vals[ds['Predicted_QC']=='POS']
	lbls_pred=model.predict(vals)
	lbls_probs = model.predict_proba(vals)[:, 1]
	set_prediction=ds.iloc[list(vals.index)]
	col_name='Predicted_'+lable_name
	set_prediction.loc[:,col_name]=list(lbls_pred)
	set_prediction_final=set_prediction
	ds=ds.merge(set_prediction_final[col_name], how='left', left_index=True, right_index=True)
	if lable_name in ['BRCA1', 'BRCA2']:
		roc=pd.DataFrame({'sample_ID':ds.iloc[list(vals.index)]['sample_ID'], 'lbls_pred':lbls_pred, 'lbls_probs':lbls_probs})
		roc.to_csv('%s/ROC_%s.tsv' % (out, lable_name), sep='\t', index=False)
	### Accuracy assesment
	if mode == 'validate':
		lables=ds[lable_name]
		accuracy_f(lables, lbls_pred, lbls_probs, out, lable_name, model)

### Write results
ds.to_csv('%s_RFresult.tsv' % set.strip('.tsv'), sep='\t', index=False)