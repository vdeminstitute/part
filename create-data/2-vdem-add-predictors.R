
# This script gets the V-Dem feature set data in order. It requires that you have download V-Dem v9...
## You will need to make sure all of your directory paths are correct...

packs <- c("tidyverse", "rio", "vfcast", "states") 
# install.packages(packs, dependencies = TRUE)
# install.packages("C:/Users/rickm/Dropbox/VForecast/vfcast_0.0.1.tar.gz")
lapply(packs, library, character.only = TRUE)
setwd(vpath("Data/v9/v-dem")) ## vpath comes from the vfcast package, which Andy built to reduce file path issues he and I were having...  
source("../../../regime-forecast/R/functions.R")

TARGET_YEAR <- 2019
START_YEAR <- 1968

## This is the target variable dataset. We'll need it at the end...  
VDem_GW_regime_shift_data <- read_csv("output/VDem_GW_regime_shift_data_1970_v9.csv")%>%
  mutate(country_name = ifelse(country_id == 196, "Sao Tome and Principe", country_name))
dim(VDem_GW_regime_shift_data) ## 'data.frame':   7923 obs. of  26 variables:

vdem_complete <- readRDS("../Dropbox/Closing Space/Data/VDem_v9/V-Dem-CY-Full+Others-v9.rds") %>%
  mutate(country_name = ifelse(country_id == 196, "Sao Tome and Principe", country_name)) %>%
  filter(year >= START_YEAR & 
           country_name != "Palestine/West Bank" & country_name != "Hong Kong" & country_name != "Bahrain" & country_name != "Malta" & 
           country_name != "Zanzibar" & country_name != "Somaliland" & country_name != "Palestine/Gaza") %>% 
  filter(!(country_name == "Timor-Leste" & year < 2002)) %>%
  mutate(gwcode = COWcode,
         gwcode = case_when(gwcode == 255 ~ 260L,
                            gwcode == 679 ~ 678L,
                            gwcode == 345 & 
                              year >= 2006 ~ 340L, 
                            TRUE ~ gwcode)) %>%
    select(country_name, country_text_id, gwcode, country_id, year, v2x_polyarchy, v2x_liberal, v2xdl_delib, v2x_jucon,
           v2x_frassoc_thick, v2xel_frefair, v2x_elecoff, v2xlg_legcon, v2x_partip, v2x_cspart, v2x_egal, v2xeg_eqprotec,
           v2xeg_eqaccess, v2xeg_eqdr, v2x_diagacc, v2xex_elecleg, v2x_civlib, v2x_clphy, v2x_clpol, v2x_clpriv, v2x_corr, 
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
           v2lgdsadlobin, v2lglegplo, v2lgcomslo, v2lgsrvlo, v2ex_hosw, v2lgamend, v2dlreason, v2dlcommon, v2dlcountr, v2dlconslt, 
           v2dlengage, v2dlencmps, v2dlunivl, v2jureform, v2jupurge, v2jupoatck, v2jupack, v2juaccnt, v2jucorrdc, v2juhcind, 
           v2juncind, v2juhccomp, v2jucomp, v2jureview, v2clacfree, v2clrelig, v2cltort, v2clkill, v2cltrnslw, v2clrspct, v2clfmove, 
           v2cldmovem, v2cldmovew, v2cldiscm, v2cldiscw, v2clslavem, v2clslavef, v2clstown, v2clprptym, v2clprptyw, v2clacjstm, 
           v2clacjstw, v2clacjust, v2clsocgrp, v2clrgunev, v2svdomaut, v2svinlaut, v2svstterr, v2cseeorgs, v2csreprss, v2cscnsult, 
           v2csprtcpt, v2csgender, v2csantimv, v2csrlgrep, v2csrlgcon, v2mecenefm, v2mecrit, v2merange, v2meharjrn, v2meslfcen, v2mebias, 
           v2mecorrpt, v2pepwrses, v2pepwrsoc, v2pepwrgen, v2pepwrort, v2peedueq, v2pehealth)
dim(vdem_complete)

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
                  v2elmonden = ifelse(is.na(v2elmonden) & v2x_elecreg == 0, 0, v2elmonden)) %>%#,
           ungroup() %>%
           mutate(v2x_jucon = ifelse(is_jud == 0, 0, v2x_jucon), 
                  v2xlg_legcon = ifelse(is_leg == 0, 0, v2xlg_legcon), 
                  v2elmonref = ifelse(is.na(v2elmonref) & is_elec == 1, 0, v2elmonref),
                  v2elmonden = ifelse(is.na(v2elmonden) & is_elec == 1, 0, v2elmonden),
                  v2elrsthos = ifelse(is.na(v2elrsthos) & country_name == "South Africa" & between(year, 2017, 2018), 1, v2elrsthos), ## Not sure why this is NA... It has been a 1 since 1993
                  v2elrsthos = ifelse(is.na(v2elrsthos) & country_name == "Haiti" & between(year, 2017, 2018), 1, v2elrsthos), ## Not sure why this is NA... All other years are 1
                  v2elrstrct = ifelse(is.na(v2elrstrct) & country_name == "Timor-Leste" & between(year, 2017, 2018), 1, v2elrstrct), ## Not sure why this is NA... All other years are 
                  v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "Saudi Arabia" & between(year, 1970, 2018), -3.527593, v2psoppaut), ## Opposition parties are banned in Saudi Arabia. Going with the min score in the data (1970-2017)
                  v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "Kuwait" & between(year, 1970, 2018), -2.250289, v2psoppaut), ## Carry forward. has the same score 1970-2016
                  v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "Qatar" & between(year, 1971, 2018), -3.527593, v2psoppaut), ## Opposition parties are banned in Qatar. Going with the min score in the data (1970-2017)
                  v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "United Arab Emirates" & between(year, 1971, 2018), -3.527593, v2psoppaut), ## Opposition parties are banned in UAE. Going with the min score in the data (1970-2017)
                  v2psoppaut = ifelse(is.na(v2psoppaut) & country_name == "Oman" & between(year, 2000, 2018), -2.46780629, v2psoppaut), ## Carry forward. There are a handful of nominal opposition parties, but they are co-opted. No much changed after 1999... 
                  v2lgqstexp = ifelse(is_leg == 0, 0, v2lgqstexp), 
                  v2lginvstp = ifelse(is_leg == 0, 0, v2lginvstp), 
                  v2lgotovst = ifelse(is_leg == 0, 0, v2lgotovst), 
                  v2lgcrrpt = ifelse(is_leg == 0, 0, v2lgcrrpt), 
                  v2lgoppart = ifelse(is_leg == 0, 0, v2lgoppart),
                  v2lgfunds = ifelse(is_leg == 0, 0, v2lgfunds), 
                  v2lgdsadlobin = ifelse(is_leg == 0, 0, v2lgdsadlobin),
                  v2lglegplo = ifelse(is_leg == 0, 0, v2lglegplo), 
                  v2lgcomslo = ifelse(is_leg == 0, 0, v2lgcomslo), 
                  v2lgsrvlo =  ifelse(is_leg == 0, 0, v2lgsrvlo),  
                  v2lgamend = ifelse(is.na(v2lgamend) & is_leg == 0, 0, v2lgamend),
                  v2lgamend = ifelse(is.na(v2lgamend) & country_name == "Ghana" & year == 2018, 1, v2lgamend)) %>%
           select(country_name, country_text_id, gwcode, country_id, year, everything())
dim(vdem_clean_data) ## 8258  191

vdem_clean_data_lagged <- vdem_clean_data %>%
  mutate(year = year + 1)
names(vdem_clean_data_lagged)[-c(1:5)] <- paste("lagged_", names(vdem_clean_data_lagged)[-c(1:5)], sep = "")
dim(vdem_clean_data_lagged) ## 8258  191

vdem_clean_data_lagged_diff <- vdem_clean_data_lagged %>%
  group_by(country_id) %>%
  arrange(year) %>%
  mutate_at(vars(-c(country_name, country_text_id, gwcode, country_id, year, lagged_is_jud, lagged_is_leg, lagged_is_elec, lagged_is_election_year)), ~c(NA, diff(.))) %>% 
  ungroup() %>%
  arrange(country_id, year) %>%
  select(country_name, country_text_id, gwcode, country_id, year, lagged_is_jud, lagged_is_leg, lagged_is_elec, lagged_is_election_year, everything())

names(vdem_clean_data_lagged_diff)[-c(1:9)] <- str_replace_all(names(vdem_clean_data_lagged)[-c(1:9)], "lagged_", "lagged_diff_year_prior_")
# naCountFun(vdem_clean_data_lagged_diff, TARGET_YEAR)

vdem_data <- vdem_clean_data_lagged %>%
  left_join(vdem_clean_data_lagged_diff)
dim(vdem_data)
# naCountFun(vdem_data, TARGET_YEAR)

vDem_GW_data <- VDem_GW_regime_shift_data %>%
  left_join(vdem_data) %>%
  group_by(gwcode) %>%
  arrange(year) %>%
  fill(1:length(.), .direction = "up") %>%
  ungroup() %>%
  arrange(country_id, year)
dim(vDem_GW_data)
summary(vDem_GW_data)

naCountFun(vDem_GW_data, TARGET_YEAR + 1)
naCountFun(vDem_GW_data, TARGET_YEAR)

write_csv(VDem_GW_data, "output/VDem_GW_data_final_USE_2yr_target_v9.csv")















vdem_clean_data0 <- left_join(country_year_set, vdem_clean_data)
dim(vdem_clean_data0) ## 8118   190
naCountFun(vdem_clean_data0, TARGET_YEAR)

View(vdem_clean_data0[is.na(vdem_clean_data0$v2elmulpar) & vdem_clean_data0$year != 2019, c("country_name", "year", "is_leg")])



