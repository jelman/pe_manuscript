#################################################################################
# Script to create datasets for practice effect analyses using GEE.             #
# This script will create two datasets, one on raw score scale and one          #
# standardized (z-scored) using VETSA 1 means and SDs                           #
#################################################################################

# Import libraries
library(dplyr)

# Load raw test scores and demographics data
allData = read.csv("~/netshare/K/Projects/PracticeEffects/data/raw/V1V2_CogData_Raw.csv",
                   stringsAsFactors = FALSE)

# Convert all variable names to upper case
names(allData) = toupper(names(allData))

### Log transform timing data ###

# Get names of variables to transform
timeVarsV1 = c("TRL1T","TRL2T","TRL3T","TRL4T","TRL5T","SRTLMEAN","SRTLSTD","SRTRMEAN",
                "SRTRSTD","SRTGMEAN","SRTGSTD","CHRTLMEAN","CHRTRMEAN","CHRTLSTD",
                "CHRTRSTD","CHRTGMEAN","CHRTGSTD")
timeVarsLogV1 = paste0(timeVarsV1, "LOG")
timeVarsV2 = paste0(timeVarsV1, "_V2")
timeVarsLogV2 = paste0(timeVarsLogV1, "_V2")

# Transform
allData[timeVarsLogV1] = log(allData[timeVarsV1])                
allData = dplyr::select(allData, -one_of(timeVarsV1))
allData[timeVarsLogV2] = log(allData[timeVarsV2])                
allData = dplyr::select(allData, -one_of(timeVarsV2))

## Adjust variables for processing speed ##

# Stroop interference
lmStroop = lm(STRCWRAW ~ STRWRAW + STRCRAW, data=allData, na.action=na.exclude)
allData[["STRCWADJ"]] = residuals(lmStroop) + coef(lmStroop)[[1]]
lmStroop_V2 = lm(STRCWRAW_V2 ~ STRWRAW_V2 + STRCRAW_V2, data=allData, na.action=na.exclude)
allData[["STRCWADJ_V2"]] = residuals(lmStroop_V2) + coef(lmStroop_V2)[[1]]

# Category Switching
lmCatSwitch = lm(CSSACC ~ CFCOR, data=allData, na.action=na.exclude)
allData[["CSSACCADJ"]] = residuals(lmCatSwitch) + coef(lmCatSwitch)[[1]]
lmCatSwitch_V2 = lm(CSSACC_V2 ~ CFCOR_V2, data=allData, na.action=na.exclude)
allData[["CSSACCADJ_V2"]] = residuals(lmCatSwitch_V2) + coef(lmCatSwitch_V2)[[1]]

# Trails Switching
lmTrails = lm(TRL4TLOG ~ TRL2TLOG + TRL3TLOG, data=allData, na.action=na.exclude)
allData[["TRL4TLOGADJ"]] = residuals(lmTrails) + coef(lmTrails)[[1]]
lmTrails_V2 = lm(TRL4TLOG_V2 ~ TRL2TLOG_V2 + TRL3TLOG_V2, data=allData, na.action=na.exclude)
allData[["TRL4TLOGADJ_V2"]] = residuals(lmTrails_V2) + coef(lmTrails_V2)[[1]]

# Create list of raw variable names to adjust
rawVarsV1 = c("MR1COR","TRL1TLOG","TRL2TLOG","TRL3TLOG","TRL4TLOG","TRL4TLOGADJ","TRL5TLOG","CSSACC","CSSACCADJ","MTXRAW","CVA1RAW","CVATOT","CVSDFR","CVLDFR",
              "AFQTPCT","AFQTVOCPCT","AFQTARPCT","AFQTTLPCT","AFQTBXPCT","AFQTPCTTRAN","AFQTVOCPCTTRAN","AFQTARPCTTRAN","AFQTTLPCTTRAN",
              "AFQTBXPCTTRAN","DSFRAW","DSBRAW","DSFMAX","SSPFRAW","SSPBRAW","LNTOT","LMITOT","LMDTOT","VRITOT","VRDTOT","VRCTOT","HFTOTCOR",
              "STRWRAW","STRCRAW","STRCWRAW","STRCWADJ","LFFCOR","LFACOR","LFSCOR","LFCOR","CFANCOR","CFBNCOR","CFCOR","CSCOR","SRTLMEANLOG",
              "SRTLSTDLOG","SRTRMEANLOG","SRTRSTDLOG","SRTGMEANLOG","SRTGSTDLOG","CHRTLMEANLOG","CHRTRMEANLOG","CHRTLSTDLOG",
              "CHRTRSTDLOG","CHRTGMEANLOG","CHRTGSTDLOG","RSATOT","AXHITRATE","AXFARATE","AXMISSRATE","BXHITRATE","BXFARATE",
              "BXMISSRATE","CPTDPRIME")
rawVarsV2 = paste0(rawVarsV1, "_V2")

# Print variable names and verify these are correct
rawVarsV1
rawVarsV2



#----------------------------------------------------------------------------#
#                     Define functions                                       #
#----------------------------------------------------------------------------#

addScaleVals = function(df,varname, x) {
  ###########################################################
  # Save mean and SD of all variables into a dataframe      #
  # Input:                                                  #
  # df = Initialized dataframe to hold results              #
  # varname = String name of variable                       #
  # x = Scaled vector of data                               #
  ###########################################################
  meanVal = attr(x, which="scaled:center")
  sdVal = attr(x, which="scaled:scale")
  rbind(df, data.frame(Variable=varname, Mean=meanVal, SD=sdVal))
}


##########################################
### Begin creating unadjusted datasets ###
##########################################

#-----------------------------------------------------------------------------------#
# Create unadjusted dataset on raw score scale                                      #
#-----------------------------------------------------------------------------------#

### Save out unadjusted scores on raw score scale ###
write.csv(allData, 
          "~/netshare/K/Projects/PracticeEffects/data/GEE/V1V2_CogData_Unadj.csv",
          row.names = FALSE)


#-----------------------------------------------------------------------------------#
# Standardize (z-scored) based on VETSA 2 means and sd.                             #
#-----------------------------------------------------------------------------------#

# Initialize dataframe to hold means and SDs
scaleValues = data.frame()

allDataZscores = allData

# Scale VETSA 1 variables 
# Adds mean and SD to dataframe and deletes adjusted raw variables from dataset
for(i in rawVarsV1){
  varname = i
  zvarname = paste(i, "z", sep="_")
  allDataZscores[[zvarname]] = scale(allDataZscores[[varname]])
  scaleValues = addScaleVals(scaleValues, varname, allDataZscores[[zvarname]])
  allDataZscores[[varname]] = NULL
}

# Scale VETSA 2 variables using VETSA 1 mean and SD
# Delete adjusted raw variable from dataset
for(i in rawVarsV2){
  varnameV2 = i
  zvarname = paste(i, "z", sep="_")
  varnameV1 = gsub("_V2","",varnameV2)
  allDataZscores[[zvarname]] = scale(allDataZscores[[varnameV2]],
                                        center=scaleValues$Mean[scaleValues$Variable==varnameV1],
                                        scale=scaleValues$SD[scaleValues$Variable==varnameV1])
  allDataZscores[[varnameV2]] = NULL
}

# Save out unadjusted and z-scored dataset
write.csv(allDataZscores, 
          "~/netshare/K/Projects/PracticeEffects/data/GEE/V1V2_CogData_Unadj_Z.csv",
          row.names = FALSE)

# Save out means and standard deviations used to standardize scores
write.csv(scaleValues, "~/netshare/K/Projects/PracticeEffects/data/GEE/V1_Unadj_Means_SDs.csv",
          row.names = FALSE)
