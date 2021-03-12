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
#   They can take several hours each to run, and are setup to run in parallel.
#   In any case, this file shows how to run them in order, as well as the
#   final script that summarizes the overall performance/accuracy.
#
#   NOTE: When running as a RStudio job, the model assessment run at the end of
#   each script does not work correctly. Go into `assess-model.R`, uncomment
#   and adjust `model_prefix <- ...` as needed, and manually run the script.
#

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

# Keep a summary of overall performance/accuracy
source("scripts/summarize-performance.R", echo = TRUE)
