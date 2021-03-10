#
#   Assess model results
#   2019-02-20
#

packs <- c("tidyverse", "readr", "mlr", "glmnet", "here", "MLmetrics", "pROC",
           "xtable", "futile.logger", "parallelMap", "e1071", "MLmetrics",
           "doParallel", "states")
# install.packages(packs, dependencies = TRUE)
lapply(packs, library, character.only = TRUE)

source("R/functions.R")

#   This relies on model_prefix to find relevant files
#   This is already set in the train models scripts, but if running this
#   script by itself, set it.
#model_prefix <- "mdl1"

plot_title <- switch(model_prefix,
                     mdl1 = "Base rate Model",
                     mdl2 = "Logistic Regression /w some features",
                     mdl3 = "Elastic-net Regularization",
                     mdl4 = "Random Forest",
                     mdl5 = "Gradient-boosted Forest",
                     mdl6 = "Average of All ML Models")

#
#   Load needed data
#   _________________

# UPDATE:
dv_dat <- read_csv("input/part-v11.csv", col_types = cols())%>%
	select(gwcode, year, any_neg_change)
test_forecasts <- read_rds(sprintf("output/predictions/%s_test_forecasts.rds", model_prefix))
live_forecasts <- read_rds(sprintf("output/predictions/%s_live_forecast.rds", model_prefix))


#
#   Test forecasts
#   _______________

test_fcast_perf <- bin_class_summary(test_forecasts$truth, test_forecasts$prob.1) %>%
  tibble(model = model_prefix, set = "test forecasts", measure = names(.), value = .)

test_fcast_perf %T>%
  write_csv(., sprintf("output/performance/%s-test-forecast-performance.csv", model_prefix)) %>%
  print()

p <- ggsepplot(test_forecasts$truth, test_forecasts$prob.1)
ggsave(sprintf("output/figures/%s-sepplot-test-forecsts.pdf", model_prefix), plot = p, height = 2, width = 8)

# Yearly check plots
for (y in unique(test_forecasts$year)) {

  test_forecasts_this_year <- test_forecasts %>%
    filter(year==y) %>%
    mutate(Pr1 = round(prob.1, 4)) %>%
    arrange(Pr1)%>%
    left_join(dv_dat)

  perf_this_year <- bin_class_summary(test_forecasts_this_year$truth, test_forecasts_this_year$prob.1)

  BaseSepPlotsFun(sprintf("output/figures/%s-%s-yearly-check.pdf", model_prefix, y),
                  threshold = 0.05,
                  year = y,
                  N = 34,
                  preds = test_forecasts_this_year$Pr1,
                  truth = test_forecasts_this_year$truth,
                  any_neg_change = test_forecasts_this_year$any_neg_change,
                  country_names = test_forecasts_this_year$country_name,
                  kappa_score  = perf_this_year["Kappa"],
                  auc_pr_score = perf_this_year["AUC_PR"],
                  brier_score  = perf_this_year["Brier"],
                  model_name   = plot_title)
}

# Live forecast plots

live_forecasts <- live_forecasts%>%
	mutate(color_prob = case_when(prob.1 < 0.03 ~ "#fef0d9",
                        prob.1 < 0.05 ~ "#fdcc8a",
                        prob.1 < 0.1 ~ "#fc8d59",
                        prob.1 < 0.15 ~ "#e34a33",
                        prob.1 >= 0.15 ~ "#b30000"),
		Pr1 = round(prob.1, 4))%>%
    arrange(Pr1)


BaseSepPlotsFun_live(sprintf("output/figures/%s-live-forecast.pdf", model_prefix),
					# threshold = 0.1,
					year = 2018,
					N = 34,
					preds = live_forecasts$Pr1,
					country_names = live_forecasts$country_name,
					model_name = plot_title,
					colors = live_forecasts$color_prob)
