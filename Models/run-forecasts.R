#
#   Run all scripts neccessary to create the final forecast
#
#   Andreas Beger
#   2021-03-12
#
#   There are 6 model scripts in total. These correspond to a lagged DV
#   logistic regression (model 1), logistic regression with a few more
#   predictors (2), regularized logistic regression (glmnet; 3),
#   random forest (4), boosted forest (xgboost; 5), and an ensemble
#   of models 3, 4, and 5 (model 6). The ensemble are the final predictions
#   that end up in the dashboard.
#
#   Each model script can be run by itself. In fact this is how I run them.
#   Note that each is setup to run in parallel. In any case, this file shows
#   how to run them in order, as well as the final scripts that summarize the
#   each models forecasts and overall performance/accuracy.
#

setwd(here::here("Models"))

# Logistic regression
source("scripts/train-model1.R", echo = TRUE)

# Restricted logistic regression
source("scripts/train-model2.R", echo = TRUE)

# Regularized logistic regression (glmnet)
source("scripts/train-model3.R", echo = TRUE)

# Random forest
source("scripts/train-model4.R", echo = TRUE)

# XGBoost
source("scripts/train-model5.R", echo = TRUE)

# Ensemble of glmnet, rf, xgboost
source("scripts/train-model6.R", echo = TRUE)

# Update forecast plots/performance summary for each model
source("scripts/assess-model.R", echo = TRUE)

# Keep a summary of overall performance/accuracy
source("scripts/summarize-performance.R", echo = TRUE)

# UPDATE:
# the final forecasts are in mdl6_live_forecasts.rds and mdl6_test_forecasts.rds
# copy those over to dashboard/data-raw and then in that folder
# data-organization.R will need to be run in order to update the transformed
# data objects the dashboard actually uses.
#
# The train-model6.R script, which does the ensemble, will also already have
# written a more human-readable copy of the forecasts to archive/
#

