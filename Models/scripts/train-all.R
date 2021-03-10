#
#   Train all models
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


source("scripts/summarize-performance.R", echo = TRUE)
