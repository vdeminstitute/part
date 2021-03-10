#
#   Model 4: Random forest
#
#   AB: for v11, it took 4.5 hours to run with 7 cores
#

# to ID output files
model_prefix <- "mdl4"

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

manual_tuning <- function() {
  # check out hyperparameter tuning; take this out later
  ps_rf = makeParamSet(
    makeIntegerParam("num.trees", lower = 200L, upper = 700L),
    makeIntegerParam("mtry", lower = 1L, upper = 40L),
    makeNumericParam("sample.fraction", lower = 0.25, upper = 1),
    makeIntegerParam("min.node.size", lower = 1L, upper = 200L)
  )

  res <- tuneParams(
    learner    = makeLearner("classif.ranger", predict.type = "prob"),
    task       = full_task,
    par.set    = ps_rf,
    resampling = makeResampleDesc("CV", iters = TUNE_CV_FOLDS),
    measures   = list(mlr::brier, mlr::timeboth),
    control    = makeTuneControlRandom(maxit = 200L)
  )

  write_rds(res, file = "output/models/mdl4_tuning_results.rds")

  # res <- read_rds("output/models/mdl4_tuning_results.rds")
  # data = generateHyperParsEffectData(res, partial.dep = T)
  #
  # # sample.fraction 0.8 seems to be reasonable
  # plotHyperParsEffect(data, x = "sample.fraction", y = "logloss.test.mean",
  #                     plot.type = "line", partial.dep.learn = "regr.ranger") +
  #   geom_point(data = data$data, aes(x = sample.fraction, y = logloss.test.mean))
  # ggplot(data = data$data, aes(x = sample.fraction, y = timeboth.test.mean)) +
  #   geom_point() + geom_smooth()
  #
  # # around 500 trees?
  # plotHyperParsEffect(data, x = "num.trees", y = "logloss.test.mean",
  #                     plot.type = "line", partial.dep.learn = "regr.ranger") +
  #   geom_point(data = data$data, aes(x = num.trees, y = logloss.test.mean))
  # ggplot(data = data$data, aes(x = num.trees, y = timeboth.test.mean)) +
  #   geom_point() + geom_smooth()
  #
  # # the more the better, about 30 to 40
  # plotHyperParsEffect(data, x = "mtry", y = "logloss.test.mean",
  #                     plot.type = "line", partial.dep.learn = "regr.ranger") +
  #   geom_point(data = data$data, aes(x = mtry, y = logloss.test.mean))
  # plotHyperParsEffect(data, x = "mtry", y = "logloss.test.mean", z = "logloss.test.mean",
  #                     plot.type = "line", partial.dep.learn = "regr.ranger") +
  #   geom_point(data = data$data, aes(x = mtry, y = logloss.test.mean))
  # ggplot(data = data$data, aes(x = mtry, y = timeboth.test.mean)) +
  #   geom_point() + geom_smooth()
}

if (file.exists("output/models/mdl4_tuning_results.rds")) {
  tr <- read_rds("output/models/mdl4_tuning_results.rds")
} else {
  tr <- manual_tuning()
}

# Parameter search space
ps_rf = makeParamSet(
  makeIntegerParam("mtry", lower = 10L, upper = 50L),
  makeNumericParam("sample.fraction", lower = 0.7, upper = 1)
)

# Random forest with hyperparameter optimization via 10-fold CV over random grid
auto_rf <- makeTuneWrapper(
  learner    = makeLearner("classif.ranger", predict.type = "prob",
                           num.trees = 1000, min.node.size = 10),
  par.set    = ps_rf,
  resampling = makeResampleDesc("CV", iters = TUNE_CV_FOLDS),
  measures   = list(mlr::brier),
  control    = makeTuneControlRandom(maxit = RANDOM_TUNE_SAMPLES),
  show.info  = TRUE)


learner <- auto_rf
task    <- full_task


#
#   Test forecasts
#   _______________


lgr$info("Running test forecasts")
test_forecasts <- test_forecast(learner, task, TEST_FORECAST_YEARS)
write_rds(test_forecasts, file = sprintf("output/predictions/%s_test_forecasts.rds", model_prefix))


#
#   Live forecast
#   ________________


lgr$info("Running live forecast")
# Estimate final version of model on full data
mdl_full_data <- mlr::train(learner, task)
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

#
#   Process results / creates figures, performance tables, etc.
#   ____________________________________
#
#   The behavior of the assess-model.R script depends on having the correct
#   model_prefix variable set at the beginning of this script.
#

lgr$info("Models done, sourcing assessment script")
source("scripts/assess-model.R")
