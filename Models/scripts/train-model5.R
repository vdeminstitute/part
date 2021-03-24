#
#   Model 5: XGboost
#
#   AB: for the 2021 update, with fixed HP, this now runs in under 2m
#

# to ID output files
model_prefix <- "mdl5"

# The forecasts will vary a bit if we don't fix the RNG seed
set.seed(1234)

# install.packages("xgboost", dependencies = TRUE)

library(here)
library(lgr)

setwd(here::here("Models"))

# Load needed packages and setup global variables controlling model training
source("scripts/0-setup-training-environment.R")
# import functions
source("R/functions.R")

# Make learner
learner <- makeLearner("classif.xgboost", predict.type = "prob",
                       nrounds = 50, eta = 0.25, gamma = 0, max_depth = 8,
                       min_child_weight = 2.5, max_delta_step = 5,
                       subsample = 0.7, colsample_bytree = 0.65,
                       lambda = 1, alpha = 0,
                       nthread = N_CORES)


#
#   Test forecasts
#   _______________


lgr$info("Running test forecasts")
test_forecasts <- test_forecast(learner, full_task, TEST_FORECAST_YEARS)
write_rds(test_forecasts, file = sprintf("output/predictions/%s_test_forecasts.rds", model_prefix))


#
#   Live forecast
#   ________________


lgr$info("Running live forecast")
# Estimate final version of model on full data
mdl_full_data <- mlr::train(learner, full_task)
write_rds(mdl_full_data, file = sprintf("output/models/%s_full_data.rds", model_prefix))

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

lgr$info("Models done, please source assessment script")
