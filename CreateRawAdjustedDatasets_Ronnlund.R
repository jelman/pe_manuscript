#################################################################################
# Script to create datasets for practice effect analyses.                       #
# This script will create four datasets:                                        #
#   - Cognitive data with nas201tran (age 20 AFQT) regressed out. Scores are    #
#     not standardized.                                                         #
#   - Cognitive data with above adjustment for nas201tran. Scores are           # 
#     standardized (z-scored)                                                   #
#     based on VETSA1 means and sd.                                             #
#   - Cognitive data with TEDALL (Education) regressed out. Scores are not      # 
#     standardized.                                                             #
#   - Cognitive data with above adjustment for TEDALL. Scores are standardized  #
#     (z-scored) based on VETSA1 means and sd.                                  #
#                                                                               #
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
lmStroop = lm(STRCWRAW ~ scale(STRWRAW, center=T, scale=F) + scale(STRCRAW, center=T, scale=F), data=allData, na.action=na.exclude)
allData[["STRCWADJ"]] = residuals(lmStroop) + coef(lmStroop)[[1]]
lmStroop_V2 = lm(STRCWRAW_V2 ~ scale(STRWRAW_V2, center=T, scale=F) + scale(STRCRAW_V2, center=T, scale=F), data=allData, na.action=na.exclude)
allData[["STRCWADJ_V2"]] = residuals(lmStroop_V2) + coef(lmStroop_V2)[[1]]

# Category Switching
lmCatSwitch = lm(CSSACC ~ scale(CFCOR, center=T, scale=F), data=allData, na.action=na.exclude)
allData[["CSSACCADJ"]] = residuals(lmCatSwitch) + coef(lmCatSwitch)[[1]]
lmCatSwitch_V2 = lm(CSSACC_V2 ~ scale(CFCOR_V2, center=T, scale=F), data=allData, na.action=na.exclude)
allData[["CSSACCADJ_V2"]] = residuals(lmCatSwitch_V2) + coef(lmCatSwitch_V2)[[1]]

# Trails Switching
lmTrails = lm(TRL4TLOG ~ scale(TRL2TLOG, center=T, scale=F) + scale(TRL3TLOG, center=T, scale=F), data=allData, na.action=na.exclude)
allData[["TRL4TLOGADJ"]] = residuals(lmTrails) + coef(lmTrails)[[1]]
lmTrails_V2 = lm(TRL4TLOG_V2 ~ scale(TRL2TLOG_V2, center=T, scale=F) + scale(TRL3TLOG_V2, center=T, scale=F), data=allData, na.action=na.exclude)
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

adjustDataset = function(regVars,adjVars,nDemoVars=7,suffix="adj",data){
  #######################################################################
  # Adjust dataset for specified set of variables.Regresses passed      #
  # variables from each measure using linear regression. The intercept  #
  # is added back in to retain mean level information.                  #
  # Input:                                                              #
  # regVars = List of variables to regress out                          #
  # adjVars = List of variables to be adjusted                          #
  # nDemoVars = Number of demographic variables included in dataframe.  #
  #             These should be the first 1:nDemoVars columns of        #
  #             the dataframe                                           #
  #######################################################################
  
  # Read variable names from data and store in a vector
  allNames <- names(data)
  
  #*** Check variables are correct
  nVars <- length(adjVars)	
  
  ### Creating Storate Data Frame ###
  
  # Set number of individuals 
  n <- dim(data)[1]
  tot <- dim(data)[2]
  
  # Create Data Frame
  data <- cbind(data,matrix(NA,nrow=n,ncol=nVars))
  names(data) <- c(allNames,paste(adjVars,suffix,sep="_"))
  
  ### Running Loop Using lapply ###
  
  # fitting models
  models <- lapply(adjVars, function(x) {
    fmla = as.formula(paste0(x," ~ ",regVars))
    lm(formula=fmla, data = data, na.action=na.exclude)
  })
  
  # storing residuals from each model into data frame
  for(v in 1:nVars){
    data[,tot+v] <- residuals(models[[v]]) + coef(models[[v]])[[1]]
  }
  
  #dataR is now your residualized parameters
  dataR <- data[,c(1:nDemoVars,(tot+1):(tot+nVars))]
  dataR
}


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
#                                                                                   #
# Intercept is added back in to avoid mean centering.                               #
#-----------------------------------------------------------------------------------#

### Save out unadjusted scores on raw score scale ###
write.csv(allData, 
          "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1V2_CogData_Unadj.csv",
          row.names = FALSE)


#-----------------------------------------------------------------------------------#
# Create dataset adjusted for nas201tran (Age 20 AFQT) and standardized.            #
#                                                                                   #
# Dataset with NAS201TRAN (age 20 AFQT) regressed out is standardized (z-scored)    #
# based on VETSA 2 means and sd.                                                    #
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
          "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1V2_CogData_Unadj_Z.csv",
          row.names = FALSE)

# Save out means and standard deviations used to standardize scores
write.csv(scaleValues, "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1_Unadj_Means_SDs.csv",
          row.names = FALSE)

########################################
### Begin creating adjusted datasets ###
########################################

#-----------------------------------------------------------------------------------#
# Create dataset adjusted for nas201tran (Age 20 AFQT)                              #
#                                                                                   #
# Adjustment consists of regressing out nuisance variable from raw variables.       # 
# Intercept is added back in to avoid mean centering.                               #
#-----------------------------------------------------------------------------------#

# Adjust raw scores from VETSA 1 and VETSA 2
adjVars = c(rawVarsV1, rawVarsV2)

### Set number of demographic variables included in dataframe (these won't be adjusted) ###
nDemoVars = 7

# Filter out subjects missing variable to be regressed out
data = subset(allData, !is.na(allData$NAS201TRAN))

# Specify nas201tran (Age 20 AFQT as variable to regress out)
regVars = paste("scale(NAS201TRAN)", sep=" + ")

# Regress nas201tran out of dataset
nasAdjRawScoresData = adjustDataset(regVars, adjVars, nDemoVars, "nas", data)

# Save out dataset with Age 20 AFQT regressed out
write.csv(nasAdjRawScoresData, "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1V2_CogData_NASAdj.csv",
          row.names=F)

#-----------------------------------------------------------------------------------#
# Create dataset adjusted for nas201tran (Age 20 AFQT) and standardized.            #
#                                                                                   #
# Dataset with NAS201TRAN (age 20 AFQT) regressed out is standardized (z-scored)    #
# based on VETSA 2 means and sd.                                                    #
#-----------------------------------------------------------------------------------#

# Initialize dataframe to hold means and SDs
scaleValues = data.frame()

nasAdjZscoresData = nasAdjRawScoresData

# Scale VETSA 1 variables that have been adjusted for nas201tran
# Adds mean and SD to dataframe and deletes adjusted raw variables from dataset
for(i in rawVarsV1){
  varname = paste0(i, "_nas")
  zvarname = gsub("_nas","_znas",varname)
  nasAdjZscoresData[[zvarname]] = scale(nasAdjZscoresData[[varname]])
  scaleValues = addScaleVals(scaleValues, varname, nasAdjZscoresData[[zvarname]])
  nasAdjZscoresData[[varname]] = NULL
}

# Scale VETSA 2 variables that have been adjusted for nas201tran using VETSA 1 mean and SD
# Delete adjusted raw variable from dataset
for(i in rawVarsV2){
  varnameV2 = paste0(i, "_nas")
  zvarname = gsub("_nas","_znas",varnameV2)
  varnameV1 = gsub("_V2","",varnameV2)
  nasAdjZscoresData[[zvarname]] = scale(nasAdjZscoresData[[varnameV2]],
                                          center=scaleValues$Mean[scaleValues$Variable==varnameV1],
                                          scale=scaleValues$SD[scaleValues$Variable==varnameV1])
  nasAdjZscoresData[[varnameV2]] = NULL
}

# Save out adjusted and z-scored dataset
write.csv(nasAdjZscoresData, 
          "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1V2_CogData_NASAdj_Z.csv",
          row.names = FALSE)

# Save out means and standard deviations used to standardize scores
write.csv(scaleValues, "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1_NASAdj_Means_SDs.csv",
          row.names = FALSE)


#-----------------------------------------------------------------------------------#
# Create dataset adjusted for TEDALL (Education)                                    #
#                                                                                   #
# Adjustment consists of regressing out nuisance variable from raw variables.       # 
# Intercept is added back in to avoid mean centering.                               #
#-----------------------------------------------------------------------------------#

# Adjust raw scores from VETSA 1 and VETSA 2
adjVars = c(rawVarsV1, rawVarsV2)

### Set number of demographic variables included in dataframe (these won't be adjusted) ###
nDemoVars = 7

# Filter out subjects missing variable to be regressed out
data = subset(allData, !is.na(allData$TEDALL))

# Specify nas201tran (Age 20 AFQT as variable to regress out)
regVars = paste("scale(TEDALL)", sep=" + ")

# Regress nas201tran out of dataset
tedAdjRawScoresData = adjustDataset(regVars, adjVars, nDemoVars, "ted", data)

# Save out dataset with Education regressed out
write.csv(tedAdjRawScoresData, "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1V2_CogData_TEDALLAdj.csv",
          row.names=F)

#-----------------------------------------------------------------------------------#
# Create dataset adjusted for TEDALL (Education) and standardized.                  #
#                                                                                   #
# Dataset with TEDALL (Education) regressed out is standardized (z-scored)          #
# based on VETSA 2 means and sd.                                                    #
#-----------------------------------------------------------------------------------#

# Initialize dataframe to hold means and SDs
scaleValues = data.frame()

tedAdjZscoresData = tedAdjRawScoresData

# Scale VETSA 1 variables that have been adjusted for TEDALL
# Adds mean and SD to dataframe and deletes adjusted raw variables from dataset
for(i in rawVarsV1){
  varname = paste0(i, "_ted")
  zvarname = gsub("_ted","_zted",varname)
  tedAdjZscoresData[[zvarname]] = scale(tedAdjZscoresData[[varname]])
  scaleValues = addScaleVals(scaleValues, varname, tedAdjZscoresData[[zvarname]])
  tedAdjZscoresData[[varname]] = NULL
}

# Scale VETSA 2 variables that have been adjusted for TEDALL using VETSA 1 mean and SD
# Delete adjusted raw variable from dataset
for(i in rawVarsV2){
  varnameV2 = paste0(i, "_ted")
  zvarname = gsub("_ted","_zted",varnameV2)
  varnameV1 = gsub("_V2","",varnameV2)
  tedAdjZscoresData[[zvarname]] = scale(tedAdjZscoresData[[varnameV2]],
                                        center=scaleValues$Mean[scaleValues$Variable==varnameV1],
                                        scale=scaleValues$SD[scaleValues$Variable==varnameV1])
  tedAdjZscoresData[[varnameV2]] = NULL
}

# Save out adjusted and z-scored dataset
write.csv(tedAdjZscoresData, 
          "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1V2_CogData_TEDALLAdj_Z.csv",
          row.names = FALSE)

# Save out means and standard deviations used to standardize scores
write.csv(scaleValues, "~/netshare/K/Projects/PracticeEffects/data/Ronnlund/V1_TEDALLAdj_Means_SDs.csv",
          row.names = FALSE)
