#
#   Model 6: Ensemble
#
#   This model is an ensemble, via a simple average, of the predictions from
#   models 3, 4, and 5.
#

# to ID output files
model_prefix <- "mdl6"

# UPDATE: what version of V-Dem is this set of forecasts using?
VERSION = "v11"

library(here)
library(lgr)

setwd(here::here("Models"))

# Load needed packages and setup global variables controlling model training
source("scripts/0-setup-training-environment.R")
# import functions
source("R/functions.R")

preds_needed <- expand.grid(
  paste0("mdl", 3:5),
  c("test", "live"),
  "forecasts.rds"
) %>%
  apply(., 1, paste0, collapse = "_")



#
#   Test forecasts
#   _______________

test_preds <- dir("output/predictions", pattern = "[3-5]{1}_test", full.names = TRUE) %>%
  setNames(., nm = str_extract(., "mdl[0-9]{1}"))
test_preds <- test_preds %>% map_dfr(read_rds, .id = "model")
test_forecasts <- test_preds %>%
  group_by(gwcode, country_name, year, id) %>%
  summarize(any_neg_change_2yr = unique(any_neg_change_2yr),
            truth = unique(truth),
            prob.0 = mean(prob.0),
            prob.1 = mean(prob.1),
            response = math_mode(response))

write_rds(test_forecasts, file = sprintf("output/predictions/%s_test_forecasts.rds", model_prefix))


#
#   Live forecast
#   ________________

fcast_preds <- dir("output/predictions", pattern = "[3-5]{1}_live", full.names = TRUE) %>%
  setNames(., nm = str_extract(., "mdl[0-9]{1}"))
fcast_preds <- fcast_preds %>% map_dfr(read_rds, .id = "model")
fcast <- fcast_preds %>%
  group_by(gwcode, country_name, year) %>%
  summarize(any_neg_change_2yr = unique(any_neg_change_2yr),
            prob.0 = mean(prob.0),
            prob.1 = mean(prob.1),
            response = math_mode(response))

write_rds(fcast, sprintf("output/predictions/%s_live_forecast.rds", model_prefix))

# write a csv version to the archive as well
fcast %>%
  mutate(for_years = paste0(year, " - ", year + 1),
         prob = prob.1) %>%
  select(gwcode, country_name, year, for_years, prob) %>%
  arrange(desc(prob)) %>%
  write_csv(here(sprintf("archive/forecasts-%s.csv", VERSION)))

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

source("scripts/assess-model.R")
