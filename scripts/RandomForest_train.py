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

ds_start=pd.read_csv(set, sep = '\t')

vrbls=['ATM_VAF', 'ATM_number', 'ATM_concord', 'BRCA1_VAF', 'BRCA1_number', 'BRCA1_concord', 'BRCA2_VAF', 'BRCA2_number', 'BRCA2_concord', 'E', 'MAPD', 'C', 'E1', 'MPD1', 'C1', 'E2', 'MPD2', 'C2', 'ATM_pool1_cverage', 'ATM_pool2_cverage', 'BRCA1_pool1_cverage', 'BRCA1_pool2_cverage', 'BRCA2_pool1_cverage', 'BRCA2_pool2_cverage']

### Split dataset into training set (70%) and test set (30%)
train, test = train_test_split(ds_start, test_size=0.3)

for lable_name in ['QC', 'BRCA1', 'BRCA2']:
	print(lable_name)
	if lable_name != 'QC':
		ds_start_train=ds_start.iloc[list(train.index)]
		train=train[ds_start_train['QC']=='POS']
		ds_start_test=ds_start.iloc[list(test.index)]
		test=test[ds_start_test['QC']=='POS']
	(vals_train, vals_test, lbls_train, lbls_test)=[train[vrbls], test[vrbls], train[lable_name], test[lable_name]]# Features
	### Define N trees and features
	ntrees_acc={}
	for ntrs in range(100, 550, 50):
		model=RandomForestClassifier(n_estimators=ntrs, bootstrap = True, max_features = 'sqrt')
		model.fit(vals_train,lbls_train)
		lbls_pred=model.predict(vals_test)
		ntrees_acc[ntrs]=accuracy_score(lbls_test, lbls_pred)
	plt.plot(list(ntrees_acc.keys()), [round(100 * i, 3) for i in ntrees_acc.values()], color="black", lw=1.5)
	plt.ylabel("Accuracy")
	plt.xlabel("Number of trees")
	plt.title("Numer of features = 'sqrt'")
	plt.margins(y=0.5)
	plt.savefig('%s/Number_of_trees_%s.png' %(out, lable_name))
	plt.close()
	ntrs=300
	mtry_acc={}
	for mtrs in range(3, 8):
		model=RandomForestClassifier(n_estimators=ntrs, bootstrap = True, max_features = mtrs)
		model.fit(vals_train,lbls_train)
		lbls_pred=model.predict(vals_test)
		mtry_acc[mtrs]=accuracy_score(lbls_test, lbls_pred)
	plt.plot(
		list(mtry_acc.keys()),
		[round(100 * i, 3) for i in mtry_acc.values()],
		color="black",
		lw=1.5)
	plt.ylabel("Accuracy")
	plt.xlabel("Number of features")
	plt.title("Numer of trees = %s" % (ntrs))
	plt.margins(y=0.5)
	plt.savefig('%s/Number_of_features_%s.png' %(out, lable_name)) 
	plt.close()
	### Train a Model, Save
	(ntrs, mtrs)= [300, 5]
	model=RandomForestClassifier(n_estimators=ntrs, bootstrap = True, max_features = mtrs)
	model.fit(vals_train,lbls_train)
	joblib.dump(model, '/home/onco-admin/RnD/Yakushina/CNV/RFmodel_%s.joblib' %lable_name) #Save model
	### Add Predictions to source dataset
	lbls_pred=model.predict(vals_train)
	set_prediction=ds_start.iloc[list(vals_train.index)]
	col_name='Predicted_'+lable_name
	set_prediction.loc[:,col_name]=list(lbls_pred)
	### Accuracy assesment
	lbls_pred = model.predict(vals_test) #Classification on test sample
	lbls_probs = model.predict_proba(vals_test)[:, 1] # Probabilies for each clas
	accuracy_f(lbls_test, lbls_pred, lbls_probs, out, lable_name, model)
	#fi = pd.DataFrame({'feature': vrbls,
	#	'importance': model.feature_importances_}).\
	#	sort_values('importance', ascending = False)
	#fi.to_csv('%s/feature_importance_%s.tsv' %(out, lable_name), sep='\t', index=False)
	set_prediction_test=ds_start.iloc[list(vals_test.index)]
	set_prediction_test.loc[:,col_name]=list(lbls_pred)
	set_prediction_final=pd.concat([set_prediction, set_prediction_test], axis=0)
	ds_start.loc[list(vals_train.index),'set']='TRAIN'
	ds_start.loc[list(vals_test.index),'set']='TEST'
	ds_start=ds_start.merge(set_prediction_final[col_name], how='left', left_index=True, right_index=True)

### Write results
ds_start.to_csv('%s_result.tsv' % set, sep='\t', index=False)