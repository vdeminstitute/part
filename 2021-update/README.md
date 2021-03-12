Notes for the 2021 forecast update
==================================



Forecast sanity check
---------------------

Some unexpected countries like Denmark are showing up high in the 2021-2022 forecasts. Does this make sense?

In 2020 there were observed adverse regime transitions (ARTs) in 4 countries: Czech Republic, Portugal, Ivory Coast, and Slovenia. 

CR, Portugal and Slovenia all went from liberal democracy (v2x_regime=3) to electoral democracy (v2x_regime=2). 

The conditions separating the two RoW categories are:

v2x_liberal > .8 AND  
v2cltrnslw_osp > 3 AND  
v2clacjstm_osp > 3 AND  
v2clacjstw_osp > 3

All three European cases were due to decreases in the transparent laws with predictable enforcement index (`v2cltrnslw_osp`). Portugal went from 3.7 to 2.9, Slovenia 3.3 to 2.7, and Czech Republic from 3 to 2.5.

Ivory Coast went from electoral to closed democracy; not relevant for Denmark & co so I won't dig in. 

Looking at the data for Denmark, it's transparent laws index went from 3.9 to 3.2 for 2020. So it seems credible that it would be relatively high risk. Latvia is at 3.1 on the index, also a high prediction. 

```
library(vdemdata)
library(here)

vdem <- readRDS(here("create-data/input/V-Dem-CY-Full+Others-v11.rds"))
keep <- c("country_name", "year", "v2x_regime", "v2x_liberal", "v2cltrnslw_osp",
          "v2clacjstm_osp", "v2clacjstw_osp")
vdem <- vdem[, keep]
# v2x_polyarchy v2elfrfair_osp v2elmulpar_osp
vdem %>% filter(country_name=="Portugal", year > 1990) %>% View()
vdem %>% filter(country_name=="Slovenia", year > 1990) %>% View()
vdem %>% filter(country_name=="Czech Republic", year > 1990) %>% View()
vdem %>% filter(country_name=="Ivory Coast", year > 1990) %>% View()
vdem %>% filter(country_name=="Denmark", year > 1990) %>% View()
```


