# The module contains usefull functions for the pipeline

from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, accuracy_score, roc_curve, plot_confusion_matrix, confusion_matrix, ConfusionMatrixDisplay
import pandas as pd
import matplotlib.pyplot as plt
import joblib

def accuracy_f(lables_test, lables_pred, lables_probs, out_folder, var_tp, md):
  accuracy=round(accuracy_score(list(lables_test), lables_pred), 4)
  roc_value = round(roc_auc_score(lables_test, lables_probs), 4)
  TP=len(lables_pred[(lables_pred==lables_test) & (lables_pred=='POS')])
  TN=len(lables_pred[(lables_pred==lables_test) & (lables_pred=='NEG')])
  FN=len(lables_pred[(lables_pred!=lables_test) & (lables_pred=='POS')])
  FP=len(lables_pred[(lables_pred!=lables_test) & (lables_pred=='NEG')])
  TPR=round(TP/(TP + FN), 4)*100
  TNR=round(TN/(TN + FP), 4)*100
  PPV=round(TP/(TP + FP), 4)*100
  NPV=round(TN/(TN + FN), 4)*100
  acc=pd.DataFrame({'accuracy':[accuracy], 'AUC':[roc_value], 'TPR':[TPR], 'TNR':[TNR], 'PPV':[PPV], 'NPV':[NPV]})
  acc.to_csv('%s/accuracy_%s.tsv' % (out_folder, var_tp), sep='\t')
  acc.to_csv('%s/accuracy_%s.tsv' % (out_folder, var_tp), sep='\t', index=False)
  cm = confusion_matrix(lables_test, lables_pred, labels=md.classes_) # Confusion_matrix
  disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=md.classes_)
  disp.plot()
  plt.savefig('%s/confusion_matrix_%s.png' %(out_folder, var_tp)) 
  plt.close()
  #Plot ROC curve
  fpr, tpr, thresholds = roc_curve(lables_test, lables_probs, pos_label='POS')
  plt.figure()
  plt.plot(fpr, tpr, color="darkred", lw=1.5, label="ROC curve (area = %0.3f)" % roc_value)
  plt.plot([0, 1], [0, 1], color="darkgreen", lw=1.5, linestyle="--")
  plt.xlim([-0.05, 1.05])
  plt.ylim([-0.05, 1.05])
  plt.xlabel("False Positive Rate")
  plt.ylabel("True Positive Rate")
  plt.title("Receiver operating characteristic example")
  plt.legend(loc="lower right")
  plt.savefig('%s/ROC_%s.png' %(out_folder, var_tp)) 
  plt.close()