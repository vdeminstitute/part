#' ---
#' title: "Check high risk predictions in Europe"
#' author: "Andreas Beger"
#' date: "`r Sys.Date()`"
#' output:
#'   github_document: default
#' ---

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(vdemdata)
  library(ggplot2)
  library(here)
})

fcast <- read.csv(here::here("archive/forecasts-v12.csv"))
fcast <- fcast %>%
  mutate(rank = nrow(.) - rank(prob) + 1)

#' ## Load data

part <- read.csv(here::here("archive/part-v12.csv"))
part <- part %>%
  select(gwcode, year, country_name, lagged_v2x_regime, v2x_regime, any_neg_change)

vdem <- readRDS(here("create-data/input/V-Dem-CY-Full+Others-v12.rds"))
keep <- c("country_name", "year", "v2x_regime", "v2x_liberal", "v2cltrnslw_osp",
          "v2clacjstm_osp", "v2clacjstw_osp", "v2x_polyarchy", "v2elfrfair_osp",
          "v2elmulpar_osp")
vdem <- vdem[vdem$year > 1990, keep]

#' ## Helper functions

#' Some helper functions to make it easier to look at the data:
thresholds <- tibble(
  indicator = c("v2x_liberal", "v2cltrnslw_osp", "v2clacjstm_osp",
                "v2clacjstw_osp"),
  bar = c(.8, 3, 3, 3)
)

# Diagnostic plot showing the 4 indicators separating liberal from electoral
# democracy.
# data: vdem data
libdem_diagnostic <- function(country = "Portugal", data = vdem) {
  dat <- data[data$country_name==country, ]
  dat <- tail(dat, 6)
  dat <- dat %>%
    pivot_longer(v2x_liberal:v2clacjstw_osp, names_to = "indicator")

  dummy_data <- tibble(
    indicator = rep(c("v2x_liberal", "v2cltrnslw_osp", "v2clacjstm_osp",
                      "v2clacjstw_osp"), each = 2),
    year = 2015,
    value = c(0, 1, rep(c(0, 4), 3))
  )

  ggplot(dat, aes(x = year, y = value, color = indicator)) +
    geom_line() +
    facet_wrap(~indicator, scales = "free_y") +
    geom_blank(data = dummy_data) +
    geom_hline(data = thresholds, aes(yintercept = bar, color = indicator),
               linetype = 2) +
    theme_minimal() +
    theme(panel.border = element_rect(colour = "gray50", fill=NA, size=1)) +
    scale_color_discrete(guide = "none") +
    labs(x = NULL, y = NULL, title = country)
}

#' ## Analysis

part %>%
  filter(year==2021, any_neg_change==1) %>%
  arrange(country_name)

#' Austria, Ghana, Portugal, and Trinidad and Tobago all went from liberal
#' democracy (v2x_regime=3) to electoral democracy (v2x_regime=2).
#'
#' The conditions separating the liberal and electoral democracy regimes of the
#' worl (RoW) categories are based on 4 indicators. A country is a liberal,
#' not electoral democracy, if:
#'
#' ```
#' v2x_liberal > .8 AND
#' v2cltrnslw_osp > 3 AND
#' v2clacjstm_osp > 3 AND
#' v2clacjstw_osp > 3
#' ```
#'

libdem_diagnostic("Austria")
libdem_diagnostic("Ghana")

libdem_diagnostic("Portugal")
#' Portugal is just barely under on "access to justice for men". Not sure that
#' would survive a model re-run.

libdem_diagnostic("Trinidad and Tobago")

libdem2021 <- vdem %>% filter(year==2021, v2x_regime==3)
fcast %>%
  filter(country_name %in% libdem2021$country_name) %>%
  knitr::kable("simple")

#' Wow, that's a lot: 31 of the 33 liberal democracies in 2021 that are covered
#' by the forecasts (Seychelles are not) are at above average
#' risk for backsliding to electoral democracy.

mean(fcast$prob)

libdem_diagnostic("Uruguay")
libdem_diagnostic("Bhutan")
libdem_diagnostic("United States of America")
libdem_diagnostic("Sweden")
libdem_diagnostic("Finland")
libdem_diagnostic("New Zealand")
libdem_diagnostic("United Kingdom")
libdem_diagnostic("Switzerland")

# There are a large number of negative changes in 2021
part %>% group_by(year) %>% summarize(neg_change = sum(any_neg_change)) %>% tail()

part %>% group_by(year, lagged_v2x_regime) %>%
  summarize(countries = n(),
            neg_change = sum(any_neg_change, na.rm = TRUE),
            rate = neg_change/countries) %>%
  tail(12)

fcast_v11 <- fcast <- read.csv(here::here("archive/forecasts-v11.csv"))
mean(fcast$prob)
mean(fcast_v11$prob)

