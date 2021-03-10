#
#   Augment the V-Dem regime shift outcome data with predictors
#
#   Andreas Beger
#   2021-03-09
#
#   The original version of this script was written by Rick Morgan and called
#   `compose_all_vdem_data_new.r`.
#
#   Inputs: output/regime-shift-data-1970on.csv
#           input/V-Dem-CY-Full+Others-vX.rds
#
#   Outputs:  output/VDem_GW_data_final_USE_2yr_target_v9.csv

# UPDATE: the first year of the 2-year period we want to forecast for
# Note that this is different from demspaces.
TARGET_YEAR <- 2021
VERSION <- "v11"
# keep this the same
START_YEAR  <- 1968
# The V-Dem data we use as input; should be correct automatically with VERSION
VDEM_DATA <- sprintf(here("create-data/input/V-Dem-CY-Full+Others-%s.rds"), VERSION)


library(dplyr)
library(tidyr)
library(readr)
library(states)
library(here)
library(stringr)

naCountFun <- function(dat, exclude_year){
  dat%>%
    filter(year < exclude_year)%>%
    sapply(function(x) sum(is.na(x)))%>%
    sort()
}

setwd(here("create-data"))


## This is the target variable dataset. We'll need it at the end...
VDem_GW_regime_shift_data <- read_csv("output/regime-shift-data-1970on.csv",
                                      col_types = cols()) %>%
  mutate(country_name = ifelse(country_id == 196, "Sao Tome and Principe", country_name))
dim(VDem_GW_regime_shift_data)
# v9:  7923 obs. of 26 variables
# v11: 8190 obs. of 26 variables

vdem_raw <- readRDS(VDEM_DATA)
vdem_complete <- vdem_raw %>%
  mutate(country_name = ifelse(country_id == 196, "Sao Tome and Principe", country_name)) %>%
  filter(
    year >= START_YEAR &
      country_name != "Palestine/West Bank" & country_name != "Hong Kong" &
      country_name != "Bahrain" & country_name != "Malta" &
      country_name != "Zanzibar" & country_name != "Somaliland" &
      country_name != "Palestine/Gaza") %>%
  filter(!(country_name == "Timor-Leste" & year < 2002)) %>%
  mutate(gwcode = as.integer(COWcode),
         gwcode = case_when(gwcode == 255 ~ 260L,
                            gwcode == 679 ~ 678L,
                            gwcode == 345 &
                              year >= 2006 ~ 340L,
                            TRUE ~ gwcode)) %>%
  select(
    country_name, country_text_id, gwcode, country_id, year, v2x_polyarchy,
    v2x_liberal, v2xdl_delib, v2x_jucon, v2x_frassoc_thick, v2xel_frefair,
    v2x_elecoff, v2xlg_legcon, v2x_partip, v2x_cspart, v2x_egal, v2xeg_eqprotec,
    v2xeg_eqaccess, v2xeg_eqdr, v2x_diagacc, v2xex_elecleg, v2x_civlib,
    v2x_clphy, v2x_clpol, v2x_clpriv, v2x_corr, v2x_freexp_altinf, v2xcl_rol,
    v2x_accountability, v2x_veracc, v2x_horacc, v2x_pubcorr, v2xcs_ccsi,
    v2x_EDcomp_thick, v2x_elecreg, v2x_freexp, v2x_gencl, v2x_gencs, v2x_hosabort, v2x_hosinter, v2x_rule, v2xcl_acjst,
    v2xcl_disc, v2xcl_dmove, v2xcl_prpty, v2xcl_slave, v2xel_elecparl, v2xel_elecpres, v2xex_elecreg, v2xlg_elecreg,
    v2ex_legconhog, v2ex_legconhos, v2x_ex_confidence, v2x_ex_direlect, v2x_ex_hereditary, v2x_ex_military, v2x_ex_party,
    v2x_execorr, v2x_legabort, v2xlg_leginter, v2x_neopat, v2xnp_client, v2xnp_pres, v2xnp_regcorr, v2elvotbuy, v2elfrcamp,
    v2elpdcamp, v2elpaidig, v2elmonref, v2elmonden, v2elrgstry, v2elirreg, v2elintim, v2elpeace, v2elfrfair, v2elmulpar,
    v2elboycot, v2elaccept, v2elasmoff, v2eldonate, v2elpubfin, v2ellocumul, v2elprescons, v2elprescumul, v2elembaut,
    v2elembcap, v2elreggov, v2ellocgov, v2ellocons, v2elrsthos, v2elrstrct, v2psparban, v2psbars, v2psoppaut, v2psorgs,
    v2psprbrch, v2psprlnks, v2psplats, v2pscnslnl, v2pscohesv, v2pscomprg, v2psnatpar, v2pssunpar, v2exremhsp, v2exdfdshs,
    v2exdfcbhs, v2exdfvths, v2exdfdmhs, v2exdfpphs, v2exhoshog, v2exrescon, v2exbribe, v2exembez, v2excrptps, v2exthftps,
    v2ex_elechos, v2ex_hogw, v2expathhs, v2lgbicam, v2lgqstexp, v2lginvstp, v2lgotovst, v2lgcrrpt, v2lgoppart, v2lgfunds,
    v2lgdsadlobin, v2lglegplo, v2lgcomslo, v2lgsrvlo, v2ex_hosw, v2dlreason, v2dlcommon, v2dlcountr, v2dlconslt,
    v2dlengage, v2dlencmps, v2dlunivl, v2jureform, v2jupurge, v2jupoatck, v2jupack, v2juaccnt, v2jucorrdc, v2juhcind,
    v2juncind, v2juhccomp, v2jucomp, v2jureview, v2clacfree, v2clrelig, v2cltort, v2clkill, v2cltrnslw, v2clrspct, v2clfmove,
    v2cldmovem, v2cldmovew, v2cldiscm, v2cldiscw, v2clslavem, v2clslavef, v2clstown, v2clprptym, v2clprptyw, v2clacjstm,
    v2clacjstw, v2clacjust, v2clsocgrp, v2clrgunev, v2svdomaut, v2svinlaut, v2svstterr, v2cseeorgs, v2csreprss, v2cscnsult,
    v2csprtcpt, v2csgender, v2csantimv, v2csrlgrep, v2csrlgcon, v2mecenefm, v2mecrit, v2merange, v2meharjrn, v2meslfcen, v2mebias,
    v2mecorrpt, v2pepwrses, v2pepwrsoc, v2pepwrgen, v2pepwrort, v2peedueq, v2pehealth)
# v11: 'v2lgamend' doesn't seem to exist anymore
dim(vdem_complete)
# 8602 x 186

# Rule-based imputations
# Some variables are missing because for conceptual reasons; set these to 0
vdem_clean_data <- vdem_complete %>%
  group_by(country_id) %>%
  arrange(year) %>%
  mutate(is_jud = ifelse(is.na(v2x_jucon), 0, 1),
         is_leg = ifelse(v2lgbicam > 0, 1, 0),
         is_elec = ifelse(v2x_elecreg == 0, 0, 1),
         is_election_year = ifelse(!is.na(v2elirreg), 1, 0)) %>%
  fill(v2elrgstry) %>%
  fill(v2elvotbuy) %>%
  fill(v2elirreg) %>%
  fill(v2elintim) %>%
  fill(v2elpeace) %>%
  fill(v2elfrfair) %>%
  fill(v2elmulpar) %>%
  fill(v2elboycot) %>%
  fill(v2elaccept) %>%
  fill(v2elasmoff) %>%
  fill(v2elfrcamp) %>%
  fill(v2elpdcamp) %>%
  fill(v2elpaidig) %>%
  fill(v2elmonref) %>%
  fill(v2elmonden) %>%
  mutate(v2elrgstry = ifelse(is.na(v2elrgstry) & v2x_elecreg == 0, 0, v2elrgstry),
         v2elvotbuy = ifelse(is.na(v2elvotbuy) & v2x_elecreg == 0, 0, v2elvotbuy),
         v2elirreg = ifelse(is.na(v2elirreg) & v2x_elecreg == 0, 0, v2elirreg),
         v2elintim = ifelse(is.na(v2elintim) & v2x_elecreg == 0, 0, v2elintim),
         v2elpeace = ifelse(is.na(v2elpeace) & v2x_elecreg == 0, 0, v2elpeace),
         v2elfrfair = ifelse(is.na(v2elfrfair) & v2x_elecreg == 0, 0, v2elfrfair),
         v2elmulpar = ifelse(is.na(v2elmulpar) & v2x_elecreg == 0, 0, v2elmulpar),
         v2elboycot = ifelse(is.na(v2elboycot) & v2x_elecreg == 0, 0, v2elboycot),
         v2elaccept = ifelse(is.na(v2elaccept) & v2x_elecreg == 0, 0, v2elaccept),
         v2elasmoff = ifelse(is.na(v2elasmoff) & v2x_elecreg == 0, 0, v2elasmoff),
         v2elpaidig = ifelse(is.na(v2elpaidig) & v2x_elecreg == 0, 0, v2elpaidig),
         v2elfrcamp = ifelse(is.na(v2elfrcamp) & v2x_elecreg == 0, 0, v2elfrcamp),
         v2elpdcamp = ifelse(is.na(v2elpdcamp) & v2x_elecreg == 0, 0, v2elpdcamp),
         v2elpdcamp = ifelse(is.na(v2elpdcamp) & v2x_elecreg == 0, 0, v2elpdcamp),
         v2elmonref = ifelse(is.na(v2elmonref) & v2x_elecreg == 0, 0, v2elmonref),
         v2elmonden = ifelse(is.na(v2elmonden) & v2x_elecreg == 0, 0, v2elmonden)) %>%
  ungroup() %>%
  mutate(v2x_jucon = ifelse(is_jud == 0, 0, v2x_jucon),
         v2xlg_legcon = ifelse(is_leg == 0, 0, v2xlg_legcon),
         v2elmonref = ifelse(is.na(v2elmonref) & is_elec == 1, 0, v2elmonref),
         v2elmonden = ifelse(is.na(v2elmonden) & is_elec == 1, 0, v2elmonden),
         v2lgqstexp = ifelse(is_leg == 0, 0, v2lgqstexp),
         v2lginvstp = ifelse(is_leg == 0, 0, v2lginvstp),
         v2lgotovst = ifelse(is_leg == 0, 0, v2lgotovst),
         v2lgcrrpt = ifelse(is_leg == 0, 0, v2lgcrrpt),
         v2lgoppart = ifelse(is_leg == 0, 0, v2lgoppart),
         v2lgfunds = ifelse(is_leg == 0, 0, v2lgfunds),
         v2lgdsadlobin = ifelse(is_leg == 0, 0, v2lgdsadlobin),
         v2lglegplo = ifelse(is_leg == 0, 0, v2lglegplo),
         v2lgcomslo = ifelse(is_leg == 0, 0, v2lgcomslo),
         v2lgsrvlo =  ifelse(is_leg == 0, 0, v2lgsrvlo)) %>%
  select(country_name, country_text_id, gwcode, country_id, year, everything())

# Country specific imputations
# here are all the missing data points left:
if (FALSE) {
  probs <- vdem_clean_data %>%
    filter(!complete.cases(.)) %>%
    pivot_longer(-c(country_name, country_id, country_text_id, gwcode, year)) %>%
    filter(is.na(value)) %>%
    group_by(country_id, name) %>%
    arrange(country_id, name, year) %>%
    mutate(spell_id = id_date_sequence(year)) %>%
    group_by(country_id, country_name, name, spell_id) %>%
    summarize(years_missing = paste0(range(year), collapse = "-"), n = n()) %>%
    select(-spell_id)
  View(probs)
}

#vdem_clean_data %>% filter(country_name=="Jamaica") %>% select(year, v2elrstrct) %>% View()
vdem_clean_data <- vdem_clean_data %>%
  mutate(
    # Opposition parties are banned in Saudi Arabia. Going with the min score in the data
    v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "Saudi Arabia",
                        min(v2psoppaut, na.rm = TRUE), v2psoppaut),
    # Opposition parties are banned in Qatar. Going with the min score in the data
    v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "Qatar",
                        min(v2psoppaut, na.rm = TRUE), v2psoppaut),
    # Opposition parties are banned in UAE. There's a single non-missing value in 2019, use that
    v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "United Arab Emirates",
                        -2.363, v2psoppaut),
    # There's a single value for a couple of years, but with missing at head and tail;
    # just set everything to that value
    v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "Oman",
                        -2.472, v2psoppaut),
    # Jamaica; all other values are 1, set last two years to this as well
    v2elrsthos = ifelse(is.na(v2elrsthos) & country_name == "Jamaica",
                        1, v2elrsthos),
    v2elrstrct = ifelse(is.na(v2elrstrct) & country_name == "Jamaica",
                        1, v2elrstrct)
  )

dim(vdem_clean_data)
# v9:  8258 x 191
# v11: 8602 x 197

# There are still some missing values. Try two approaches:
# (1) For any missing values preceded by 3 identical non-NA values, use that
# (2) For any single missing value, use the previous observed value
#

# If a series is missing the last 1 or 2 values and the preceding 3 non-NA
# values are the same, set it to that; this gets rid of some edge cases
# where for some reason the last year in the data is missing
imputer <- function(x) {
  xx <- rle(x)
  trail_na <- is.na(tail(xx$values, 1))
  if (trail_na & length(xx$lengths) > 1) {
    # check the preceding non-NA value occurred at least 3 times
    # index for 2nd to last element
    back2 <- length(xx$lengths) - 1
    good <- xx$lengths[back2] > 2
    if (good) {
      x[(length(x) - tail(xx$lengths, 1) + 1):length(x)] <- xx$values[back2]
    }
  }
  x
}
# all.equal(imputer(c(1, 1, 1, NA)), rep(1, 4))
# all_equal(imputer(c(1, 1, NA)), c(1, 1, NA))
vdem_clean_data <- vdem_clean_data %>%
  group_by(country_id) %>%
  mutate_at(vars(-group_cols()), imputer) %>%
  ungroup()

# impute single NA values with previous value
# this catches a few leftovers for non-constant series
imputer <- function(x) {
  if (length(x) > 1) {
    for (i in 2:length(x)) {
      if (is.na(x[i]) & !is.na(x[i-1])) {
        x[i] <- x[i-1]
      }
    }
  }
  x
}
vdem_clean_data <- vdem_clean_data %>%
  group_by(country_id) %>%
  mutate_at(vars(-group_cols()), imputer) %>%
  ungroup()



# Lag and transformations -------------------------------------------------

vdem_clean_data_lagged <- vdem_clean_data %>%
  mutate(year = year + 1)
names(vdem_clean_data_lagged)[-c(1:5)] <- paste("lagged_", names(vdem_clean_data_lagged)[-c(1:5)], sep = "")
dim(vdem_clean_data_lagged)
# v9:  8258 x 191
# v11: 8602 x 197


vdem_clean_data_lagged_diff <- vdem_clean_data_lagged %>%
  pivot_longer(-c(country_name, country_text_id, gwcode, country_id, year, lagged_is_jud, lagged_is_leg, lagged_is_elec, lagged_is_election_year)) %>%
  group_by(country_id, name) %>%
  arrange(year) %>%
  mutate(value = c(NA, diff(value))) %>%
  pivot_wider()
colnames(vdem_clean_data_lagged_diff) <- str_replace(
  colnames(vdem_clean_data_lagged_diff), "lagged_", "lagged_diff_year_prior_")

vdem_data <- vdem_clean_data_lagged %>%
  left_join(vdem_clean_data_lagged_diff)
dim(vdem_data)
# v11: 8602 x 389
# naCountFun(vdem_data, TARGET_YEAR)

vDem_GW_data <- VDem_GW_regime_shift_data %>%
  left_join(vdem_data) %>%
  group_by(gwcode) %>%
  arrange(year) %>%
  fill(1:length(.), .direction = "up") %>%
  ungroup() %>%
  arrange(country_id, year)
dim(vDem_GW_data)
# v11: 8190 x 392

x <- naCountFun(vDem_GW_data, TARGET_YEAR + 1)
x[x>0]
# multiple missing for TARGET_YEAR
x <- naCountFun(vDem_GW_data, TARGET_YEAR)
x[x>0]
# any_neg_change_2yr should be missing for TARGET_YEAR - 1

saveRDS(vDem_GW_data, file = "output/vdem-augmented.rds")
