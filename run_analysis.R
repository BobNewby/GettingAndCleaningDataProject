# run_analysis.R
#
# Getting and Cleaning Data Course Project
#
# Bob Newby on 4 April 2016
#
# produces two (2) tidy datasets:
#   mergedData
#   groupedMeans
# as described in the accompanying CodeBook.md file
#
# this script can be safely run in-place (i.e., directly in the folder in which it resides)

# start with a clean environment
remove(list = ls())

# load needed packages
library(dplyr)
library(tidyr)

# needed filepaths
downloadURL <- 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
downloadedZip <- 'dataset.zip'
parentDataDir <- file.path('.', 'UCI HAR Dataset')
activity_labels_file <- file.path(parentDataDir, 'activity_labels.txt')
features_file <- file.path(parentDataDir, 'features.txt')
trainingDataDir <- file.path(parentDataDir, 'train')
subject_train_file <- file.path(trainingDataDir, 'subject_train.txt')
X_train_file <- file.path(trainingDataDir, 'X_train.txt')
y_train_file <- file.path(trainingDataDir, 'y_train.txt')
testingDataDir <- file.path(parentDataDir, 'test')
subject_test_file <- file.path(testingDataDir, 'subject_test.txt')
X_test_file <- file.path(testingDataDir, 'X_test.txt')
y_test_file <- file.path(testingDataDir, 'y_test.txt')

# download zip file containing (raw) data to be prepared for analysis, and unzip it
# first, clean up any prior download artifacts
unlink(c(downloadedZip, parentDataDir), recursive = T)
download.file(downloadURL, downloadedZip, 'curl')
unzip(downloadedZip)

# load activity-labels data and rename the 2 columns ActivityIndex and Activity, respectively
# store result in activity_labels var
activity_labels <- tbl_df(read.table(activity_labels_file)) %>%
  rename(ActivityIndex = V1, Activity = V2) %>%
  mutate(Activity = as.factor(Activity))  # treat Activity as a factor

# load features data, rename the Feature column, and remove the extraneous column V1
# store result in features var
features <- tbl_df(read.table(features_file)) %>%
  rename(Feature = V2) %>%
  select(Feature)

# load X_test data, naming the columns per the vector features$Feature
# then subset it to the columns of interest (namely means and standard deviations)
# store the result in X_test var
X_test <- tbl_df(read.table(X_test_file, col.names = features$Feature))
X_test <- bind_cols( select(X_test, matches('mean')), select(X_test, matches('std')) )

# load X_train data, naming the columns per the vector features$Feature
# then subset it to the columns of interest (namely means and standard deviations)
# store the result in X_train var
X_train <- tbl_df(read.table(X_train_file, col.names = features$Feature))
X_train <- bind_cols( select(X_train, matches('mean')), select(X_train, matches('std')) )

# remove the intermediate dataset features
remove(features)

# load subject_test data, name the Subject column,
# append a DataUse column prepopulated with Testing,
# and treat both variables as factors
# store the result in subject_test var
subject_test <- tbl_df(read.table(subject_test_file)) %>%
  rename(Subject = V1) %>%
  mutate(Subject = as.factor(Subject), DataUse = as.factor('Testing'))

# load subject_train data, name the Subject column,
# append a DataUse column prepopulated with Training,
# and treat both variables as factors
# store the result in subject_train var
subject_train <- tbl_df(read.table(subject_train_file)) %>%
  rename(Subject = V1) %>%
  mutate(Subject = as.factor(Subject), DataUse = as.factor('Training'))

# bind subject_test and X_test columns
# store the result in testingData var
# remove intermediate datasets subject_test and X_test
testingData <- bind_cols(subject_test, X_test)
remove(subject_test, X_test)

# bind subject_train and X_train columns
# store the result in trainingData var
# remove intermediate datasets subject_train and X_train
trainingData <- bind_cols(subject_train, X_train)
remove(subject_train, X_train)

# load y_test data, renaming col to ActivityIndex
y_test <- tbl_df(read.table(y_test_file)) %>%
  rename(ActivityIndex = V1)

# load y_train data, renaming col to ActivityIndex
y_train <- tbl_df(read.table(y_train_file)) %>%
  rename(ActivityIndex = V1)

# create testingActivity and trainingActivity datasets by joining y_test and y_train,
# respectively, with activity_labels
# remove intermediate datasets y_test, y_train and activity_labels
testingActivity <- left_join(y_test, activity_labels, by = 'ActivityIndex')
trainingActivity <- left_join(y_train, activity_labels, by = 'ActivityIndex')
remove(y_test, y_train, activity_labels)

# bind the columns of testingActivity and testingData
# bind the columns of trainingActivity and trainingData
# store the results as testingData and trainingData vars, respectively
# remove intermediate datasets testingActivity and trainingActivity
testingData <- bind_cols(testingActivity, testingData)
trainingData <- bind_cols(trainingActivity, trainingData)
remove(testingActivity, trainingActivity)

# merge testingData with trainingData, treat Subject and DataUse as factors,
# remove the extraneous ActivityIndex column,
# and group the result by Acitivty, Subject and DataUse
# store the result in mergedData var
# remove the intermediate datasets trainingData and testingData
mergedData <- bind_rows(trainingData, testingData) %>%
  tbl_df() %>%
  mutate(Subject = as.factor(Subject), DataUse = as.factor(DataUse)) %>%
  select(-ActivityIndex) %>%
  group_by(Activity, Subject, DataUse)
remove(trainingData, testingData)

# using mergedData's Subject, Activity and DataUse factors/groups,
# aggregate mergedData by each Subject/Activity/DataUse combination,
# for each combination compute the mean of each data measurement (which are in cols after 1, 2 and 3),
# and group by Subject, Activity and DataUse
# store the result in groupedMeans var
groupedMeans <-
  aggregate(
    mergedData[,-(1:3)],
    list(mergedData$Subject, mergedData$Activity, mergedData$DataUse),
    mean) %>%
  tbl_df() %>%
  rename(Subject = Group.1, Activity = Group.2, DataUse = Group.3) %>%
  group_by(Subject, Activity, DataUse) %>%
  arrange(Subject, Activity, DataUse)

# check out the results!
mergedData %>% print
groupedMeans %>% print
View(mergedData)
View(groupedMeans)

# end of code
