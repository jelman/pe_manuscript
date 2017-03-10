# -*- coding: utf-8 -*-
"""
Created on 12/8/2015

Create dataset with cognitive and demographics data for 
cortical DTI project.

@author: Jeremy
"""

import pandas as pd
import numpy as np
from sas7bdat import SAS7BDAT
import os


### Load admin dataset ###
admindf = pd.read_csv('/home/jelman/netshare/K/data/VETSA_Demographics/VETSA_demo_vars.csv')

# Create variable to indicate brother has is deceased
deceased = admindf.ix[admindf.deceased2013==1,['vetsaid','case','deceased2013']]
deceased = deceased.merge(admindf[['vetsaid','case']], how='left', on='case')
deceased.ix[deceased.vetsaid_x<>deceased.vetsaid_y, 'DECEASEDSIB'] = 1
deceased = deceased.ix[deceased.DECEASEDSIB==1,['vetsaid_y','DECEASEDSIB']].rename(columns={'vetsaid_y':'vetsaid'})
admindf = admindf.merge(deceased, how='left',on='vetsaid')

# Load BMI data
bmidf = pd.read_csv('/home/jelman/netshare/K/data/VETSA_Demographics/VETSA_base_13Nov16.csv', sep=',')
bmidf = bmidf[['VETSAID','BMI','BMI_v2']].rename(columns={'BMI_v2':'BMI_V2','VETSAID':'vetsaid'})
admindf = admindf.merge(bmidf, how='left', on='vetsaid')

### Load merge files
# VETSA 1
fname = '/home/jelman/netshare/K/data/VETSA1_Aug2014/vetsa1merged_21aug2014.sas7bdat'
with SAS7BDAT(fname) as f:
    dfV1 = f.to_data_frame()
    
# VETSA 2
fname = '/home/jelman/netshare/K/data/VETSA2_April2015/vetsa2merged_1dec2015_edits.sas7bdat'
with SAS7BDAT(fname) as f:
    dfV2 = f.to_data_frame()

         
# Select only variables of interest    
varsV1 = ["vetsaid","TOCC","E6","L3","dep05","DIABYN","BRONYN","EMPHYN",
          "ASTHYN","CANCYN","OARTYN","RARTYN","HATTYN","HRTFYN","HRTSURGY",
          "ANGIYN","HYPTYN","PRVDYN","CIRRYN","AIDSYN","sf36PF","sf36RP",
          "SF36BP","SF36GH","SF36VT","SF36SF","SF36RE","SF36MH"]
varsV2 = ["vetsaid","TOCCV1_v2","E5_v2","E6_v2","CESdep_v2","DIABYN_v2","BRONYN_v2",
          "EMPHYN_v2","ASTHYN_v2","CANCYN_v2","OARTYN_v2","RARTYN_v2",
          "HATTYN_v2","HRTFYN_v2","HRTSURGY_v2","ANGIYN_v2","HYPTYN_v2",
          "PRVDYN_v2","CIRRYN_v2","AIDSYN_v2","SF36PFCEF_v2","SF36RPCEF_v2",
          "SF36BPCEF_v2","SF36VTCEF_v2","SF36SFCEF_v2","SF36RECEF_v2",
          "SF36MHCEF_v2","SF36GHCEF_v2"]


dfV1 = dfV1[varsV1]
dfV2 = dfV2[varsV2]
 
    
# Rename variables for ethinicity, racial category, and education
dfV1 = dfV1.rename(columns={'E6':'SUBJINCOME',
                            'L3':'TOTINCOME',
                            'dep05':'DEP_V1'})
                              
dfV2 = dfV2.rename(columns={'TOCCV1_v2':'TOCC_V2',
                            'E5_v2':'SUBJINCOME_V2',
                            'E6_v2':'TOTINCOME_V2',
                            'CESdep_v2':'DEP_V2',
                            'SF36PFCEF_v2':'SF36PF_V2',
                            'SF36RPCEF_v2':'SF36RP_V2',
                            'SF36BPCEF_v2':'SF36BP_V2',
                            'SF36GHCEF_v2':'SF36GH_V2',
                            'SF36VTCEF_v2':'SF36VT_V2',
                            'SF36SFCEF_v2':'SF36SF_V2',
                            'SF36RECEF_v2':'SF36RE_V2',
                            'SF36MHCEF_v2':'SF36MH_V2'})


#Replace missing data values with NA
naVarsV1 = ["DIABYN","BRONYN","EMPHYN","ASTHYN","CANCYN","OARTYN","RARTYN",
           "HATTYN","HRTFYN","HRTSURGY","ANGIYN","HYPTYN","PRVDYN",
           "CIRRYN","AIDSYN"]
naVarsV2 = ["DIABYN_v2","BRONYN_v2","EMPHYN_v2","ASTHYN_v2","CANCYN_v2",
           "OARTYN_v2","RARTYN_v2","HATTYN_v2","HRTFYN_v2","HRTSURGY_v2",
           "ANGIYN_v2","HYPTYN_v2","PRVDYN_v2","CIRRYN_v2",
           "AIDSYN_v2"]
dfV1.ix[:,naVarsV1] = dfV1.ix[:,naVarsV1].replace([8,9,99], np.nan)
dfV2.ix[:,naVarsV2] = dfV2.ix[:,naVarsV2].replace([8,9,99], np.nan)


# Merge datasets
alldf = admindf.merge(dfV1, how='left', on='vetsaid')
alldf = alldf.merge(dfV2, how='left', on='vetsaid')

# Update TOCC_V2 field for longitudinal returnees
alldf = alldf.set_index('vetsaid')
alldf['TOCC_V2'] = alldf['TOCC_V2'].combine_first(alldf['TOCC'])
v1idx = (alldf.VETSAGRP<>"V1V2") & (alldf.VETSAGRP<>"V2AR")
alldf.ix[v1idx, 'TOCC_V2'] = np.nan
alldf = alldf.reset_index()

alldf.deceased2013 = alldf.deceased2013.fillna(0)
alldf.DECEASEDSIB = alldf.DECEASEDSIB.fillna(0)

# Save out file
outfile = '/home/jelman/netshare/K/Projects/PracticeEffects/data/GEE/AttritionData.csv'
alldf.to_csv(outfile, index=False)
