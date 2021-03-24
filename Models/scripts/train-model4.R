#
#   Model 4: Random forest
#
#   AB: for v11, it took 8m to run with 7 cores.
#

# to ID output files
model_prefix <- "mdl4"

# The forecasts will vary a bit if we don't fix the RNG seed
set.seed(1234)

library(here)
library(lgr)

setwd(here::here("Models"))

# Load needed packages and setup global variables controlling model training
source("scripts/0-setup-training-environment.R")
# import functions
source("R/functions.R")

# Setup learner
learner <- makeLearner("classif.ranger", predict.type = "prob",
                       num.trees = 2000, mtry = 80, min.node.size = 10,
                       sample.fraction = 1,
                       num.threads = N_CORES)

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
