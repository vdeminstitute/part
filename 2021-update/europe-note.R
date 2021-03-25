#' ---
#' title: "Europe note"
#' author: "Andreas Beger"
#' date: "`r Sys.Date()`"
#' output:
#'   github_document: default
#' ---

#' Several countries in Europe as well as Canada have high values for the risk
#' of an adverse regime transition (ART) in 2021-2022. In Europe these including
#' "surprising" countries like Norway and Denmark, which rank at 11 and 15,
#' respectively.
#'
#' Are these indicative for mistakes or shortcomings in the PART forecast model,
#' or do they appear to be legitimately high risk cases?
#'
#' (And one should note that although ranking high in terms of relative risk,
#' the actual estimated probabilities of an ART are still relatively low,
#' 16 - 11% for the 5 cases I will look at in more detail below)

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(vdemdata)
  library(ggplot2)
  library(here)
})

fcast <- read.csv(here::here("archive/forecasts-v11.csv"))
fcast <- fcast %>%
  mutate(rank = nrow(.) - rank(prob) + 1)

part <- read.csv(here::here("archive/part-v11.csv"))
part <- part %>%
  select(gwcode, year, country_name, lagged_v2x_regime, v2x_regime, any_neg_change)

vdem <- readRDS(here("create-data/input/V-Dem-CY-Full+Others-v11.rds"))
keep <- c("country_name", "year", "v2x_regime", "v2x_liberal", "v2cltrnslw_osp",
          "v2clacjstm_osp", "v2clacjstw_osp", "v2x_polyarchy", "v2elfrfair_osp",
          "v2elmulpar_osp")
vdem <- vdem[vdem$year > 1990, keep]

#' Looking at the forecasts, there are several European countries that rank
#' relatively highly in the forecasts for 2021-2022. Does this make sense?

fcast$rank[fcast$country_name %in% c("Norway", "Denmark", "Italy", "Slovenia",
                                     "Canada")]
fcast$prob[fcast$country_name %in% c("Norway", "Denmark", "Italy", "Slovenia",
                                     "Canada")]

#' ## Were there similar cases with actual ARTs in 2020?
#'
#' For 2020 we already have observed cases of ARTs. Were any of them in Europe?
#'
#' In 2020 there were observed adverse regime transitions (ARTs) in 4 countries:
#' Czech Republic, Portugal, Ivory Coast, and Slovenia.
part %>%
  filter(year==2020, any_neg_change==1)

#' CR, Portugal and Slovenia all went from liberal democracy (v2x_regime=3) to
#' electoral democracy (v2x_regime=2).
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
    scale_color_discrete(guide = FALSE) +
    labs(x = NULL, y = NULL, title = country)
}

#' Show the critical data for the 3 European cases that had an ART in 2020.
#' In the plots, the dotted lines indicate the points below which a regime
#' goes from liberal to electoral democracy.
libdem_diagnostic("Slovenia")
libdem_diagnostic("Portugal")
libdem_diagnostic("Czech Republic")

#' All three European cases were due to decreases in the transparent laws with
#' predictable enforcement index (`v2cltrnslw_osp`). Portugal went from 3.7 to
#' 2.9, Slovenia 3.3 to 2.7, and Czech Republic from 3 to 2.5.
var_info("v2cltrnslw")[c("name", "question")]

#' Ivory Coast went from electoral to closed democracy; not relevant for
#' Denmark & co so I won't dig in.
#'
#' ## Re-check 2021-2022 "surprising" high forecasts
#'
#' Let's turn back to the cases that I wanted to check.
#'
#' ### Norway
#'

libdem_diagnostic("Norway")
vdem %>% filter(country_name=="Norway") %>% tail(6)

#' Norway's access to justice for women went from 3.7 to 3.1 in 2019.

var_info("v2clacjstw")[c("name", "question")]
var_info("v2clacjstm")[c("name", "question")]

#'
#' ### Denmark
#'

libdem_diagnostic("Denmark")
vdem %>% filter(country_name=="Denmark") %>% tail(6)

#' Denmark's transparent laws index went from 3.9 to 3.2 in 2020.

#'
#' ### Italy
#'
libdem_diagnostic("Italy")
vdem %>% filter(country_name=="Italy") %>% tail(6)

#' Italy has been low for a while on the transparent law index, with a value of
#' 3.1.
#'

#'
#' ### Canada
#'
libdem_diagnostic("Canada")
vdem %>% filter(country_name=="Canada") %>% tail(6)

#' Recent decreases in both the liberal democracy index and access to justice
#' for women indices; either of those could put Canada over the threshold for
#' dropping to electoral democracy.
#'

#'
#' ### Slovenia
#'
#' Slovenia already went to electoral dem in 2020. Now the risk is about further
#' going to electoral autocracy.
#'
#' For 2020, Hungary, Montenegro, and Serbia are coded as electoral democracies,
#' so in a basic sense this doesn't seem outside of the realm of the possible.
vdem %>% filter(year==2020) %>%
  filter(country_name %in% c("Poland", "Hungary", "Slovenia", "Serbia",
                             "Montenegro", "Bosnia and Herzegovina")) %>%
  select(country_name, year, v2x_regime)

#' Any of these three indicators put us on the path to autocracy. The thresholds
#' are 0.5 for polyarchy and 2 for the others.
vdem %>%
  filter(country_name=="Slovenia", year %in% c(2015:2020)) %>%
  select(v2x_polyarchy, v2elfrfair_osp, v2elmulpar_osp)
#' Missing values aside (which we carry forward impute in the PART data),
#' does not really seem like Slovenia is very close on any of these.


#' In the three cases for 2021-2022 that are subject to moving from liberal
#' to electoral democracy--Norway, Denmark, and Italy--one of the indicators
#' that could push a country across the categories is approaching the relevant
#' threshold.
#'
#' The other country I wanted to check, Slovenia, already had an ART in 2020,
#' going to electoral democracy. It would now be at risk of going to electoral
#' autocracy. It doesn't really seem very close on any of the 3 indices that
#' could push it down; but on the other hand also not very far away.
#'
#' Overall, it seems that the high forecasts, although maybe surprising, are
#' not the result of some kind of error.
#'
