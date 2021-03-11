#
#   Write a summary of the models' accuracy
#

# UPDATE:
VERSION <- "v11"

library("readr")
library("purrr")
library("readr")
library("tidyr")
library("dplyr")

all_perf <- dir("output/performance",
                pattern = "mdl[0-9]+[a-z-]+performance.csv",
                full.names = TRUE) %>%
  # so that dfr id is not just index
  setNames(., .) %>%
  map_dfr(., read_csv, col_types = cols(
    model = col_character(),
    set = col_character(),
    measure = col_character(),
    value = col_double()),
    .id = "file_path") %>%
  # add file mod time so we know when model was trained
  mutate(trained_on = map_chr(file_path, function(x) {
    out <- file.info(x)[["mtime"]]
    as.character(as.Date(out))
  })) %>%
  mutate(name = case_when(
    model=="mdl1" ~ "Lagged RoW logistic regression",
    model=="mdl2" ~ "Small feature set logistic regression",
    model=="mdl3" ~ "Elastic net logistic regression",
    model=="mdl4" ~ "Random forest",
    model=="mdl5" ~ "XGBoost",
    model=="mdl6" ~ "Ensemble",
    TRUE ~ "fill me in"
  )) %>%
  select(-file_path)


test_perf <- all_perf %>%
  filter(set=="test forecasts") %>%
  spread(measure, value) %>%
  arrange(model) %>%
  select(name, model, Brier, AUC_ROC, AUC_PR, Kappa, trained_on)#, everything()) ## Accuracy,
test_perf

write_csv(test_perf, "output/tables/test-perf.csv")

test_perf %>%
  knitr::kable("markdown", digits = 3) %>%
  writeLines("output/tables/test-perf.md")

# keep a record too
test_perf %>%
  knitr::kable("markdown", digits = 3) %>%
  writeLines(sprintf("output/tables/test-perf-%s.md", VERSION))

