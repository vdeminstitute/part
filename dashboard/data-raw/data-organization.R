#
#   Create/update the dashboard data
#
#   Andreas Beger
#   2021-03-12
#
#   This script was originally written by Rick Morgan (?).
#

library(leaflet)

library(highcharter)
library(rgeos)
library(maptools)
library(states)

library(dplyr)
library(here)
library(rgdal)
library(rgeos)  # for gCentroid

setwd(here("dashboard"))

vdem_complete <- readRDS("data-raw/V-Dem-CY-Full+Others-v11.rds")

dat_complete <- read.csv("data-raw/part-v11.csv")%>%
  mutate(
    lagged_v2x_regime_amb_asCharacter = case_when(
      lagged_v2x_regime_amb.0 == 1 ~ "Closed Autocracy",
      lagged_v2x_regime_amb.1 == 1 ~ "High-level Closed Autocracy",
      lagged_v2x_regime_amb.2 == 1 ~ "Low-level Electoral Autocracy",
      lagged_v2x_regime_amb.3 == 1 ~ "Electoral Autocracy",
      lagged_v2x_regime_amb.4 == 1 ~ "High-level Electoral Autocracy",
      lagged_v2x_regime_amb.5 == 1 ~ "Low-level Electoral Democracy",
      lagged_v2x_regime_amb.6 == 1 ~ "Electoral Democracy",
      lagged_v2x_regime_amb.7 == 1 ~ "High-level Electoral Democracy",
      lagged_v2x_regime_amb.8 == 1 ~ "Low-level Liberal Democracy",
      lagged_v2x_regime_amb.9 == 1 ~ "Liberal Democracy"))

live_forecast_dat <- readRDS(file = "data-raw/mdl6_live_forecast.rds") %>%
  ungroup() %>%
	select(gwcode, year, prob.1)

test_forecast_dat <- readRDS(file = "data-raw/mdl6_test_forecasts.rds") %>%
  ungroup() %>%
  select(gwcode, year, prob.1)

test_and_live_forecast_dat <- rbind(test_forecast_dat, live_forecast_dat)

country_list <- dat_complete%>%
  filter(year == max(year))%>%
    select(gwcode, year, country_name, lagged_v2x_regime, lagged_v2x_regime_amb_asCharacter)%>%
      left_join(test_and_live_forecast_dat)%>%
        dplyr::rename(prob_onset = prob.1,
          regime = lagged_v2x_regime)%>%
        dplyr::arrange(desc(prob_onset))%>%
          mutate(map_color_prob = case_when(prob_onset < 0.05 ~ "#fef0d9",
              prob_onset < 0.1 ~ "#fdcc8a",
              prob_onset < 0.2 ~ "#fc8d59",
              prob_onset < 0.25 ~ "#e34a33",
              prob_onset > 0.25 ~ "#b30000"),
            map_color_prob = ifelse(regime == 0, "#D0D0D1", map_color_prob),
            color_prob = case_when(prob_onset < 0.05 ~ "#fef0d9",
              prob_onset < 0.1 ~ "#fdcc8a",
              prob_onset < 0.2 ~ "#fc8d59",
              prob_onset < 0.25 ~ "#e34a33",
              prob_onset > 0.25 ~ "#b30000"),
            regime_asCharacter = case_when(regime == 0 ~ "Closed Autocracy",
              regime == 1 ~ "Electoral Autocracy",
              regime == 2 ~ "Electoral Democracy",
              regime == 3 ~ "Liberal Democracy"),
            rank = 1:n())

GW_shp_file <- cshapes::cshp(date = as.Date("2013/01/01"), useGW = TRUE)
str(GW_shp_file@data)
GW_shp_file@data$gwcode <- GW_shp_file@data$GWCODE
GW_shp_file@data <- left_join(GW_shp_file@data, country_list)%>%
  select(-GWCODE)

country_centers <- SpatialPointsDataFrame(gCentroid(GW_shp_file, byid = TRUE),
                                      GW_shp_file@data, match.ID = FALSE)

GW_shp_file@data <- GW_shp_file@data%>%
    mutate(center_lon = country_centers@coords[, 1],
      center_lat = country_centers@coords[, 2])

popUp_text0 <- paste("<h3><b>", GW_shp_file@data$CNTRY_N,"</b></h3>", "<h6><b>Probablity of Adverse Regime Transition: ",
  paste(floor(GW_shp_file@data$prob_onset * 100), "%</b></h6>", sep = ""),
  paste("<b> Estimated Risk Ranking 2019/2020: ", GW_shp_file@data$rank, "</b><br>", sep = ""),
  paste("<b> ROW Class in 2018: ", GW_shp_file@data$regime_asCharacter, "</b>", sep = ""),sep = "")
GW_shp_file@data$popUp_text <- str_replace_all(popUp_text0, "NA%", "No Data")

#GW_shp_file_new2 <- rmapshaper::ms_simplify(GW_shp_file, keep = 0.2)
#object.size(GW_shp_file)
#object.size(GW_shp_file_new2)

saveRDS(GW_shp_file, file = "data/new_map_data.rds", compress = FALSE)

N <- 20
bar_plot_dat <- GW_shp_file@data%>%
  select(gwcode, country_name, prob_onset, color_prob)%>%
  mutate(color_prob = as.character(color_prob),
    color_prob = ifelse(is.na(color_prob), "#ffffff", color_prob))%>%
  arrange(desc(prob_onset))%>%
  head(., N)
saveRDS(bar_plot_dat, file = "data/bar_plot_dat.rds", compress = FALSE)


prob1_dat <- test_and_live_forecast_dat%>%
  left_join(dat_complete)%>%
  select(country_name, year, prob.1, any_neg_change, any_neg_change_2yr)%>%
  mutate(year_string = paste(year, (year - 2000 + 1), sep = "/"),
   prob_1 = round(prob.1, 3) * 100,
    colors = case_when(any_neg_change == 1 & any_neg_change_2yr == 1 ~ "#0498F0", #"#026097",
                      any_neg_change == 0 & any_neg_change_2yr == 1 ~ "#0498F0", #"#0498F0",
                      any_neg_change == 0 &  any_neg_change_2yr == 0 ~ "#C48BC890", #"#C48BC890",
                      is.na(any_neg_change_2yr) ~ "#A29C97"),
    ART_current_year = ifelse(any_neg_change == 1, "Yes", "No"))

saveRDS(prob1_dat, file = "data/prob1_dat.rds", compress = FALSE)

vdem_select <- vdem_complete%>%
  select(year, country_name, v2x_regime_amb,
    v2x_polyarchy, v2x_polyarchy_codehigh, v2x_polyarchy_codelow,
    v2x_liberal, v2x_liberal_codehigh,  v2x_liberal_codelow,
    v2xel_frefair, v2xel_frefair_codehigh, v2xel_frefair_codelow,
    v2x_freexp_altinf, v2x_freexp_altinf_codehigh, v2x_freexp_altinf_codelow,
    v2x_frassoc_thick, v2x_frassoc_thick_codehigh, v2x_frassoc_thick_codelow,
    v2xcl_rol, v2xcl_rol_codehigh, v2xcl_rol_codelow,
    v2x_jucon, v2x_jucon_codehigh, v2x_jucon_codelow,
    v2xlg_legcon, v2xlg_legcon_codehigh, v2xlg_legcon_codelow,
    v2x_civlib, v2x_civlib_codehigh, v2x_civlib_codelow)%>%
  filter(year > 2009)%>%
  mutate(v2x_regime_amb_asCharacter = case_when(v2x_regime_amb == 0 ~ "Closed Autocracy",
    v2x_regime_amb == 1 ~ "High-level Closed Autocracy",
    v2x_regime_amb == 2 ~ "Low-level Electoral Autocracy",
    v2x_regime_amb == 3 ~ "Electoral Autocracy",
    v2x_regime_amb == 4 ~ "High-level Electoral Autocracy",
    v2x_regime_amb == 5 ~ "Low-level Electoral Democracy",
    v2x_regime_amb == 6 ~ "Electoral Democracy",
    v2x_regime_amb == 7 ~ "High-level Electoral Democracy",
    v2x_regime_amb == 8 ~ "Low-level Liberal Democracy",
    v2x_regime_amb == 9 ~ "Liberal Democracy"))

country_characteristic_dat <- dat_complete%>%
  select(gwcode, country_name, year)%>%
  filter(between(year, 2010, 2018))%>%
  left_join(vdem_select)
saveRDS(country_characteristic_dat, file = "data/country_characteristic_dat.rds",
        compress = FALSE)
