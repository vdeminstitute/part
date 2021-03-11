#
#   Model 3: Regularized logistic regresion (glmnet::glmnet(.., family = "binomial"))
#
#   AB: running this for the 2021 update took about 1hr with 7 cores
#

# to ID output files
model_prefix <- "mdl3"

library(here)
library(lgr)

setwd(here::here("Models"))

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

# since glmnet includes an intercept, for dummy features we need to drop a
# reference column
full_task = dropFeatures(full_task, "lagged_v2x_regime_amb.0")

learner <- makeLearner("classif.glmnet", predict.type = "prob",
                       alpha = 0.5, s = 0.01341932)
task    <- full_task


#
#   Test forecasts
#   _______________


lgr$info("Running test forecast")
test_forecasts <- test_forecast(learner, task, TEST_FORECAST_YEARS)
write_rds(test_forecasts, file = sprintf("output/predictions/%s_test_forecasts.rds", model_prefix))


#
#   Live forecast
#   ________________


lgr$info("Running live forecast")
# Estimate final version of model on full data
mdl_full_data <- mlr::train(learner, task)
write_rds(mdl_full_data, file = sprintf("output/models/%s_full_data.rds", model_prefix))

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

lgr$info("Models done, sourcing assessment script")
source("scripts/assess-model.R")
