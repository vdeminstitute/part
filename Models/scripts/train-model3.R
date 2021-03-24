#
#   Model 3: Regularized logistic regresion (glmnet::glmnet(.., family = "binomial"))
#
#   AB: running this for the 2021 update took about 12m with 7 cores
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

# since glmnet includes an intercept, for dummy features we need to drop a
# reference column
full_task = dropFeatures(full_task, "lagged_v2x_regime_amb.0")

# Make learner
learner <- makeLearner("classif.glmnet", predict.type = "prob",
                       alpha = 0.5, s = 0.01341932)


#
#   Test forecasts
#   _______________


lgr$info("Running test forecast")
test_forecasts <- test_forecast(learner, full_task, TEST_FORECAST_YEARS)
write_rds(test_forecasts, file = sprintf("output/predictions/%s_test_forecasts.rds", model_prefix))


#
#   Live forecast
#   ________________


lgr$info("Running live forecast")
# Estimate final version of model on full data
mdl_full_data <- mlr::train(learner, full_task)
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

lgr$info("Models done, please source assessment script")
