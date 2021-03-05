#
#   Setup training environment
#   2019-02-20
#
#   Run this before trying to train a model; this sets up the globals and 
#   data.
#

packs <- c("tidyverse", "rio", "mlr", "glmnet", "here", "MLmetrics", "pROC", 
           "xtable", "futile.logger", "parallelMap", "e1071", "MLmetrics", 
           "doParallel", "states")
# install.packages(packs, dependencies = TRUE)
# install.packages("C:/Users/xricmo/Dropbox/VForecast/vfcast_0.0.1.tar.gz")
lapply(packs, library, character.only = TRUE)

stopifnot(basename(getwd())=="VForecast")

# which year to forecast for?
TARGET_YEAR <- 2019
# test forecast years
TEST_FORECAST_YEARS <- 2011:2017  # this should be one less than TARGET_YEAR 
                                  # because any_neg_change_2yr looks ahead at 
                                  # next year, but we don't know what 
                                  # any_neg_change in 
TARGET <- "any_neg_change_2yr"

# Model training settings
CV_REPS       <- 2L
CV_FOLDS      <- 7L
TUNE_CV_FOLDS <- 7L
# How many samples to take for random tune grids?
RANDOM_TUNE_SAMPLES <- 21L
ACC_MEASURES <- list(mlr::brier, mlr::auc, mlr::timeboth)
N_CORES      <- 7L

# Make it parallel ?parallel
if (.Platform$OS.type == "windows") {
  parallelMap::parallelStartSocket(N_CORES)
} else {
  parallelMap::parallelStartMulticore(cpus = N_CORES)
}

# Choose a resampling strategy
if (CV_REPS == 1L) {
  resample_strategy = makeResampleDesc("CV", iters = CV_FOLDS)
} else {
  resample_strategy = makeResampleDesc("RepCV", reps = CV_REPS, folds = CV_FOLDS)
}


#
#   Process data ----
#   __________________

# Country names
data("gwstates")
cnames <- gwstates %>%
  group_by(gwcode) %>%
  dplyr::slice(n()) %>%
  select(gwcode, country_name)

# Complete, non-missing data, except for the TARGET, which will be missing for the 
# last year.

complete_data <- read_csv("input/ALL_data_final_USE_v9.csv")
# # take these out from training data
id_cols <- c("gwcode", "year", "country_name", "country_text_id", "country_id",
             "v2x_regime", "v2x_regime_amb", "any_neg_change") 

drop_vars <- c("date", "lagged_v2x_regime_asCharacter", "lagged_v2x_regime_asFactor")
dim(complete_data)[2] - length(id_cols) - length(drop_vars)


# Check there are only missing target values in last year
missing_target_by_year <- complete_data %>% 
  group_by(year) %>% 
  summarize(n = sum(is.na(any_neg_change_2yr)))

# check
miss_years <- missing_target_by_year[missing_target_by_year$n > 0, "year"][[1]]
if (any(miss_years!=TARGET_YEAR)) {
  stop("Somethign is wrong with missing values in 'any_neg_change_2yr'")
}

# Index for complete training data and forecast data (DV is missing)
train_idx <- complete.cases(complete_data)
fcast_idx <- complete_data$year %in% missing_target_by_year$year[missing_target_by_year$n > 0]

complete_data <- complete_data%>%
  mutate(any_neg_change_2yr = factor(any_neg_change_2yr)) %>%
  # convert hidden discrete vars to dummy 
  # NOTE: this does not leave out a reference level; take out intercept in any
  # models that include this feature
  mutate(lagged_v2x_regime = as.factor(lagged_v2x_regime)) %>%
  mlr::createDummyFeatures(., cols = "lagged_v2x_regime")

# Split data; this will be a list containing all the data partitions we 
# need for training, out-of-sample eval, etc.
split_data <- list(
  # Training set
  train_ids = complete_data %>% dplyr::filter(train_idx) %>% 
    dplyr::select(id_cols),
  train     = complete_data %>% dplyr::filter(train_idx) %>% 
    dplyr::select(-one_of(id_cols, drop_vars)) %>% as.data.frame(),
  # Forecast data
  fcast_ids = complete_data %>% dplyr::filter(fcast_idx) %>% 
    dplyr::select(id_cols),
  fcast     = complete_data %>% dplyr::filter(fcast_idx) %>% 
    dplyr::select(-one_of(id_cols, drop_vars)) %>% as.data.frame()
)

write_rds(split_data, "output/split-data.rds")

full_task <- makeClassifTask(data = split_data$train, 
                             target = "any_neg_change_2yr", 
                             positive = "1")



