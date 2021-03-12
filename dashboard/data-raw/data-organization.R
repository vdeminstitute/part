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
library(sf)
library(rgdal)
library(rgeos)  # for gCentroid

setwd(here("dashboard"))

# V-Dem data for indices
vdem_complete <- readRDS("data-raw/V-Dem-CY-Full+Others-v11.rds")

MAX_DATA <- max(vdem_select$year)
MIN_DATA <- MAX_DATA - 9  # go back 9 years, for 10 years total, for time series plot

# PART data
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

# Forecast data
live_forecast_dat <- readRDS(file = "data-raw/mdl6_live_forecast.rds") %>%
  ungroup() %>%
  select(gwcode, year, prob.1)
test_forecast_dat <- readRDS(file = "data-raw/mdl6_test_forecasts.rds") %>%
  ungroup() %>%
  select(gwcode, year, prob.1)
test_and_live_forecast_dat <- rbind(test_forecast_dat, live_forecast_dat)

# Index year for forecast period
FCAST_YEAR <- max(live_forecast_dat$year)

# Prepare risk data to merge into map data
country_list <- dat_complete %>%
  filter(year == max(year)) %>%
  select(gwcode, year, country_name, lagged_v2x_regime)%>%
  left_join(test_and_live_forecast_dat)%>%
  dplyr::rename(prob_onset = prob.1,
                regime = lagged_v2x_regime)%>%
  dplyr::arrange(desc(prob_onset))%>%
  mutate(
    map_color_prob = case_when(
      prob_onset < 0.05 ~ "#fef0d9",
      prob_onset < 0.1 ~ "#fdcc8a",
      prob_onset < 0.2 ~ "#fc8d59",
      prob_onset < 0.25 ~ "#e34a33",
      prob_onset > 0.25 ~ "#b30000"),
    map_color_prob = ifelse(regime == 0, "#D0D0D1", map_color_prob),
    color_prob = case_when(
      prob_onset < 0.05 ~ "#fef0d9",
      prob_onset < 0.1 ~ "#fdcc8a",
      prob_onset < 0.2 ~ "#fc8d59",
      prob_onset < 0.25 ~ "#e34a33",
      prob_onset > 0.25 ~ "#b30000"),
    regime_asCharacter = case_when(
      regime == 0 ~ "Closed Autocracy",
      regime == 1 ~ "Electoral Autocracy",
      regime == 2 ~ "Electoral Democracy",
      regime == 3 ~ "Liberal Democracy"),
    rank = 1:n())

# Map data
raw_map_data <- cshapes::cshp(date = as.Date("2013/01/01"), useGW = TRUE)
raw_map_data <- rmapshaper::ms_simplify(raw_map_data, keep = 0.2)

# Convert to an sf object
map_data <- st_as_sf(raw_map_data)
map_data <- map_data %>%
  st_transform("+proj=longlat +datum=WGS84")
map_data <- map_data %>%
  select(GWCODE, CNTRY_NAME) %>%
  rename(gwcode = GWCODE)

# Add centroid lat/long
centroids <- map_data %>% st_centroid() %>% st_coordinates()
map_data$center_lon <- centroids[, 1]
map_data$center_lat <- centroids[, 2]

# Add regime and risk data
map_data <- map_data %>%
  left_join(country_list, by = "gwcode")

# Construct popup text
# UPDATE: the years here as needed
popup_text <- function(country, prob, rank, regime) {
  prob <- as.character(round(prob*100, digits = 0))
  # "0" -> "<0"
  prob[prob=="0"] <- "<0"
  # Add percent for non-missing values
  prob[!is.na(prob)] <- paste0(prob[!is.na(prob)], "%")
  prob[is.na(prob)] <- "No data"

  rank <- as.character(rank)
  rank[is.na(rank)] <- "No data"
  regime[is.na(regime)] <- "No data"
  paste0(
    sprintf("<h3><b>%s</b></h3>", country),
    sprintf("<h6><b>Probablity of Adverse Regime Transition: %s</b></h6>", prob),
    sprintf("<b> Estimated Risk Ranking %s/%s: %s</b><br>", FCAST_YEAR, FCAST_YEAR + 1, rank),
    sprintf("<b> ROW Class in %s: %s</b>", MAX_DATA, regime)
  )
}

map_data <- map_data %>%
  mutate(popUp_text = popup_text(CNTRY_NAME, prob_onset, rank, regime_asCharacter))

saveRDS(map_data, file = "data/new_map_data.rds", compress = FALSE)



# Data for top N forecasts ------------------------------------------------
#
#   For the small chart next to the map plot
#

N <- 20
bar_plot_dat <- GW_shp_file@data %>%
  arrange(desc(prob_onset)) %>%
  select(country_name, prob_onset, color_prob) %>%
  mutate(
    prob_onset = floor(prob_onset * 100),
    color_prob = as.character(color_prob),
    color_prob = ifelse(is.na(color_prob), "#ffffff", color_prob)) %>%
  head(., N)
saveRDS(bar_plot_dat, file = "data/bar_plot_dat.rds", compress = FALSE)



# Core V-Dem indicator data -----------------------------------------------
#
#   For country time series chart
#

vdem_select <- vdem_complete %>%
  select(year, country_name, v2x_regime_amb,
         v2x_polyarchy, v2x_polyarchy_codehigh, v2x_polyarchy_codelow,
         v2x_liberal, v2x_liberal_codehigh,  v2x_liberal_codelow,
         v2xel_frefair, v2xel_frefair_codehigh, v2xel_frefair_codelow,
         v2x_freexp_altinf, v2x_freexp_altinf_codehigh, v2x_freexp_altinf_codelow,
         v2x_frassoc_thick, v2x_frassoc_thick_codehigh, v2x_frassoc_thick_codelow,
         v2xcl_rol, v2xcl_rol_codehigh, v2xcl_rol_codelow,
         v2x_jucon, v2x_jucon_codehigh, v2x_jucon_codelow,
         v2xlg_legcon, v2xlg_legcon_codehigh, v2xlg_legcon_codelow,
         v2x_civlib, v2x_civlib_codehigh, v2x_civlib_codelow) %>%
  filter(year >= MIN_DATA) %>%
  mutate(v2x_regime_amb_asCharacter = case_when(
    v2x_regime_amb == 0 ~ "Closed Autocracy",
    v2x_regime_amb == 1 ~ "High-level Closed Autocracy",
    v2x_regime_amb == 2 ~ "Low-level Electoral Autocracy",
    v2x_regime_amb == 3 ~ "Electoral Autocracy",
    v2x_regime_amb == 4 ~ "High-level Electoral Autocracy",
    v2x_regime_amb == 5 ~ "Low-level Electoral Democracy",
    v2x_regime_amb == 6 ~ "Electoral Democracy",
    v2x_regime_amb == 7 ~ "High-level Electoral Democracy",
    v2x_regime_amb == 8 ~ "Low-level Liberal Democracy",
    v2x_regime_amb == 9 ~ "Liberal Democracy")
  )

country_characteristic_dat <- dat_complete %>%
  select(country_name, year)%>%
  filter(between(year, MIN_DATA, MAX_DATA))%>%
  left_join(vdem_select)
saveRDS(country_characteristic_dat, file = "data/country_characteristic_dat.rds",
        compress = FALSE)

# Risk data for all countries ---------------------------------------------
#
#   For the small risk over time plot next to the indicator time series plot
#

prob1_dat <- test_and_live_forecast_dat %>%
  left_join(dat_complete) %>%
  mutate(year_string = paste(year, (year - 2000 + 1), sep = "/"),
         prob_1 = round(prob.1, 3) * 100,
         colors = case_when(
           any_neg_change == 1 & any_neg_change_2yr == 1 ~ "#0498F0", #"#026097",
           any_neg_change == 0 & any_neg_change_2yr == 1 ~ "#0498F0", #"#0498F0",
           any_neg_change == 0 &  any_neg_change_2yr == 0 ~ "#C48BC890", #"#C48BC890",
           is.na(any_neg_change_2yr) ~ "#A29C97"),
         ART_current_year = ifelse(any_neg_change == 1, "Yes", "No")) %>%
  select(country_name, year_string, prob_1, colors, ART_current_year) %>%
  as.data.frame()

saveRDS(prob1_dat, file = "data/prob1_dat.rds", compress = FALSE)




