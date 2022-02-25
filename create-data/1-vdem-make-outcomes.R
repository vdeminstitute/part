#
#   Code outcome variables using V-Dem data
#
#   Andreas Beger
#   2021-03-05
#
#   The original version of this script was written by Rick Morgan and called
#   "compose_VDem_regime_shift_data.R".
#
#   This script takes the raw V-Dem data and calculates the outcome data
#   for negative shifts in the regimes of the world classification, as well
#   as some history-related predictors.
#
#   Input: V-Dem-CY-Full+Others-vX.rds
#
#   Outputs: VDem-GW-regime-shift-data-1970on.csv
#            as well as signature files that provide quick summary stats
#            so that changes are easy to spot on git
#

# UPDATE: the first year of the 2-year period we want to forecast for
# Note that this is different from demspaces.
TARGET_YEAR <- 2022
VERSION     <- "v12"
# The V-Dem data we use as input; should be correct automatically with VERSION
VDEM_DATA <- sprintf("create-data/input/V-Dem-CY-Full+Others-%s.rds", VERSION)

library(dplyr)
library(tidyr)
library(RcppRoll)
library(states)
library(readr)
library(stringr)
library(forcats)
library(yaml)
library(here)

naCountFun <- function(dat, exclude_year){
  dat%>%
    filter(year < exclude_year)%>%
    sapply(function(x) sum(is.na(x)))%>%
    sort()
}

# We need a balanced data frame and we need to remove "problem" countries --
# countries that have a lot of missingness in the VDem data...
Vdem_raw <- read_rds(here::here(VDEM_DATA))
Vdem_complete <- Vdem_raw %>%
  filter(year >= 1900) %>%
  group_by(country_id) %>%
  tidyr::complete(country_id, year = min(year):TARGET_YEAR) %>%
  ungroup() %>%
  fill(country_name) %>%
  mutate(country_name = ifelse(country_id == 196, "Sao Tome and Principe",
                               country_name)) %>%
  filter(country_name != "Palestine/West Bank" & country_name != "Hong Kong" &
           country_name != "Bahrain" & country_name != "Malta") %>%
  data.frame(stringsAsFactors = FALSE)
dim(Vdem_complete)
## v9: 19513 obs. of 3888 variables
# v11: 19439 obs. of 4176 variables
# v12: 19618, 4170

## Create DV and related variables

# Is v2x_regime missing anywhere relevant?
Vdem_complete %>%
  filter(is.na(v2x_regime), year > 1968, year!=TARGET_YEAR) %>%
  select(country_id, year, country_name, v2x_regime) |>
  group_by(country_id, country_name) %>%
  summarize(years = paste0(range(year), collapse = " - ")) %>%
  as_tibble()
# v11: only South Yemen, id 23

VDem_regime_shift_data <- Vdem_complete %>%
  select(c(country_id, country_name, year, COWcode, codingstart_contemp,
           gapend1, v2x_regime, v2x_regime_amb))%>%
  group_by(country_id)%>%
  arrange(year) %>%
  mutate(
    lagged_v2x_regime = lag(v2x_regime, n = 1),

    any_neg_change = as.integer(v2x_regime < lagged_v2x_regime),
    lagged_any_neg_change = lag(any_neg_change, n = 1),

    # any neg change in this or next year?
    # neg change this year or next year
    any_neg_change_2yr = as.integer(any_neg_change==1 | lead(any_neg_change)==1),
    # a few countries like GDR 1990 ceased to exist; for those it's ok if we
    # only use last year's neg change even if year after that is not available
    last_year = case_when(
      country_name=="German Democratic Republic" ~ 1990L,
      country_name=="Republic of Vietnam" ~ 1975L,
      country_name=="South Yemen" ~ 1990L,
      TRUE ~ 9999L
    ),
    any_neg_change_2yr = ifelse(
      is.na(any_neg_change_2yr) & year==last_year,
      any_neg_change,
      any_neg_change_2yr
    ),
    last_year = NULL
  )

VDem_regime_shift_data <- VDem_regime_shift_data %>%
  mutate(lagged_v2x_regime_amb = lag(v2x_regime_amb, n = 1),

         low_border_case = ifelse(v2x_regime_amb == 2 | v2x_regime_amb == 5 | v2x_regime_amb == 8, 1, 0),
         low_border_case = ifelse(year == TARGET_YEAR, NA, low_border_case),
         lagged_low_border_case = lag(low_border_case, n = 1),

         high_border_case = ifelse(v2x_regime_amb == 1 | v2x_regime_amb == 4 | v2x_regime_amb == 7, 1, 0),
         high_border_case = ifelse(year == TARGET_YEAR, NA, high_border_case),
         lagged_high_border_case = lag(high_border_case, n = 1),

         # for the purpose of adding up neg changes, create a version without
         # NAs
         pos = ifelse(is.na(any_neg_change), 0, any_neg_change),
         num_of_neg_changes = cumsum(pos),
         pos = NULL,
         lagged_num_of_neg_changes = lag(num_of_neg_changes, n = 1),

         is_closed_autocracy = ifelse(v2x_regime == 0, 1, 0),
         lagged_is_closed_autocracy = lag(is_closed_autocracy),
         last_neg_change_yr = ifelse(any_neg_change == 1, year, NA),

         num_of_neg_changes_3yrs = roll_sumr(any_neg_change, n = 3),
         num_of_neg_changes_3yrs = ifelse(any_neg_change == 1 & is.na(num_of_neg_changes_3yrs), 1, num_of_neg_changes_3yrs),
         lagged_num_of_neg_changes_3yrs = lag(num_of_neg_changes_3yrs, n = 1),
         was_neg_change_last_3yrs = ifelse(num_of_neg_changes_3yrs > 0, 1, 0),
         lagged_was_neg_change_last_3yrs = lag(was_neg_change_last_3yrs, n = 1),

         num_of_neg_changes_5yrs = roll_sumr(any_neg_change, n = 5),
         num_of_neg_changes_5yrs = ifelse(any_neg_change == 1 & is.na(num_of_neg_changes_5yrs), 1, num_of_neg_changes_5yrs),
         lagged_num_of_neg_changes_5yrs = lag(num_of_neg_changes_5yrs, n = 1),
         was_neg_change_last_5yrs = ifelse(num_of_neg_changes_5yrs > 0, 1, 0),
         lagged_was_neg_change_last_5yrs = lag(was_neg_change_last_5yrs, n = 1),

         num_of_neg_changes_10yrs = roll_sumr(any_neg_change, n = 10),
         num_of_neg_changes_10yrs = ifelse(any_neg_change == 1 & is.na(num_of_neg_changes_10yrs), 1, num_of_neg_changes_10yrs),
         lagged_num_of_neg_changes_10yrs = lag(num_of_neg_changes_10yrs, n = 1),
         was_neg_change_last_10yrs = ifelse(num_of_neg_changes_10yrs > 0, 1, 0),
         lagged_was_neg_change_last_10yrs = lag(was_neg_change_last_10yrs, n = 1),

         codingstart_contemp = ifelse(year == TARGET_YEAR , TARGET_YEAR, codingstart_contemp), #| year == TARGET_YEAR - 1

         regime0 = ifelse(v2x_regime == 0, 1, 0),
         regime1 = ifelse(v2x_regime == 1, 1, 0),
         regime2 = ifelse(v2x_regime == 2, 1, 0),
         regime3 = ifelse(v2x_regime == 3, 1, 0),
         regime0startYear = ifelse((lag(regime0) == 0 | is.na(lag(regime0))) & regime0 == 1 & (lead(regime0) == 1 | lead(regime1) == 1 | lead(regime2) == 1 | lead(regime3) == 1), year, NA),
         regime1startYear = ifelse((lag(regime1) == 0 | is.na(lag(regime1))) & regime1 == 1 & (lead(regime1) == 1 | lead(regime0) == 1 | lead(regime2) == 1 | lead(regime3) == 1), year, NA),
         regime2startYear = ifelse((lag(regime2) == 0 | is.na(lag(regime2))) & regime2 == 1 & (lead(regime2) == 1 | lead(regime0) == 1 | lead(regime1) == 1 | lead(regime3) == 1), year, NA),
         regime3startYear = ifelse((lag(regime3) == 0 | is.na(lag(regime3))) & regime3 == 1 & (lead(regime3) == 1 | lead(regime0) == 1 | lead(regime1) == 1 | lead(regime2) == 1), year, NA))%>%
  fill(regime0startYear)%>%
  fill(regime1startYear)%>%
  fill(regime2startYear)%>%
  fill(regime3startYear)%>%
  fill(last_neg_change_yr)%>%
  mutate(yrs_since_any_neg_change = year - last_neg_change_yr,
         yrs_since_any_neg_change = ifelse(is.na(yrs_since_any_neg_change) & is.na(gapend1) & (!is.na(codingstart_contemp) & year != TARGET_YEAR), year - min(year), yrs_since_any_neg_change),

         regime0startYear = ifelse(regime1 == 1 | regime2 == 1 | regime3 == 1, NA, regime0startYear),
         regime1startYear = ifelse(regime0 == 1 | regime2 == 1 | regime3 == 1, NA, regime1startYear),
         regime2startYear = ifelse(regime0 == 1 | regime1 == 1 | regime3 == 1, NA, regime2startYear),
         regime3startYear = ifelse(regime0 == 1 | regime1 == 1 | regime2 == 1, NA, regime3startYear),

         regime0startYear = ifelse(is.na(regime0startYear) & is.na(regime1startYear) & is.na(regime2startYear) & is.na(regime3startYear) & regime0 == 1, year, regime0startYear),
         regime1startYear = ifelse(is.na(regime0startYear) & is.na(regime1startYear) & is.na(regime2startYear) & is.na(regime3startYear) & regime1 == 1, year, regime1startYear),
         regime2startYear = ifelse(is.na(regime0startYear) & is.na(regime1startYear) & is.na(regime2startYear) & is.na(regime3startYear) & regime2 == 1, year, regime2startYear),
         regime3startYear = ifelse(is.na(regime0startYear) & is.na(regime1startYear) & is.na(regime2startYear) & is.na(regime3startYear) & regime3 == 1, year, regime3startYear),

         regime0Duration = year - regime0startYear,
         regime0Duration = regime0Duration + 1,

         regime1Duration = year - regime1startYear,
         regime1Duration = regime1Duration + 1,

         regime2Duration = year - regime2startYear,
         regime2Duration = regime2Duration + 1,

         regime3Duration = year - regime3startYear,
         regime3Duration = regime3Duration + 1)%>%
  unite(col = currentRegimeDuration, regime0Duration, regime1Duration, regime2Duration, regime3Duration, remove = FALSE)%>%
  mutate(currentRegimeDuration = str_replace_all(currentRegimeDuration, "NA|_", ""),
         currentRegimeDuration = as.numeric(currentRegimeDuration),
         regime0Duration = ifelse(is.na(regime0Duration) & year == TARGET_YEAR & year != min(year), 0, regime0Duration),
         regime1Duration = ifelse(is.na(regime1Duration) & year == TARGET_YEAR & year != min(year), 0, regime1Duration),
         regime2Duration = ifelse(is.na(regime2Duration) & year == TARGET_YEAR & year != min(year), 0, regime2Duration),
         regime3Duration = ifelse(is.na(regime3Duration) & year == TARGET_YEAR & year != min(year), 0, regime3Duration),
         lagged_currentRegimeDuration = lag(currentRegimeDuration, n = 1),
         lagged_regime0Duration = lag(regime0Duration, n = 1),
         lagged_regime1Duration = lag(regime1Duration, n = 1),
         lagged_regime2Duration = lag(regime2Duration, n = 1),
         lagged_regime3Duration = lag(regime3Duration, n = 1),
         lagged_regime0Duration = ifelse(is.na(lagged_regime0Duration) & (!is.na(lagged_regime1Duration) | !is.na(lagged_regime2Duration) | !is.na(lagged_regime3Duration)), 0, lagged_regime0Duration),
         lagged_regime1Duration = ifelse(is.na(lagged_regime1Duration) & (!is.na(lagged_regime0Duration) | !is.na(lagged_regime2Duration) | !is.na(lagged_regime3Duration)), 0, lagged_regime1Duration),
         lagged_regime2Duration = ifelse(is.na(lagged_regime2Duration) & (!is.na(lagged_regime0Duration) | !is.na(lagged_regime1Duration) | !is.na(lagged_regime3Duration)), 0, lagged_regime2Duration),
         lagged_regime3Duration = ifelse(is.na(lagged_regime3Duration) & (!is.na(lagged_regime0Duration) | !is.na(lagged_regime1Duration) | !is.na(lagged_regime2Duration)), 0, lagged_regime3Duration))%>%
  ungroup()%>%
  arrange(country_id, year)%>%
  mutate(v2x_regime_asCharacter = ifelse(v2x_regime == 0, "Closed Autocracy",
                                         ifelse(v2x_regime == 1, "Electoral Autocracy",
                                                ifelse(v2x_regime == 2, "Electoral Democracy",
                                                       ifelse(v2x_regime == 3, "Liberal Democracy", NA)))),
         v2x_regime_asFactor =  as_factor(v2x_regime_asCharacter),

         lagged_v2x_regime_asCharacter = ifelse(lagged_v2x_regime == 0, "Closed Autocracy",
                                                ifelse(lagged_v2x_regime == 1, "Electoral Autocracy",
                                                       ifelse(lagged_v2x_regime == 2, "Electoral Democracy",
                                                              ifelse(lagged_v2x_regime == 3, "Liberal Democracy", NA)))),
         lagged_v2x_regime_asFactor =  as_factor(lagged_v2x_regime_asCharacter),
         gwcode = as.integer(COWcode),
         gwcode = case_when(gwcode == 255 ~ 260L,
                            gwcode == 679 ~ 678L,
                            gwcode == 345 &
                              year >= 2006 ~ 340L,
                            TRUE ~ gwcode))%>%
  fill(gwcode)%>%
  filter(year >= 1969 & !is.na(codingstart_contemp))%>%
  group_by(gwcode)%>%
  arrange(year)%>%
  mutate(yrs_since_any_neg_change = ifelse(is.na(yrs_since_any_neg_change), year - min(year), yrs_since_any_neg_change),
         yrs_since_any_neg_change = ifelse(gwcode == 345, year - 1900, yrs_since_any_neg_change),
         lagged_yrs_since_any_neg_change = lag(yrs_since_any_neg_change, n = 1),
         lagged_yrs_since_any_neg_change = ifelse(gwcode == 345 & year == 1970, 69, lagged_yrs_since_any_neg_change),
         lagged_yrs_since_any_neg_change = ifelse(is.na(lagged_yrs_since_any_neg_change), 0, lagged_yrs_since_any_neg_change),
         lagged_yrs_since_any_neg_change = ifelse(gwcode == 366 & year == 1992, 2, lagged_yrs_since_any_neg_change),
         lagged_yrs_since_any_neg_change = ifelse(gwcode == 367, year - 1990, lagged_yrs_since_any_neg_change),
         lagged_yrs_since_any_neg_change = ifelse(gwcode == 368 & year <= 2016, year - 1990, lagged_yrs_since_any_neg_change),
         lagged_yrs_since_any_neg_change = ifelse(gwcode == 541, year - 1975, lagged_yrs_since_any_neg_change),
         drop = ifelse((year == TARGET_YEAR | !is.na(any_neg_change)), 0, 1))%>%
  fill(lagged_num_of_neg_changes, .direction = "up")%>%
  fill(lagged_any_neg_change, .direction = "up")%>%
  ungroup()%>%
  arrange(gwcode, year)%>%
  filter(year >= 1970 & !is.na(lagged_v2x_regime) & drop == 0)%>%
  select(c(gwcode, year, country_name, country_id, any_neg_change, any_neg_change_2yr, v2x_regime,
           v2x_regime_amb, lagged_v2x_regime, lagged_v2x_regime_amb, lagged_v2x_regime_asCharacter, lagged_v2x_regime_asFactor, lagged_is_closed_autocracy,
           lagged_currentRegimeDuration, lagged_low_border_case, lagged_high_border_case, lagged_yrs_since_any_neg_change, lagged_num_of_neg_changes,
           lagged_any_neg_change, lagged_num_of_neg_changes_3yrs, lagged_num_of_neg_changes_5yrs, lagged_num_of_neg_changes_10yrs, lagged_was_neg_change_last_3yrs,
           lagged_was_neg_change_last_5yrs, lagged_was_neg_change_last_10yrs))%>%
  data.frame()

dim(VDem_regime_shift_data)
# v9:  8205 obs. of 26 variables
# v11: 8555 obs. of 26 variables
# v12: 8751, 25
#
# naCountFun(VDem_regime_shift_data, TARGET_YEAR + 1)
# naCountFun(VDem_regime_shift_data, TARGET_YEAR)
## The NAs that remain in the "last_Xyrs" variables are all due to the start of new series after 1970... We fix these after we merge v-dem with gw

##########################################
## Joining VDem data to the GW state set
##########################################


## GW_template is a balanced gwcode yearly data frame from 1970 to 2018. Need to drop microstates. We get this from the states package
keep <- gwstates$gwcode[gwstates$microstate == FALSE]
GW_template <- state_panel(1970, TARGET_YEAR, partial = "any", useGW = TRUE) %>%
  filter(gwcode %in% keep)
dim(GW_template)
# v9:  8074 obs. of  2 variables
# v11: 8422 obs. of 2 variables
# v12: 8596, 2

VDem_GW_regime_shift_data <- GW_template%>%
  left_join(VDem_regime_shift_data)%>%
  group_by(gwcode)%>%
  fill(country_name, .direction = "down")%>%
  fill(country_name, .direction = "up")%>%
  fill(country_id, .direction = "down")%>%
  fill(country_id, .direction = "up")%>%
  fill(any_neg_change, .direction = "up")%>%
  fill(any_neg_change_2yr, .direction = "up")%>%
  fill(v2x_regime, .direction = "up")%>%
  fill(v2x_regime_amb, .direction = "up")%>%
  fill(lagged_v2x_regime, .direction = "up")%>%
  fill(lagged_v2x_regime_amb, .direction = "up")%>%
  fill(lagged_v2x_regime_asCharacter, .direction = "up")%>%
  fill(lagged_v2x_regime_asFactor, .direction = "up")%>%
  fill(lagged_is_closed_autocracy, .direction = "up")%>%
  fill(lagged_currentRegimeDuration, .direction = "up")%>%
  fill(lagged_low_border_case, .direction = "up")%>%
  fill(lagged_high_border_case, .direction = "up")%>%
  fill(lagged_yrs_since_any_neg_change, .direction = "up")%>%
  fill(lagged_num_of_neg_changes, .direction = "up")%>%
  fill(lagged_any_neg_change, .direction = "up")%>%
  mutate(any_neg_change = ifelse(country_name == "Estonia" & year == 1991, 0, any_neg_change),
         lagged_num_of_neg_changes_3yrs = ifelse(country_name == "Estonia" & year == 1992, 0, lagged_num_of_neg_changes_3yrs),

         lagged_num_of_neg_changes_5yrs = ifelse(country_name == "Estonia" & year == 1992, 0, lagged_num_of_neg_changes_5yrs),
         lagged_num_of_neg_changes_5yrs = ifelse(country_name == "Bangladesh" & year == 1975, 0, lagged_num_of_neg_changes_5yrs),

         lagged_num_of_neg_changes_10yrs = ifelse(country_name == "Montenegro" & year == 2007, 0, lagged_num_of_neg_changes_10yrs),
         lagged_num_of_neg_changes_10yrs = ifelse(country_name == "Macedonia" & year == 2000, 0, lagged_num_of_neg_changes_10yrs),
         lagged_num_of_neg_changes_10yrs = ifelse(country_name == "Estonia" & year == 1992, 0, lagged_num_of_neg_changes_10yrs),
         lagged_num_of_neg_changes_10yrs = ifelse(country_name == "Ukraine" & year == 1998, 0, lagged_num_of_neg_changes_10yrs),
         lagged_num_of_neg_changes_10yrs = ifelse(country_name == "Belarus" & year == 1996, 0, lagged_num_of_neg_changes_10yrs),
         lagged_num_of_neg_changes_10yrs = ifelse(country_name == "Armenia" & year == 1996, 0, lagged_num_of_neg_changes_10yrs),
         lagged_num_of_neg_changes_10yrs = ifelse(country_name == "Bangladesh" & year == 1975, 0, lagged_num_of_neg_changes_10yrs),
         lagged_num_of_neg_changes_10yrs = ifelse(country_name == "South Sudan" & year == 2018, 0, lagged_num_of_neg_changes_10yrs),

         lagged_was_neg_change_last_3yrs = ifelse(country_name == "Estonia" & year == 1992, 0, lagged_was_neg_change_last_3yrs),

         lagged_was_neg_change_last_5yrs = ifelse(country_name == "Estonia" & year == 1992, 0, lagged_was_neg_change_last_5yrs),
         lagged_was_neg_change_last_5yrs = ifelse(country_name == "Bangladesh" & year == 1975, 0, lagged_was_neg_change_last_5yrs),

         lagged_was_neg_change_last_10yrs = ifelse(country_name == "Montenegro" & year == 2007, 0, lagged_was_neg_change_last_10yrs),
         lagged_was_neg_change_last_10yrs = ifelse(country_name == "Macedonia" & year == 2000, 0, lagged_was_neg_change_last_10yrs),
         lagged_was_neg_change_last_10yrs = ifelse(country_name == "Estonia" & year == 1992, 0, lagged_was_neg_change_last_10yrs),
         lagged_was_neg_change_last_10yrs = ifelse(country_name == "Ukraine" & year == 1998, 0, lagged_was_neg_change_last_10yrs),
         lagged_was_neg_change_last_10yrs = ifelse(country_name == "Belarus" & year == 1996, 0, lagged_was_neg_change_last_10yrs),
         lagged_was_neg_change_last_10yrs = ifelse(country_name == "Armenia" & year == 1996, 0, lagged_was_neg_change_last_10yrs),
         lagged_was_neg_change_last_10yrs = ifelse(country_name == "Bangladesh" & year == 1975, 0, lagged_was_neg_change_last_10yrs),
         lagged_was_neg_change_last_10yrs = ifelse(country_name == "South Sudan" & year == 2018, 0, lagged_was_neg_change_last_10yrs))%>%
  fill(lagged_num_of_neg_changes_3yrs, .direction = "up")%>%
  fill(lagged_num_of_neg_changes_5yrs, .direction = "up")%>%
  fill(lagged_num_of_neg_changes_10yrs, .direction = "up")%>%
  fill(lagged_num_of_neg_changes_10yrs, .direction = "down")%>%
  fill(lagged_was_neg_change_last_3yrs, .direction = "up")%>%
  fill(lagged_was_neg_change_last_5yrs, .direction = "up")%>%
  fill(lagged_was_neg_change_last_10yrs, .direction = "up")%>%
  fill(lagged_was_neg_change_last_10yrs, .direction = "down")%>%
  ungroup()%>%
  data.frame(stringsAsFactors = FALSE)

non_in_vdem <- unique(VDem_GW_regime_shift_data$gwcode[is.na(VDem_GW_regime_shift_data$country_name)])
gwstates[gwstates$gwcode %in% non_in_vdem, ]
VDem_GW_regime_shift_data <- VDem_GW_regime_shift_data%>%
  filter(!(gwcode %in% non_in_vdem))%>%
  filter(!is.na(lagged_v2x_regime))

dim(VDem_GW_regime_shift_data)
# v9:  7923 obs. of 26 variables:
# v11: 8190 obs. of 26 variables:
# v12: 8359, 25
naCountFun(VDem_GW_regime_shift_data, TARGET_YEAR + 1)
naCountFun(VDem_GW_regime_shift_data, TARGET_YEAR)


# Record signature and write out ------------------------------------------


data_signature <- function(df) {
  out <- list()
  out$Class <- paste(class(df), collapse = ", ")
  out$Size_in_mem <- format(utils::object.size(df), "Mb")
  out$N_countries <- length(unique(df$gwcode))
  out$Years <- paste0(range(df$year, na.rm = TRUE), collapse = " - ")
  out$N_columns <- ncol(df)
  out$N_rows <- nrow(df)
  out$N_complete_rows <- sum(stats::complete.cases(df))
  out$Countries <- length(unique(df$gwcode))
  out$Sum_any_neg_change <- as.integer(sum(df$any_neg_change, na.rm = TRUE))
  out$Sum_any_neg_change_2yr <- as.integer(sum(df$any_neg_change_2yr, na.rm = TRUE))
  out$Columns <- as.list(colnames(df))
  out
}
sig <- data_signature(VDem_GW_regime_shift_data)

# Write both versioned and clean file name so that:
# - easy to see changes on git with clean file name
# - concise historical record with versioned file name
write_yaml(sig, here(sprintf("create-data/output/regime-shift-%s-signature.yml",
                        VERSION)))
write_yaml(sig, here("create-data/output/regime-shift-signature.yml"))

# Record ART cases so changes are easier to ID
art_cases <- VDem_GW_regime_shift_data %>%
  filter(any_neg_change==1) %>%
  select(year, country_name) %>%
  arrange(year, country_name)
write_csv(art_cases, here::here("create-data/output/art-cases.csv"))

# Ok, now write the actually important output
write_csv(VDem_GW_regime_shift_data, here("create-data/output/regime-shift-data-1970on.csv"))


