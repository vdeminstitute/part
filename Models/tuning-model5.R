#' ---
#' title: "xgboost (model 5) tuning results"
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


res <- readRDS(here("Models/output/tuning/model5-tuning.rds"))
# Total number of tuning samples
print(nrow(res))

res %>%
  pivot_longer(nrounds:alpha, names_to = "hp", values_to = "hp_val") %>%
  # filter out HP that are constant, i.e. not being tuned
  group_by(hp) %>%
  filter(length(unique(hp_val)) > 1) %>%
  ungroup() %>%
  pivot_longer(Brier:time, names_to = "measure", values_to = "m_val") %>%
  ggplot(aes(x = hp_val, y = m_val, group = interaction(hp, measure))) +
  facet_grid(measure ~ hp, scales = "free") +
  geom_point() +
  geom_smooth() +
  theme_minimal() +
  labs(y = "Accuracy measure value", x = "HP value") +
  theme(panel.border = element_rect(colour = "black", fill=NA, size=1))

res %>%
  filter(nrounds > 25, max_delta_step > .5,
         eta > .1, eta < .6,
         min_child_weight > 1) %>%
  pivot_longer(nrounds:alpha, names_to = "hp", values_to = "hp_val") %>%
  # filter out HP that are constant, i.e. not being tuned
  group_by(hp) %>%
  filter(length(unique(hp_val)) > 1) %>%
  ungroup() %>%
  pivot_longer(Brier:time, names_to = "measure", values_to = "m_val") %>%
  ggplot(aes(x = hp_val, y = m_val, group = interaction(hp, measure))) +
  facet_grid(measure ~ hp, scales = "free") +
  geom_point() +
  geom_smooth() +
  theme_minimal() +
  labs(y = "Accuracy measure value", x = "HP value") +
  theme(panel.border = element_rect(colour = "black", fill=NA, size=1))
