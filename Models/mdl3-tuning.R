#
#   Manual tuning investigation for the glmnet model (model 3)
#
#   51m for 6 tunes
#

TUNE_N  <- 6
WORKERS <- 7

library(dplyr)
library(glmnet)
library(doFuture)
library(here)
library(readr)
library(lgr)

setwd(here("Models"))

#registerDoParallel(cores = WORKERS)
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

# Set up X and y matrix/vector for glmnet
train_x <- as.matrix(part[, setdiff(colnames(part), c("any_neg_change_2yr", id_cols))])
train_y <- as.numeric(part[["any_neg_change_2yr"]])


# Helper functions --------------------------------------------------------

bin_class_summary <- function(obs, pred) {
  brier  <- mean((pred - obs)^2)
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

# Given a cv.glment object (x) and truth vector, extract performance measures
# for a specific lambda (at = ...)
s_performance <- function(x, truth, at = c("min", "1se")) {
  at <- match.arg(at)
  out <- data.frame(lambda_criterion = at)
  optlams <- x[paste0("lambda.", at)]
  which = match(optlams, x$lambda)
  out$lambda   <- unlist(optlams)
  out[[names(x$name)]] <- x$cvm[which]  # aka measure
  out$non_zero <- x$nzero[which]

  # this gets the "prevalidated" (out-of-sample?) predictions for lambda
  preds <- plogis(x$fit.preval[, x$index[at, ]])
  ff  <- bin_class_summary(obs = truth, preds)
  out <- cbind(out, as.data.frame(as.list(ff)))
  out
}

# Perform one iteration of the tuning:
# given a value of alpha, fit cv.glmnet, and extract performance measures
one_tune_iteration <- function(x, y, foldid, alpha) {
  t0 <- Sys.time()
  cv.fit = cv.glmnet(x = train_x, y = train_y, family = "binomial",
                     type.measure = "mse", foldid = foldid,
                     alpha = alpha,
                     parallel = TRUE,
                     relax = FALSE,  # gamma; this takes forever to run
                     keep = TRUE)    # keep the pre-validated preds
  perf_min <- s_performance(cv.fit, truth = y, at = "min")
  perf_1se <- s_performance(cv.fit, truth = y, at = "1se")
  out <- rbind(perf_min, perf_1se)
  out <- cbind(alpha = alpha, out)
  out$time <- as.numeric(Sys.time() - t0)
  out
}


# Iterate over models -----------------------------------------------------

alpha = seq(1, 0.5, length.out = TUNE_N)

# For cv.glmnet, I want to do blocked CV by year. There are 40+ years,
# so chunk into groups of roughly 3 years, 14-fold CV
# code based on https://github.com/berndbischl/BBmisc/blob/master/R/chunk.R
years  <- unique(part$year)
chunk_size <- 3L
nx <- length(years)
n_chunks <- nx %/% chunk_size + (nx %% chunk_size > 0L)
yearid <- sort(seq.int(0L, nx - 1L) %% n_chunks) + 1L
foldid <- yearid[match(part$year, years)]


# cv.glmnet will run in parallel, so do a simple loop here
perf <- list(NULL)

for (i in seq_along(alpha)) {
  lgr$info("Tune interation %s of %s", i, length(alpha))
  alpha_i <- alpha[[i]]
  perf_i  <- one_tune_iteration(x = train_x, y = train_y, foldid = foldid,
                                alpha = alpha_i)
  perf_i
  perf[[i]] <- perf_i
  # Save progress just in case
  saveRDS(perf, here::here("Models/output/tuning/model3-tuning.rds"))
}

perf <- bind_rows(perf)
saveRDS(perf, here::here("Models/output/tuning/model3-tuning.rds"))


perf <- readRDS(here::here("Models/output/tuning/model3-tuning.rds"))

# overall best performance for each measure?
perf %>%
  pivot_longer(cols = -c(alpha, lambda_criterion, lambda, non_zero)) %>%
  group_by(name) %>%
  mutate(
    min_value = min(value),
    max_value = max(value),
    optim_value = case_when(
    name %in% c("mse", "Brier", "Logloss", "time") ~ min(value),
    TRUE ~ max(value))
  ) %>%
  filter(value==optim_value)

# this tends to pick min, what if we look at 1se?
perf %>%
  pivot_longer(cols = -c(alpha, lambda_criterion, lambda, non_zero)) %>%
  filter(lambda_criterion=="1se") %>%
  group_by(name) %>%
  mutate(
    min_value = min(value),
    max_value = max(value),
    optim_value = case_when(
      name %in% c("mse", "Brier", "Logloss", "time") ~ min(value),
      TRUE ~ max(value))
  ) %>%
  filter(value==optim_value)

# alpha really cuts down time below 1
plot(perf$alpha, perf$time, ylim = c(0, max(perf$time)))
plot(perf$alpha, perf$mse, ylim = c(0, max(perf$mse)))
plot(perf$alpha, perf$Brier, ylim = c(0, max(perf$Brier)))
plot(perf$alpha, perf$Logloss, ylim = c(0, max(perf$Logloss)))
plot(perf$alpha, perf$AUC_PR, ylim = c(0, max(perf$AUC_PR)))
plot(perf$alpha, perf$non_zero, ylim = c(0, max(perf$non_zero)))
# the 1se lambda cuts non-zero coefs down to <20, from ~80.
# otherwise lower values of alpha don't seem to really impact performance that
# much.
# So, pick a low value of alpha to speed up training and call it a day,
# take the lambda values from that, and I would say average them so that
# we get a few more non-zero coefs.
plot(perf$lambda, perf$non_zero)

pick <- perf %>%
  filter(alpha==0.5) %>%
  summarize(alpha = unique(alpha), lambda = mean(lambda)) %>%
  as.list()


