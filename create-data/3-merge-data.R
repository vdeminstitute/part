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
#   Output: part-vX.csv
#

# Which year should the data reach to?
TARGET_YEAR <- 2021
VERSION <- "v11"

library(dplyr)
library(tidyr)
library(states)
library(readr)
library(yaml)
library(mlr)  # to create dummy features

naCountFun <- function(dat, exclude_year){
  dat%>%
    filter(year < exclude_year)%>%
    sapply(function(x) sum(is.na(x)))%>%
    sort()
}

plotmiss <- function(x) {
  plot_missing(x, names(x), "gwcode", time = "year", statelist = "GW", partial = "any")
}


#
#   EPR ----
#   ______________

epr_dat <- read_csv("input/epr-yearly.csv", col_types = cols()) %>%
  select(-date) %>%
  filter(year < TARGET_YEAR) %>%
  mutate(year = year + TARGET_YEAR - max(year))
names(epr_dat)[-c(1:2)] <- paste("lagged_", names(epr_dat)[-c(1:2)], sep = "")

#
#   GDP ----
#   __________________

gdp_dat <- read_csv("input/gdp.csv", col_types = cols()) %>%
  filter(year < TARGET_YEAR) %>%
  dplyr::rename(gdp = NY.GDP.MKTP.KD,
                gdp_growth = NY.GDP.MKTP.KD.ZG,
                gdp_pc = NY.GDP.PCAP.KD,
                gdp_pc_growth = NY.GDP.PCAP.KD.ZG) %>%
  mutate(year = year + TARGET_YEAR - max(year),
        gdp_log = log(gdp),
        gdp_pc_log = log(gdp_pc))
names(gdp_dat)[-c(1:2)] <- paste("lagged_", names(gdp_dat)[-c(1:2)], sep = "")


#
#   State age ----
#   ________________________

age_dat <- read_csv("input/gwstate-age.csv", col_types = cols()) %>%
  filter(year < TARGET_YEAR) %>%
  mutate(year = year + TARGET_YEAR - max(year))
names(age_dat)[-c(1:2)] <- paste("lagged_", names(age_dat)[-c(1:2)], sep = "")


#
#   Population ----
#   ___________

pop_dat <- read_csv("input/population.csv", col_types = cols()) %>%
  filter(year < TARGET_YEAR) %>%
  mutate(year = year + pmax(0, TARGET_YEAR - max(year))) %>%
  # log this sucker
  mutate(pop = log(pop))
names(pop_dat)[-c(1:2)] <- paste("lagged_", names(pop_dat)[-c(1:2)], sep = "")


#
#   Coups ----
#   __________

coup_dat <- read_csv("input/ptcoups.csv", col_types = cols()) %>%
  filter(year < TARGET_YEAR) %>%
  select(-c(pt_failed_total, pt_failed_num5yrs, pt_failed_num10yrs))%>%
  mutate(year = year + TARGET_YEAR - max(year))
names(coup_dat)[-c(1:2)] <- paste("lagged_", names(coup_dat)[-c(1:2)], sep = "")


#
#   ACD ----
#   ______

acd_dat <- read_csv("input/acd.csv", col_types = cols()) %>%
  filter(year < TARGET_YEAR) %>%
  select(gwcode, year, everything()) %>%
  mutate(year = year + pmax(0, TARGET_YEAR - max(year)))
names(acd_dat)[-c(1:2)] <- paste("lagged_", names(acd_dat)[-c(1:2)], sep = "")


#
#   WDI infmort ----
#   ______


infmort <- read_csv("input/wdi-infmort.csv", col_types = cols()) %>%
  filter(year < TARGET_YEAR) %>%
  select(gwcode, year, everything()) %>%
  mutate(year = year + pmax(0, TARGET_YEAR - max(year)))
names(infmort)[-c(1:2)] <- paste("lagged_", names(infmort)[-c(1:2)], sep = "")


#
#   WDI ICT ----
#   ______


ict <- read_csv("input/wdi-ict.csv", col_types = cols()) %>%
  filter(year < TARGET_YEAR) %>%
  select(gwcode, year, everything()) %>%
  mutate(year = year + pmax(0, TARGET_YEAR - max(year)))
names(ict)[-c(1:2)] <- paste("lagged_", names(ict)[-c(1:2)], sep = "")


#
#   V-Dem ----
#   ___________

## All observations we have a DV for...
VDem_GW_regime_shift_data <- read_rds("output/vdem-augmented.rds")
dim(VDem_GW_regime_shift_data)
# v9:  7923 x 408
# v11: 8190 x 410
naCountFun(VDem_GW_regime_shift_data, TARGET_YEAR + 1)

VDem_GW_regime_shift_data <- VDem_GW_regime_shift_data %>%
  mutate(lagged_v2x_regime_amb = as.factor(lagged_v2x_regime_amb)) %>%
  mlr::createDummyFeatures(., cols = "lagged_v2x_regime_amb")

# here it's ok if we have up to target year
range(VDem_GW_regime_shift_data$year)
if (max(VDem_GW_regime_shift_data$year)!=TARGET_YEAR) stop("something wrong with VDem")

# missing y should only be for last 2 years
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

# v11: missing 2020 and 2021


# Merge all datasets ------------------------------------------------------


###########################
# Create master template

## GW_template is a balanced gwcode yearly data frame from 1970 to 2018. Need to drop microstates.
drop <- gwstates$gwcode[gwstates$microstate == TRUE]
GW_template <- state_panel(1970, TARGET_YEAR, by = "year", partial = "any",
                           useGW = TRUE) %>%
  filter(!(gwcode %in% drop))

## after the merge, all of the NAs that remain are from the external datasets. It looks like it is the first year in each series. We will need to back fill these variables...
part <- VDem_GW_regime_shift_data %>%
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
  fill(lagged_pt_attempt, .direction = "up")%>%
  fill(lagged_pt_attempt_num, .direction = "up")%>%
  fill(lagged_pt_coup_num, .direction = "up")%>%
  fill(lagged_pt_coup, .direction = "up")%>%
  fill(lagged_pt_failed_num, .direction = "up")%>%
  fill(lagged_pt_failed, .direction = "up")%>%
  fill(lagged_pt_coup_total, .direction = "up")%>%
  fill(lagged_pt_attempt_total, .direction = "up")%>%
  fill(lagged_pt_coup_num5yrs, .direction = "up")%>%
  fill(lagged_pt_attempt_num5yrs, .direction = "up")%>%
  fill(lagged_pt_coup_num10yrs, .direction = "up")%>%
  fill(lagged_pt_attempt_num10yrs, .direction = "up")%>%
  fill(lagged_years_since_last_pt_coup, .direction = "up")%>%
  fill(lagged_years_since_last_pt_failed, .direction = "up")%>%
  fill(lagged_years_since_last_pt_attempt, .direction = "up")%>%
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
  fill(lagged_pt_attempt, .direction = "down")%>%
  fill(lagged_pt_attempt_num, .direction = "down")%>%
  fill(lagged_pt_coup_num, .direction = "down")%>%
  fill(lagged_pt_coup, .direction = "down")%>%
  fill(lagged_pt_failed_num, .direction = "down")%>%
  fill(lagged_pt_failed, .direction = "down")%>%
  fill(lagged_pt_coup_total, .direction = "down")%>%
  fill(lagged_pt_attempt_total, .direction = "down")%>%
  fill(lagged_pt_coup_num5yrs, .direction = "down")%>%
  fill(lagged_pt_attempt_num5yrs, .direction = "down")%>%
  fill(lagged_pt_coup_num10yrs, .direction = "down")%>%
  fill(lagged_pt_attempt_num10yrs, .direction = "down")%>%
  fill(lagged_years_since_last_pt_coup, .direction = "down")%>%
  fill(lagged_years_since_last_pt_failed, .direction = "down")%>%
  fill(lagged_years_since_last_pt_attempt, .direction = "down")%>%
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

colmiss <- naCountFun(part, (TARGET_YEAR - 1))
colmiss
if (any(colmiss > 0)) stop("Something is wrong, some columns have missing values")

colmiss_tgt <- naCountFun(part, TARGET_YEAR + 1)
colmiss_tgt

dim(part) ## 7683  217

part$date <- NULL

# to pull out missing values
if (FALSE) {
  part %>%
    filter(!complete.cases(.)) %>%
    pivot_longer(-c(gwcode, year, country_id, country_name, country_text_id,lagged_v2x_regime_asCharacter, lagged_v2x_regime_asFactor)) %>%
    filter(is.na(value)) %>%
    filter(!name %in% c("any_neg_change", "any_neg_change_2yr", "v2x_regime", "v2x_regime_amb")) %>%
    group_by(country_id, name) %>%
    arrange(country_id, name, year) %>%
    mutate(spell_id = id_date_sequence(year)) %>%
    group_by(country_id, country_name, name, spell_id) %>%
    summarize(years_missing = paste0(range(year), collapse = "-"), n = n()) %>%
    select(-spell_id)
}

# Record signature and write out ------------------------------------------

attr(part, "spec") <- NULL
part <- as_tibble(part)

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
sig <- data_signature(part)

# Write both versioned and clean file name so that:
# - easy to see changes on git with clean file name
# - concise historical record with versioned file name
write_yaml(sig, sprintf("output/part-%s-signature.yml", VERSION))
write_yaml(sig, "output/part-signature.yml")

write_csv(part, sprintf("output/part-%s.csv", VERSION))

# Propagate downstream
write_csv(part, sprintf("../archive/part-%s.csv", VERSION))
write_csv(part, sprintf("../dashboard/data-raw/part-%s.csv", VERSION))
write_csv(part, sprintf("../Models/input/part-%s.csv", VERSION))



