#
#   xgboost (model 5) hyperparameter tuning
#
#   Andreas Beger
#   2021-03-13
#
#


TUNE_N  <- 5
WORKERS <- 7

library(dplyr)
library(xgboost)
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
  # Number of boosting rounds
  nrounds = as.integer(round(runif(TUNE_N, min = 2, max = 100))),
  # Step size shrinkage; default 0.3, [0, 1]
  eta = runif(TUNE_N, min = 0, max = 1),
  # Minimum loss reduction to grow leaf node; default 0, [0, Inf]
  gamma = 0,
  # Maximum tree depth; default 6, [0, Inf]
  max_depth = as.integer(runif(TUNE_N, min = 2, max = 10)),
  # Minimum sum of instance weight (hessian) needed in a child; default 1, [0, Inf]
  min_child_weight = runif(TUNE_N, 0.5, 1),
  # Maximum delta step for each leaf node; default 0, [1, 10] for imbalanced
  max_delta_step = runif(TUNE_N, 0, 10),
  # Sampling for each round; default 1, [0, 1]
  subsample = runif(TUNE_N, .5, 1),
  # Columns to sample for each tree; default 1, [0, 1]
  colsample_bytree = runif(TUNE_N, 0.5, 1),
  # L2 norm
  lambda = 1,
  # L1 norm
  alpha = 0
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
  train_y <- data[in_sample, ][[target]] #, levels = c("1", "0")
  dtrain <- xgb.DMatrix(data = as.matrix(train_x), label = train_y)

  test_x <- data[out_sample, !colnames(data) %in% c(target, id_cols)]
  test_y <- data[out_sample, ][[target]]
  dtest <- xgb.DMatrix(data = as.matrix(test_x), label = test_y)

  mdl <- xgb.train(data = dtrain, objective = "binary:logistic",
                   nrounds = hp[["nrounds"]],
                   params = hp)

  data.frame(obs = test_y, pred1 = predict(mdl, newdata = dtest))
}



# Iterate over models -----------------------------------------------------


# Split the training data into groups of 3 randomly-selected years,
# roughly 13-fold CV
years  <- unique(part$year)
chunk_size <- 3L
nx <- length(years)
n_chunks <- nx %/% chunk_size + (nx %% chunk_size > 0L)
yearid <- sort(seq.int(0L, nx - 1L) %% n_chunks) + 1L
yearid <- sample(yearid)
years <- split(years, yearid)

# Unroll CV models
# Instead of, for one set of hyperparameters, fitting the cross-validation
# procedure, unroll the CV models we need to run. I.e. for one set of HP,
# if we are doing 10-fold CV, we need to run 10 models. Instead of doing that
# in one call and parallelizing over the HP sets, unroll the CV models as well,
# so we have more efficient parallelization.
tune_grid <- tidyr::crossing(tune_grid, leave_out = years)

cat(sprintf("Fitting a total of %s models\n", nrow(tune_grid)))

# Randomly shuffle so workers are more evenly assigned
tune_grid <- tune_grid[sample(1:nrow(tune_grid)), ]

# Run the models
tune_grid <- foreach(
  i = 1:nrow(tune_grid),
  .combine = bind_rows,
  .inorder = FALSE
) %dorng% {
  hp_i <- tune_grid[i, ]
  hp_i$leave_out <- NULL
  test_years <- tune_grid[i, ][["leave_out"]][[1]]

  preds <- one_model(part, hp = hp_i, id_cols = id_cols,
                     target = "any_neg_change_2yr",
                     leave_out_year = test_years)
  hp_i[["preds"]] <- list(preds)
  hp_i
}

list_bin_class_summary <- function(l) {
  l <- l[[1]]
  as_tibble(as.list(bin_class_summary(obs = l[["obs"]], pred = l[["pred1"]])))
}

tune_grid <- tune_grid %>%
  group_by(nrounds, eta, gamma, max_depth, min_child_weight, max_delta_step,
           subsample, colsample_bytree, lambda, alpha) %>%
  summarize(preds = list(bind_rows(preds)), .groups = "keep") %>%
  summarize(cost = list(list_bin_class_summary(preds)), .groups = "drop") %>%
  tidyr::unnest(cost)

# append new results to existing grid
fn <- "Models/output/tuning/model5-tuning.rds"
if (file.exists(here::here(fn))) {
  res <- readRDS(here::here(fn))
  tune_grid <- bind_rows(res, tune_grid)
}

saveRDS(tune_grid, here::here("Models/output/tuning/model5-tuning.rds"))



