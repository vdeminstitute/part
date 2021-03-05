#
#   Model 5: XGboost
#

# to ID output files
model_prefix <- "mdl5"

# Load needed packages and setup global variables controlling model training
source("scripts/0-setup-training-environment.R")
# import functions
source("R/functions.R")

#
#   Setup task and learner
#   ______________________

# Parameter search space
ps_xgboost <- makeParamSet(
  # The number of trees in the model (each one built sequentially)
  makeIntegerParam("nrounds", lower = 100, upper = 500),
  # number of splits in each tree
  makeIntegerParam("max_depth", lower = 1, upper = 10),
  # "shrinkage" - prevents overfitting
  makeNumericParam("eta", lower = .1, upper = .5),
  # L2 regularization - prevents overfitting
  makeNumericParam("lambda", lower = -1, upper = 0, trafo = function(x) 10^x)
)

# Random forest with hyperparameter optimization via 10-fold CV over random grid
auto_xgboost <- makeTuneWrapper(
  learner    = makeLearner("classif.xgboost", predict.type = "prob"), 
  par.set    = ps_xgboost,
  resampling = makeResampleDesc("CV", iters = TUNE_CV_FOLDS),
  measures   = list(mlr::brier), 
  control    = makeTuneControlRandom(maxit = RANDOM_TUNE_SAMPLES), 
  show.info  = FALSE)


learner <- auto_xgboost
task    <- full_task


#
#   Cross-validation   
#   ________________

# Get OOS performance of model
mdl_resamples <- resample(learner, task, resample_strategy,
                          measures = ACC_MEASURES)

# Estimate final version of model on full data
mdl_full_data <- mlr::train(learner, task)

# Training predictions for full data
preds_oos <- tidy_ResampleResult(mdl_resamples)

# Save artifacts
write_rds(mdl_resamples, path = sprintf("output/models/%s_resamples.rds", model_prefix))
write_rds(mdl_full_data, path = sprintf("output/models/%s_full_data.rds", model_prefix))
write_rds(preds_oos,     path = sprintf("output/predictions/%s_cv_preds.rds", model_prefix))


#
#   Test forecasts
#   _______________


test_forecasts <- test_forecast(learner, task, TEST_FORECAST_YEARS)

write_rds(test_forecasts, path = sprintf("output/predictions/%s_test_forecasts.rds", model_prefix))


# 
#   Live forecast
#   ________________

forecast_data <- split_data$fcast %>% select(-!!TARGET)
fcast <- predict(mdl_full_data, newdata = as.data.frame(forecast_data))

fcast <- bind_cols(split_data$fcast_ids[, c("gwcode", "country_name", "year")], 
                   split_data$fcast[, TARGET, drop = FALSE],
                   fcast$data) %>%
  arrange(prob.1)

write_rds(fcast, sprintf("output/predictions/%s_live_forecast.rds", model_prefix))

#
#   Cleanup
#   ________

parallelStop()

#
#   Process results / creates figures, performance tables, etc.
#   ____________________________________
#
#   The behavior of the assess-model.R script depends on having the correct 
#   model_prefix variable set at the beginning of this script. 
#

source("scripts/assess-model.R")
