
TUNE_N  <- 20
WORKERS <- 7

library(dplyr)
library(ranger)
library(doFuture)
library(doRNG)
library(here)
library(readr)
library(lgr)

setwd(here("Models"))

registerDoFuture()
plan("multisession", workers = WORKERS)

part <- read_csv("input/part-v11.csv", col_types = cols())
# # take these out from training data
id_cols <- c("gwcode", "year", "country_name", "country_id", "v2x_regime",
             "v2x_regime_amb", "any_neg_change")

part$lagged_v2x_regime_asCharacter <- NULL
part$lagged_v2x_regime_asFactor <- NULL
part$country_text_id <- NULL

# Dummy out regime
for (i in 0:3) {
  v <- "lagged_v2x_regime"
  newv <- paste0(v, i)
  part[[newv]] <- part[[v]]==i
}
part$lagged_v2x_regime <- NULL


# Only use data before 2011
part <- part[part$year < 2011, ]




# Construct tuning grid ---------------------------------------------------

tune_grid <- tibble(
  row = 1:TUNE_N,
  num.trees       = as.integer(runif(TUNE_N, min = 5, max = 20.99))*100,
  mtry            = as.integer(runif(TUNE_N, min = 5, max = 80)),
  min.node.size   = as.integer(runif(TUNE_N, min = 1, max = 20)),
  sample.fraction = runif(TUNE_N, min = 0.5, max = 1),
  cost = list(NULL)
)

bin_class_summary <- function(obs, pred) {
  brier  <- mean((pred-obs)^2)
  ## measures the mean squared difference between: The predicted probability assigned to the possible outcomes for item i The actual outcome o_i.
  ## The lower the Brier score is for a set of predictions, the better the predictions are calibrated.
  aucroc <- tryCatch(MLmetrics::AUC(y_pred = pred, y_true = obs), error = function(e) NA)
  ## ROC is a probability curve and AUC represents degree or measure of separability.
  ## Higher the AUC better the model. "The probability that a random positive is assigned a higher score than a random negative."
  aucpr  <- tryCatch(MLmetrics::PRAUC(y_pred = pred, y_true = obs), error = function(e) NA)
  ## Precision Recall area under curve -- Precision-Recall is a useful measure of success of prediction when the classes are very imbalanced. In information retrieval, precision is a measure of result relevancy, while recall is a measure of how many truly relevant results are returned.
  ## The tradeoff between precision and recall for different threshold, where high precision relates to a low false positive rate, and high recall relates to a low false negative rate.
  ## High scores for both show that the classifier is returning accurate results (high precision), as well as returning a majority of all positive results (high recall).
  cagg   <- e1071::classAgreement(table(obs, as.integer(pred > 0.5)))
  acc    <- cagg[["diag"]]
  ## The Kappa statistic (or value) is a metric that compares an Observed Accuracy with an Expected Accuracy (random chance).
  ## It takes into account agreement with a random classifier, which generally means it is less misleading than simply using accuracy
  logloss <- yardstick::mn_log_loss_vec(truth = factor(obs, levels = c("1", "0")),
                                        estimate = pred,
                                        event_level = "first")
  out <- c(Brier = brier, Logloss = logloss, Accuracy = acc,
           AUC_ROC = aucroc, AUC_PR = aucpr)
  out
}

cv_by_year <- function(data, hp, id_cols, target = "any_neg_change_2yr") {
  preds <- rep(NA_real_, nrow(data))
  idx   <- data[["year"]]
  obs   <- data[[target]]
  for (y in unique(data$year)) {
    train_x <- data[data$year!=y, !colnames(data) %in% c(target, id_cols)]
    test_x  <- data[data$year==y, !colnames(data) %in% c(target, id_cols)]
    train_y <- factor(obs[y!=idx], levels = c("1", "0"))
    mdl <- ranger::ranger(y = train_y, x = train_x, probability = TRUE,
                          num.trees       = hp[["num.trees"]],
                          mtry            = hp[["mtry"]],
                          min.node.size   = hp[["min.node.size"]],
                          sample.fraction = hp[["sample.fraction"]],
                          num.threads = 1)
    preds[idx==y] <- predict(mdl, data = test_x)$predictions[, "1"]
  }
  bin_class_summary(obs, preds)
}


# Instead of doing a function that handles CV by year, unroll that into the
# tuning grid so that we get a large number of models that we can run in
# parallel more easily
one_model <- function(data, hp, id_cols, target = "any_neg_change_2yr",
                      leave_out_year) {
  # leave_out_year could be 1 or multiple years
  y = leave_out_year
  if (is.list(y)) y <- unlist(y)
  out_sample <- data$year %in% y
  in_sample  <- !out_sample

  train_x <- data[in_sample, !colnames(data) %in% c(target, id_cols)]
  test_x  <- data[out_sample, !colnames(data) %in% c(target, id_cols)]
  train_y <- factor(data[in_sample, ][[target]], levels = c("1", "0"))
  test_y  <- data[out_sample, ][[target]]

  mdl <- ranger::ranger(y = train_y, x = train_x, probability = TRUE,
                        num.trees       = hp[["num.trees"]],
                        mtry            = hp[["mtry"]],
                        min.node.size   = hp[["min.node.size"]],
                        sample.fraction = hp[["sample.fraction"]],
                        num.threads = 1, verbose = FALSE)
  data.frame(obs = test_y, pred1 = predict(mdl, data = test_x)$predictions[, "1"])
}

# split into groups of 4 years, roughly 13-fold CV
years <- unique(part$year)
years <- split(years, ceiling(seq_along(years)/4))
tune_grid <- tidyr::crossing(tune_grid, leave_out = years)


# Iterate over models -----------------------------------------------------


cat(sprintf("Fitting a total of %s models\n", nrow(tune_grid)))
tune_grid$preds = list(NULL)

# Randomly shuffle so workers are more evenly assigned
tune_grid <- tune_grid[sample(1:nrow(tune_grid)), ]

tune_grid <- foreach(
  i = 1:nrow(tune_grid),
  .combine = bind_rows,
  .inorder = FALSE
) %dorng% {
  tune_grid_i <- tune_grid[i, ]
  preds <- one_model(part, hp = tune_grid_i, id_cols = id_cols,
                     target = "any_neg_change_2yr",
                     leave_out_year = tune_grid_i[["leave_out"]])
  tune_grid_i[["preds"]] <- list(preds)
  tune_grid_i
}

list_bin_class_summary <- function(l) {
  l <- l[[1]]
  as_tibble(as.list(bin_class_summary(obs = l[["obs"]], pred = l[["pred1"]])))
}

tune_grid <- tune_grid %>%
  group_by(row, num.trees, mtry, min.node.size, sample.fraction) %>%
  summarize(preds = list(bind_rows(preds)), .groups = "keep") %>%
  summarize(cost = list(list_bin_class_summary(preds)), .groups = "drop") %>%
  tidyr::unnest(cost)

# append new results to existing grid
fn <- "Models/output/tuning/model4-tuning.rds"
if (file.exists(here::here(fn))) {
  res <- readRDS(here::here(fn))
  tune_grid <- bind_rows(res, tune_grid)
}

saveRDS(tune_grid, here::here("Models/output/tuning/model4-tuning.rds"))



