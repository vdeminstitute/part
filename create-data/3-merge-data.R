#
#   Merge data to produce part-vX.csv
#
#   Andreas Beger
#   2021-03-05
#
#   Pull all external data together;
#   this is all the stuff in input, which should be GW normalized already
#   output is in ... output
#


packs <- c("tidyverse", "rio", "states", "vfcast", "mlr")
# install.packages(packs, dependencies = TRUE)
lapply(packs, library, character.only = TRUE)

setwd(vpath("Data/v9"))

source("../../regime-forecast/R/functions.R")

plotmiss <- function(x) {
  x$date <- as.Date(paste0(x$year, "-12-31"))
  plot_missing(x, names(x), "gwcode", "date", "year", "GW", partial = "any")
}

# Which year should the data reach to?
TARGET_YEAR <- 2019
TARGET <- "any_neg_change"
lag_n <- 1

#
#   EPR ----
#   ______________

epr_dat <- import("input/epr-yearly.csv") %>%
  select(-date) %>%
  filter(year < TARGET_YEAR) %>%
  mutate(year = year + TARGET_YEAR - max(year))
names(epr_dat)[-c(1:2)] <- paste("lagged_", names(epr_dat)[-c(1:2)], sep = "")
str(epr_dat)

plotmiss(epr_dat)

#
#   GDP ----
#   __________________

gdp_dat <- import("input/gdp_1950_2017.csv") %>%
  select(-date) %>%
  filter(year < TARGET_YEAR) %>%
  dplyr::rename(gdp = NY.GDP.MKTP.KD,
                gdp_growth = NY.GDP.MKTP.KD.ZG,
                gdp_pc = NY.GDP.PCAP.KD,
                gdp_pc_growth = NY.GDP.PCAP.KD.ZG) %>%
  mutate(year = year + TARGET_YEAR - max(year),
        gdp_log = log(gdp),
        gdp_pc_log = log(gdp_pc))
names(gdp_dat)[-c(1:2)] <- paste("lagged_", names(gdp_dat)[-c(1:2)], sep = "")
str(gdp_dat)

plotmiss(gdp_dat)

#
#   State age ----
#   ________________________

age_dat <- import("input/gwstate-age.csv") %>%
  filter(year < TARGET_YEAR) %>%
  mutate(year = year + TARGET_YEAR - max(year))
names(age_dat)[-c(1:2)] <- paste("lagged_", names(age_dat)[-c(1:2)], sep = "")
str(age_dat)

plotmiss(age_dat)


#
#   Population ----
#   ___________

pop_dat <- import("input/population.csv") %>%
  filter(year < TARGET_YEAR) %>%
  mutate(year = year + pmax(0, TARGET_YEAR - max(year))) %>%
  # log this sucker
  mutate(pop = log(pop))
names(pop_dat)[-c(1:2)] <- paste("lagged_", names(pop_dat)[-c(1:2)], sep = "")
str(pop_dat)

plotmiss(pop_dat)


#
#   Coups ----
#   __________

coup_dat <- import("input/ptcoups.csv") %>%
  filter(year < TARGET_YEAR) %>%
  select(-c(date, pt_failed_coup_attempt_total, pt_failed_coup_attempt_num5yrs, pt_failed_coup_attempt_num10yrs))%>%
  mutate(year = year + TARGET_YEAR - max(year))
names(coup_dat)[-c(1:2)] <- paste("lagged_", names(coup_dat)[-c(1:2)], sep = "")
str(coup_dat)

plotmiss(coup_dat)


#
#   ACD ----
#   ______

acd_dat <- import("input/acd.csv") %>%
  filter(year < TARGET_YEAR) %>%
  select(gwcode, year, everything()) %>%
  mutate(year = year + pmax(0, TARGET_YEAR - max(year)))
names(acd_dat)[-c(1:2)] <- paste("lagged_", names(acd_dat)[-c(1:2)], sep = "")
str(acd_dat)

plotmiss(acd_dat)


#
#   WDI infmort ----
#   ______


infmort <- import("input/wdi-infmort.csv") %>%
  filter(year < TARGET_YEAR) %>%
  select(gwcode, year, everything()) %>%
  mutate(year = year + pmax(0, TARGET_YEAR - max(year)))
names(infmort)[-c(1:2)] <- paste("lagged_", names(infmort)[-c(1:2)], sep = "")
str(infmort)

plotmiss(infmort)


#
#   WDI ICT ----
#   ______


ict <- import("input/wdi-ict.csv") %>%
  filter(year < TARGET_YEAR) %>%
  select(gwcode, year, everything()) %>%
  mutate(year = year + pmax(0, TARGET_YEAR - max(year)))
names(ict)[-c(1:2)] <- paste("lagged_", names(ict)[-c(1:2)], sep = "")
str(ict)

plotmiss(ict)


#
#   V-Dem ----
#   ___________

## All observations we have a DV for...
# VDem_GW_regime_shift_data <- import("input/VDem_GW_data_final_USE.csv")
VDem_GW_regime_shift_data <- import("input/VDem_GW_data_final_USE_2yr_target_v9.csv")
str(VDem_GW_regime_shift_data) ## 'data.frame':  7923 obs. of  408
# naCountFun(VDem_GW_regime_shift_data, TARGET_YEAR)
naCountFun(VDem_GW_regime_shift_data, TARGET_YEAR + 1)

VDem_GW_regime_shift_data <- VDem_GW_regime_shift_data %>%
  mutate(lagged_v2x_regime_amb = as.factor(lagged_v2x_regime_amb)) %>%
  createDummyFeatures(., cols = "lagged_v2x_regime_amb")

# here it's ok if we have up to target year
range(VDem_GW_regime_shift_data$year)
if (max(VDem_GW_regime_shift_data$year)!=TARGET_YEAR) stop("something wrong with VDem")
plotmiss(VDem_GW_regime_shift_data)

# missing y should only be for last year
VDem_GW_regime_shift_data %>%
  # filter out countries that are entirely missing
  group_by(gwcode) %>%
  mutate(n_miss_y = sum(is.na(any_neg_change_2yr))) %>%
  filter(n_miss_y!=n()) %>%
  # remainder should be missing for last years only
  group_by(year) %>%
  summarize(n_miss_y = sum(is.na(any_neg_change_2yr)),
            n = n()) %>%
  filter(n_miss_y > 0)



#
#   Join all ----
#   ____________

###########################
# Create master template

## GW_template is a balanced gwcode yearly data frame from 1970 to 2018. Need to drop microstates.
drop <- gwstates$gwcode[gwstates$microstate == TRUE]
GW_template <- state_panel(as.Date("1970-01-01"), as.Date(paste0(TARGET_YEAR, "-01-01")), by = "year", partial = "any", useGW = TRUE)%>%
  mutate(year = lubridate::year(date), date = NULL)%>%
  filter(!(gwcode %in% drop))

## after the merge, all of the NAs that remain are from the external datasets. It looks like it is the first year in each series. We will need to back fill these variables...
VDem_GW_regime_shift_external_data <- VDem_GW_regime_shift_data %>%
  left_join(GW_template) %>%
  left_join(epr_dat) %>%
  left_join(gdp_dat) %>%
  left_join(age_dat) %>%
  left_join(pop_dat) %>%
  left_join(coup_dat) %>%
  left_join(acd_dat) %>%
  # 2019-04-12 AB: couple of countries, mainly Taiwan and Kosovo, are missing values
  #left_join(infmort) %>%
  #left_join(ict) %>%
  group_by(gwcode) %>%
  arrange(year) %>%
  fill(lagged_pop, .direction = "up")%>%
  fill(lagged_state_age, .direction = "up")%>%
  fill(lagged_pt_coup_attempt, .direction = "up")%>%
  fill(lagged_pt_coup_attempt_num, .direction = "up")%>%
  fill(lagged_pt_coup_num, .direction = "up")%>%
  fill(lagged_pt_coup, .direction = "up")%>%
  fill(lagged_pt_failed_coup_attempt_num, .direction = "up")%>%
  fill(lagged_pt_failed_coup_attempt, .direction = "up")%>%
  fill(lagged_pt_coup_total, .direction = "up")%>%
  fill(lagged_pt_coup_attempt_total, .direction = "up")%>%
  fill(lagged_pt_coup_num5yrs, .direction = "up")%>%
  fill(lagged_pt_coup_attempt_num5yrs, .direction = "up")%>%
  fill(lagged_pt_coup_num10yrs, .direction = "up")%>%
  fill(lagged_pt_coup_attempt_num10yrs, .direction = "up")%>%
  fill(lagged_years_since_last_pt_coup, .direction = "up")%>%
  fill(lagged_years_since_last_pt_failed_coup_attempt, .direction = "up")%>%
  fill(lagged_years_since_last_pt_coup_attempt, .direction = "up")%>%
  fill(lagged_gdp, .direction = "up")%>%
  fill(lagged_gdp_growth, .direction = "up")%>%
  fill(lagged_gdp_pc_growth, .direction = "up")%>%
  fill(lagged_gdp_log, .direction = "up")%>%
  fill(lagged_epr_groups, .direction = "up")%>%
  fill(lagged_epr_elf, .direction = "up")%>%
  fill(lagged_epr_excluded_groups_count, .direction = "up")%>%
  fill(lagged_epr_excluded_group_pop, .direction = "up")%>%
  fill(lagged_epr_inpower_groups_count, .direction = "up")%>%
  fill(lagged_epr_inpower_groups_pop, .direction = "up")%>%
  fill(lagged_epr_regaut_groups_count, .direction = "up")%>%
  fill(lagged_epr_regaut_group_pop, .direction = "up")%>%
  fill(lagged_gdp_pc, .direction = "up")%>%
  fill(lagged_gdp_pc_log , .direction = "up")%>%
  fill(lagged_pop, .direction = "down")%>%
  fill(lagged_pt_coup_attempt, .direction = "down")%>%
  fill(lagged_pt_coup_attempt_num, .direction = "down")%>%
  fill(lagged_pt_coup_num, .direction = "down")%>%
  fill(lagged_pt_coup, .direction = "down")%>%
  fill(lagged_pt_failed_coup_attempt_num, .direction = "down")%>%
  fill(lagged_pt_failed_coup_attempt, .direction = "down")%>%
  fill(lagged_pt_coup_total, .direction = "down")%>%
  fill(lagged_pt_coup_attempt_total, .direction = "down")%>%
  fill(lagged_pt_coup_num5yrs, .direction = "down")%>%
  fill(lagged_pt_coup_attempt_num5yrs, .direction = "down")%>%
  fill(lagged_pt_coup_num10yrs, .direction = "down")%>%
  fill(lagged_pt_coup_attempt_num10yrs, .direction = "down")%>%
  fill(lagged_years_since_last_pt_coup, .direction = "down")%>%
  fill(lagged_years_since_last_pt_failed_coup_attempt, .direction = "down")%>%
  fill(lagged_years_since_last_pt_coup_attempt, .direction = "down")%>%
  mutate(lagged_state_age = ifelse(is.na(lagged_state_age) & country_name == "South Yemen", max(lagged_state_age, na.rm = TRUE) + 1, lagged_state_age),
         lagged_state_age = ifelse(is.na(lagged_state_age) & country_name == "Republic of Vietnam", max(lagged_state_age, na.rm = TRUE) + 1, lagged_state_age),
         lagged_state_age = ifelse(is.na(lagged_state_age) & country_name == "German Democratic Republic", max(lagged_state_age, na.rm = TRUE) + 1, lagged_state_age))%>%
  # ACD
  fill(., starts_with("lagged_internal_confl"), starts_with("lagged_war"),
       starts_with("lagged_any_conflict"), starts_with("lagged_ext_conf"),
       .direction = "up") %>%
  # Infmort
  fill(., starts_with("lagged_SP.DYN.IMRT"),
       .direction = "up") %>%
  # ICT
  fill(., starts_with("lagged_IT.NET"), starts_with("lagged_IT.CEL"),
       .direction = "up") %>%
  ungroup() %>%
  arrange(country_id, year)

colmiss <- naCountFun(VDem_GW_regime_shift_external_data, TARGET_YEAR)
colmiss
if (any(colmiss > 0)) stop("Something is wrong, some columns have missing values")

colmiss_tgt <- naCountFun(VDem_GW_regime_shift_external_data, TARGET_YEAR + 1)
colmiss_tgt

dim(VDem_GW_regime_shift_external_data) ## 7683  217

VDem_GW_regime_shift_external_data$date <- NULL

export(VDem_GW_regime_shift_external_data, "output/ALL_data_final_USE_v9.csv")


import("output/ALL_data_final_USE_v9.csv")
export(VDem_GW_regime_shift_external_data, "../../regime-forecast/input/ALL_data_final_USE_v9.csv")

# complete_data <- read_csv("../../regime-forecast/input/ALL_data_final_USE_v9.csv")
# naCountFun(complete_data, TARGET_YEAR + 1)



### AB 2019-03-13: i stopped here, not sure below works

# dontrun <- function() {
# # ## What's not in our 2018 DV set but in vdem and gw?
# DV_set <- import("input/VDem_GW_DV_dataframe_1970.csv")%>%
#     select(gwcode, year, country_name, country_text_id, country_id)%>%
#         filter(year == TARGET_YEAR)
# dim(DV_set)

# vdem_coverage <- import("input/Vdem_template.csv")%>%
#     select(gwcode, year, country_name, country_text_id, country_id)%>%
#         filter(year == TARGET_YEAR)
# dim(vdem_coverage)

# keep <- gwstates$gwcode[gwstates$microstate == FALSE]
# GW_coverage <- state_panel(as.Date("1970-01-01"), as.Date(paste0(TARGET_YEAR, "-01-01")), by = "year", partial = "any", useGW = TRUE)%>%
#     mutate(year = lubridate::year(date), date = NULL)%>%
#         filter(gwcode %in% keep & year == TARGET_YEAR)
# dim(GW_coverage)

# ## dropped from vdem
# anti_join(vdem_coverage, DV_set)

# ## dropped from gw
# dropped_from_gw <- anti_join(GW_coverage, DV_set)
# gwstates[gwstates$gwcode %in% dropped_from_gw$gwcode, c(1, 3)]

# ## Which country-years are dropped
# DV_coverage <- import("input/VDem_GW_DV_dataframe_1970.csv")%>%
#     select(gwcode, year, country_name, country_text_id, country_id, any_neg_change)
# dim(DV_coverage)

# Vdem_template <- import("input/Vdem_template.csv")%>%
#     select(gwcode, year, country_name, country_text_id, country_id, any_neg_change)
# dim(Vdem_template)
# # summary(Vdem_template)
# # Vdem_template[Vdem_template$country_name == "Slovenia", ]

# keep <- gwstates$gwcode[gwstates$microstate == FALSE]
# GW_template <- state_panel(as.Date("1970-01-01"), as.Date(paste0(TARGET_YEAR, "-01-01")), by = "year", partial = "any", useGW = TRUE)%>%
#     mutate(year = lubridate::year(date), date = NULL)%>%
#         filter(gwcode %in% keep)

# dropped_from_vdem_complete <- anti_join(Vdem_template, DV_coverage)
# table(dropped_from_vdem_complete$year, dropped_from_vdem_complete$country_name)

# dropped_from_gw_complete0 <- anti_join(GW_template, DV_coverage)
# dropped_from_gw_complete <- left_join(dropped_from_gw_complete0, gwstates[gwstates$gwcode %in% dropped_from_gw_complete0$gwcode, c(1, 3)])
# table(dropped_from_gw_complete$year, dropped_from_gw_complete$country_name)

# ## WHat does the yearly distribution of the DV look like
# Vdem_template[Vdem_template$any_neg_change == 1 & Vdem_template$year == 1986, ]

# yearly_coverage <- table(Vdem_template$year, Vdem_template$any_neg_change)
# barplot(yearly_coverage[, 2], width = 0.5, cex.names = 0.8)
# # yearly_percent_dv <-
# data.frame(any_neg_change = yearly_coverage[, 2], no_neg_change = yearly_coverage[, 1], percent_neg_change = round(yearly_coverage[, 2]/(yearly_coverage[, 1] + yearly_coverage[, 2]), 2))

# # Percent DV
# sum(DV_coverage$any_neg_change, na.rm = TRUE) / nrow(DV_coverage[!is.na(DV_coverage$any_neg_change), ])


# }



