#
#   Model 1: plain logistic regression model
#

# to ID output files
model_prefix <- "mdl1"

# Load needed packages and setup global variables controlling model training
source("scripts/0-setup-training-environment.R")
# import functions
source("R/functions.R")

#
#   Setup task and learner
#   ______________________

# Setup learner
glm_binomial <- makeLearner("classif.logreg", predict.type = "prob")

# The only feature should be v2x_regime
# leave out lagged_v2x_regime.0 as reference
drop <- setdiff(getTaskFeatureNames(full_task), paste0("lagged_v2x_regime.", 1:3))
full_task_narrow <- dropFeatures(full_task, drop)


learner <- glm_binomial
task    <- full_task_narrow

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
