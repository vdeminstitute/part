#
#   Model 3: Regularized logistic regresion (glmnet::glmnet(.., family = "binomial"))
#

# to ID output files
model_prefix <- "mdl3"

# Load needed packages and setup global variables controlling model training
source("scripts/0-setup-training-environment.R")
# import functions
source("R/functions.R")

#
#   Setup task and learner
#   ______________________

# Get reasonable range for lambda
lambda_start <- function() {
  registerDoParallel(cores = N_CORES)
  # what should i set lambda to?
  train_mat <- split_data$train[, !colnames(split_data$train) %in% TARGET] %>%
    as.matrix()
  target_vec <- as.numeric(as.character(split_data$train[[TARGET]]))
  cv.fit = cv.glmnet(train_mat, target_vec, family = "binomial", parallel = TRUE)
  # "Un-register" parallel backend
  registerDoSEQ()
  write_rds(cv.fit, "output/models/mdl3_tuning_results.rds")
  cv.fit
}

if (file.exists("output/models/mdl3_tuning_results.rds")) {
  cv.fit <- read_rds("output/models/mdl3_tuning_results.rds")
} else {
  cv.fit <- lambda_start()
}
lambda_range <- cv.fit$lambda %>% `[`(c(1, length(.))) %>% rev()

# back to hyperparameter tuning
ps <- makeParamSet(
  makeDiscreteParam("alpha", values = c(1, .9, .8, .7, .1, 0)),
  makeNumericParam("s", lower = lambda_range[1], upper = lambda_range[2])
)

# GLMNET with lambda and alpha selection via CV over random search grid
auto_glmnet <- makeTuneWrapper(
  learner    = makeLearner("classif.glmnet", predict.type = "prob"),
  resampling = makeResampleDesc("CV", iters = TUNE_CV_FOLDS),
  measures   = list(mlr::logloss), 
  par.set    = ps,
  control    = makeTuneControlRandom(maxit = RANDOM_TUNE_SAMPLES),
  show.info = TRUE
)

# since glmnet includes an intercept, for dummy features we need to drop a 
# reference column
full_task = dropFeatures(full_task, "lagged_v2x_regime_amb.0")

learner <- auto_glmnet
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

forecast_data <- split_data$fcast %>% select(-!!TARGET, -lagged_v2x_regime_amb.0)
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
