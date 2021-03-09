Create merged data
==================

For GDP, population, infant mortality, P&T Coups, state age updates, see demspaces repo

EPR has not had an update. 


```r
library(yaml)
library(stringr)

v9  <- read_yaml("output/part-v9-signature.yml")$Columns
v11 <- read_yaml("output/part-v11-signature.yml")$Columns

v9 <- str_replace_all(v9, "pt_coup_attempt", "pt_attempt")
v9 <- str_replace_all(v9, "pt_failed_coup_attempt", "pt_failed")

v9 <- str_remove_all(v9, "lagged_")
v9 <- str_remove_all(v9, "diff_year_prior_")
v9 <- unique(v9)

v11 <- str_remove_all(v11, "lagged_")
v11 <- str_remove_all(v11, "diff_year_prior_")
v11 <- unique(v11)

# 1 variables dropped out in v11, v2lgamend
setdiff(v9, v11)

# 9 new ones
setdiff(v11, v9)
# [1] "v2xdl_delib"    "v2x_elecoff"    "v2x_partip"     "v2x_egal"       "v2xeg_eqdr"     "v2ex_legconhog"
# [7] "v2ex_legconhos" "v2ex_elechos"   "v2expathhs"    
```
