#' ---
#' title: "Tuning results for random forest (model 4)"
#' date: "`r format(Sys.Date())`"
#' output:
#'   github_document
#' ---


suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(tidyr)
  library(here)
})


res <- readRDS(here("Models/output/tuning/model4-tuning.rds"))

res %>%
  select(-row) %>%
  pivot_longer(num.trees:sample.fraction, names_to = "hp", values_to = "hp_val") %>%
  pivot_longer(Brier:AUC_PR, names_to = "measure", values_to = "m_val") %>%
  ggplot(aes(x = hp_val, y = m_val, group = interaction(hp, measure))) +
  facet_grid(measure ~ hp, scales = "free") +
  geom_point() +
  geom_smooth() +
  theme_minimal() +
  theme(panel.border = element_rect(colour = "black", fill=NA, size=1))

# Prior to v11, num.trees and mtry were tuned using a self-tuning model
# (`mlr`'s `TuneWrapper`).
#
# Let's zoom in by discarding obviously non-optimal settings, like low mtry
#

res %>%
  filter(mtry > 45,
         sample.fraction > .7,
         num.trees > 1500) %>%
  select(-row) %>%
  pivot_longer(num.trees:sample.fraction, names_to = "hp", values_to = "hp_val") %>%
  pivot_longer(Brier:AUC_PR, names_to = "measure", values_to = "m_val") %>%
  ggplot(aes(x = hp_val, y = m_val, group = interaction(hp, measure))) +
  facet_grid(measure ~ hp, scales = "free") +
  geom_point() +
  geom_smooth() +
  theme_minimal() +
  theme(panel.border = element_rect(colour = "black", fill=NA, size=1))
