Changes in RoW transitions between V-Dem data versions
================

Andreas Beger  
06 January 2023

The indicators on which the regimes of the world (RoW) classification is
based can change for the same case between V-Dem dataset versions. As a
result the set of outcomes–decreases in RoW–changes between V-Dem
versions.

``` r
suppressPackageStartupMessages({
  library(states)
  library(dplyr)
  library(readr)
  library(here)
})

keep <- c("gwcode", "country_id", "year", "country_name", "any_neg_change",
          "any_neg_change_2yr", "v2x_regime", "lagged_v2x_regime")

v9 <- read_csv(here("archive/part-v9.csv"), col_types = cols())[, keep]
v11 <- read_csv(here("archive/part-v11.csv"), col_types = cols())[, keep]
v12 <- read_csv(here("archive/part-v12.csv"), col_types = cols())[, keep]

# v9 doesn't have the right name for North Macedonia. That will cause merge
# problems.
v9$country_name[v9$country_name=="Macedonia"] <- "North Macedonia"

vdem11 <- readRDS(here("create-data/input/V-Dem-CY-Full+Others-v11.rds"))[, c("country_id", "year", "v2x_regime")]
vdem11 <- vdem11[vdem11$year >= min(v9$year), ]

vdem12 <- readRDS(here("create-data/input/V-Dem-CY-Full+Others-v12.rds"))[, c("country_id", "year", "v2x_regime")]
vdem12 <- vdem11[vdem12$year >= min(v9$year), ]

# I want a dataset that has all cases which are positive in either version
# Start by adding an indicator for RoW changes
v9pos <- v9 %>%
  filter(year < 2019) %>%
  mutate(v9pos = any_neg_change,
         v9change = paste0(lagged_v2x_regime, "->", v2x_regime)) %>%
  select(gwcode, country_id, year, country_name, v9pos, v9change)
v11pos <- v11 %>%
  filter(
         # drop years that are not in v9
         year %in% unique(v9pos$year)) %>%
  mutate(v11pos = any_neg_change,
         v11change = paste0(lagged_v2x_regime, "->", v2x_regime)) %>%
  select(gwcode, country_id, year, country_name, v11pos, v11change)
v12pos <- v12 %>%
  filter(
    # drop years that are not in v9
    year %in% unique(v9pos$year)) %>%
  mutate(v12pos = any_neg_change,
         v12change = paste0(lagged_v2x_regime, "->", v2x_regime)) %>%
  select(gwcode, country_id, year, country_name, v12pos, v12change)

all <- full_join(v9pos, v11pos) %>%
  full_join(v12pos) %>%
  filter(v9pos==1 | v11pos==1 | v12pos==1)
```

    ## Joining, by = c("gwcode", "country_id", "year", "country_name")
    ## Joining, by = c("gwcode", "country_id", "year", "country_name")

There was no V-Dem version 10 update for PART, so I will just compare
v9, v11, and v12 here.

Here is the first version change, from v9 to v11:

``` r
table(v9 = all$v9pos, v11 = all$v11pos)
```

    ##    v11
    ## v9    0   1
    ##   0  10  33
    ##   1  67 121

The joint 0 values here are because the v12 transitions are also in this
data frame, and must be transitions in v12 but not v9 or v11.

In any case, there are 222 RoW decreases between the v9 and v11 data,
but agreement in only 121 of those cases (55%).

That’s a challenge for assessing the accuracy of forecasts. In essence,
if we develop forecasts using the v9 V-Dem data, and then score it with
the v10 or v11 V-Dem data, the ground will have shifted under us. I’m
not sure that there is anything to do about this. We had the same
problem with the democratic spaces project and discussed this issue in
the spring of 2020 when we did the v10 update.

The underlying problem is that the RoW indicator depends on thresholds
in a variety of other indicators, and the values of those other
indicators shift slightly when the measurement models are re-run with
each data update. Even though such shifts might be miniscule, they can
in some cases cross a relevant threshold, thus changing the RoW
category.

Here is the agreement for the v11 and v12 data:

``` r
df <- all[all$v11pos==1 | all$v12pos==1, ]
with(df, table(v11 = v11pos, v12 = v12pos))
```

    ##    v12
    ## v11   0   1
    ##   0   0  13
    ##   1  17 137

There is more agreement. Of 168 joint transitions, 137 are in agreement
(82%). The disagreements are also more balanced now, whereas between v9
and v11, it seems like v9 was a lot more aggressive in coding
transitions than v11 is. We went from (33 + 67) / (33 + 67 + 121) = 45%
disagreement to now (13 + 17) / (13 + 17 + 137) a bit under 18%
disagreement.

Case counts by which version they show up in:

``` r
all %>%
  count(v12pos, v11pos, v9pos) %>%
  arrange(desc(v12pos), desc(v11pos), desc(v9pos)) %>%
  knitr::kable()
```

| v12pos | v11pos | v9pos |   n |
|-------:|-------:|------:|----:|
|      1 |      1 |     1 | 114 |
|      1 |      1 |     0 |  23 |
|      1 |      0 |     1 |   3 |
|      1 |      0 |     0 |  10 |
|      0 |      1 |     1 |   7 |
|      0 |      1 |     0 |  10 |
|      0 |      0 |     1 |  64 |
|     NA |     NA |     1 |   1 |

``` r
#' The case with missing values is Kosovo 2005, which was not an independent
#' state at the time yet.


#' Below is a table of positive cases in either dataset.

all %>%
  arrange(country_name, year) %>%
  knitr::kable()
```

| gwcode | country_id | year | country_name             | v9pos | v9change | v11pos | v11change | v12pos | v12change |
|-------:|-----------:|-----:|:-------------------------|------:|:---------|-------:|:----------|-------:|:----------|
|    700 |         36 | 1974 | Afghanistan              |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    339 |         12 | 2017 | Albania                  |     1 | 3-\>2    |      0 | 2-\>2     |      0 | 2-\>2     |
|    540 |        104 | 1993 | Angola                   |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    160 |         37 | 1976 | Argentina                |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    160 |         37 | 1977 | Argentina                |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    371 |        105 | 1995 | Armenia                  |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    771 |         24 | 1975 | Bangladesh               |     1 | 1-\>0    |      0 | 1-\>1     |      0 | 1-\>1     |
|    771 |         24 | 1976 | Bangladesh               |     0 | 0-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    771 |         24 | 1983 | Bangladesh               |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    771 |         24 | 2002 | Bangladesh               |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    771 |         24 | 2006 | Bangladesh               |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    771 |         24 | 2007 | Bangladesh               |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    771 |         24 | 2012 | Bangladesh               |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    370 |        107 | 1996 | Belarus                  |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    370 |        107 | 1997 | Belarus                  |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    434 |         52 | 2015 | Benin                    |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    145 |         25 | 1970 | Bolivia                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    145 |         25 | 1981 | Bolivia                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    571 |         68 | 2017 | Botswana                 |     1 | 3-\>2    |      1 | 3-\>2     |      0 | 3-\>3     |
|    439 |         54 | 1981 | Burkina Faso             |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    439 |         54 | 1999 | Burkina Faso             |     1 | 2-\>1    |      0 | 1-\>2     |      0 | 1-\>2     |
|    439 |         54 | 2003 | Burkina Faso             |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|    439 |         54 | 2015 | Burkina Faso             |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    516 |         69 | 1988 | Burundi                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    516 |         69 | 1996 | Burundi                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    811 |         55 | 1971 | Cambodia                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    811 |         55 | 1973 | Cambodia                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    402 |         70 | 1976 | Cape Verde               |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    402 |         70 | 2018 | Cape Verde               |     1 | 3-\>2    |      0 | 2-\>2     |      0 | 2-\>2     |
|    482 |         71 | 2004 | Central African Republic |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    155 |         72 | 1973 | Chile                    |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    155 |         72 | 1974 | Chile                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    155 |         72 | 2018 | Chile                    |     1 | 3-\>2    |      0 | 3-\>3     |      0 | 3-\>3     |
|    100 |         15 | 1977 | Colombia                 |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    100 |         15 | 1984 | Colombia                 |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    581 |        153 | 1978 | Comoros                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    581 |        153 | 2000 | Comoros                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    581 |        153 | 2015 | Comoros                  |     1 | 2-\>1    |      1 | 2-\>1     |      0 | 1-\>1     |
|    344 |        154 | 1999 | Croatia                  |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    522 |        113 | 1982 | Djibouti                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|     42 |        114 | 1987 | Dominican Republic       |     0 | 2-\>2    |      0 | 2-\>2     |      1 | 2-\>1     |
|     42 |        114 | 1990 | Dominican Republic       |     1 | 2-\>1    |      1 | 2-\>1     |      0 | 1-\>1     |
|    130 |         75 | 1972 | Ecuador                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    651 |         13 | 1993 | Egypt                    |     0 | 1-\>1    |      0 | 1-\>1     |      1 | 1-\>0     |
|    651 |         13 | 2013 | Egypt                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|     92 |         22 | 1980 | El Salvador              |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|     92 |         22 | 1997 | El Salvador              |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    411 |        160 | 1979 | Equatorial Guinea        |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    366 |        161 | 1992 | Estonia                  |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    950 |        162 | 1987 | Fiji                     |     1 | 2-\>0    |      1 | 2-\>0     |      1 | 2-\>0     |
|    950 |        162 | 2000 | Fiji                     |     1 | 2-\>0    |      1 | 2-\>0     |      1 | 2-\>0     |
|    950 |        162 | 2006 | Fiji                     |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    950 |        162 | 2007 | Fiji                     |     1 | 2-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    950 |        162 | 2016 | Fiji                     |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    452 |          7 | 1973 | Ghana                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    452 |          7 | 1981 | Ghana                    |     1 | 2-\>0    |      1 | 2-\>0     |      1 | 2-\>0     |
|    452 |          7 | 2015 | Ghana                    |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    350 |        164 | 2018 | Greece                   |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|     90 |         78 | 1983 | Guatemala                |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    438 |         63 | 2009 | Guinea                   |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    404 |        119 | 2008 | Guinea-Bissau            |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    404 |        119 | 2010 | Guinea-Bissau            |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    404 |        119 | 2013 | Guinea-Bissau            |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    404 |        119 | 2018 | Guinea-Bissau            |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|     41 |         26 | 1989 | Haiti                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|     41 |         26 | 1992 | Haiti                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|     41 |         26 | 2005 | Haiti                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|     91 |         27 | 1973 | Honduras                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|     91 |         27 | 2009 | Honduras                 |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    310 |        210 | 2006 | Hungary                  |     1 | 3-\>2    |      0 | 3-\>3     |      0 | 3-\>3     |
|    310 |        210 | 2010 | Hungary                  |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    310 |        210 | 2018 | Hungary                  |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    750 |         39 | 1975 | India                    |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    645 |         80 | 2000 | Iraq                     |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    645 |         80 | 2010 | Iraq                     |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    666 |        169 | 1976 | Israel                   |     1 | 3-\>2    |      0 | 3-\>3     |      0 | 3-\>3     |
|    666 |        169 | 2010 | Israel                   |     1 | 3-\>2    |      0 | 3-\>3     |      0 | 3-\>3     |
|    437 |         64 | 2014 | Ivory Coast              |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|     51 |        120 | 1974 | Jamaica                  |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|     51 |        120 | 1977 | Jamaica                  |     0 | 1-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|     51 |        120 | 1981 | Jamaica                  |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    501 |         40 | 2016 | Kenya                    |     0 | 1-\>2    |      1 | 2-\>1     |      0 | 2-\>2     |
|    501 |         40 | 2017 | Kenya                    |     1 | 2-\>1    |      0 | 1-\>1     |      1 | 2-\>1     |
|    732 |         43 | 2005 | Kosovo                   |     1 | 2-\>1    |     NA | NA        |     NA | NA        |
|    347 |         43 | 2011 | Kosovo                   |     0 | 1-\>2    |      1 | 2-\>1     |      0 | 1-\>1     |
|    347 |         43 | 2012 | Kosovo                   |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    703 |        122 | 2016 | Kyrgyzstan               |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    812 |        123 | 1975 | Laos                     |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    812 |        123 | 1991 | Laos                     |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    367 |         84 | 2013 | Latvia                   |     0 | 3-\>3    |      1 | 3-\>2     |      1 | 3-\>2     |
|    367 |         84 | 2016 | Latvia                   |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    660 |         44 | 2010 | Lebanon                  |     1 | 2-\>1    |      0 | 1-\>2     |      0 | 1-\>2     |
|    660 |         44 | 2018 | Lebanon                  |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    570 |         85 | 1971 | Lesotho                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    570 |         85 | 1995 | Lesotho                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    570 |         85 | 1999 | Lesotho                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    570 |         85 | 2017 | Lesotho                  |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|    450 |         86 | 1990 | Liberia                  |     1 | 1-\>0    |      0 | 1-\>1     |      0 | 1-\>1     |
|    450 |         86 | 1991 | Liberia                  |     0 | 0-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    450 |         86 | 2004 | Liberia                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    620 |        124 | 2014 | Libya                    |     1 | 2-\>0    |      1 | 2-\>0     |      1 | 2-\>0     |
|    368 |        173 | 2016 | Lithuania                |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    580 |        125 | 1972 | Madagascar               |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    580 |        125 | 2001 | Madagascar               |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    580 |        125 | 2008 | Madagascar               |     1 | 2-\>1    |      0 | 1-\>2     |      0 | 1-\>2     |
|    580 |        125 | 2009 | Madagascar               |     0 | 1-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    580 |        125 | 2010 | Madagascar               |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    553 |         87 | 1978 | Malawi                   |     1 | 1-\>0    |      1 | 1-\>0     |      0 | 1-\>1     |
|    553 |         87 | 1987 | Malawi                   |     1 | 1-\>0    |      0 | 1-\>1     |      1 | 1-\>0     |
|    553 |         87 | 2000 | Malawi                   |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    553 |         87 | 2004 | Malawi                   |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    820 |        177 | 1970 | Malaysia                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    781 |         88 | 2013 | Maldives                 |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    432 |         28 | 2012 | Mali                     |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    435 |         65 | 1975 | Mauritania               |     0 | 0-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    435 |         65 | 2006 | Mauritania               |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    435 |         65 | 2008 | Mauritania               |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    590 |        180 | 2017 | Mauritius                |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    359 |        126 | 2005 | Moldova                  |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    359 |        126 | 2008 | Moldova                  |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    341 |        183 | 2006 | Montenegro               |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    341 |        183 | 2010 | Montenegro               |     1 | 2-\>1    |      0 | 1-\>2     |      0 | 1-\>2     |
|    341 |        183 | 2013 | Montenegro               |     0 | 1-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    341 |        183 | 2016 | Montenegro               |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    565 |        127 | 1994 | Namibia                  |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    565 |        127 | 2012 | Namibia                  |     1 | 3-\>2    |      0 | 2-\>2     |      0 | 2-\>2     |
|    565 |        127 | 2017 | Namibia                  |     1 | 3-\>2    |      0 | 2-\>2     |      0 | 2-\>2     |
|    790 |         58 | 2002 | Nepal                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    790 |         58 | 2012 | Nepal                    |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|     93 |         59 | 1974 | Nicaragua                |     1 | 1-\>0    |      0 | 1-\>1     |      0 | 1-\>1     |
|     93 |         59 | 1979 | Nicaragua                |     0 | 0-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|     93 |         59 | 2007 | Nicaragua                |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    436 |         60 | 1996 | Niger                    |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    436 |         60 | 2009 | Niger                    |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    436 |         60 | 2010 | Niger                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    475 |         45 | 1984 | Nigeria                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    475 |         45 | 1994 | Nigeria                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    475 |         45 | 2003 | Nigeria                  |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    343 |        176 | 2000 | North Macedonia          |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    343 |        176 | 2011 | North Macedonia          |     0 | 2-\>2    |      0 | 2-\>2     |      1 | 2-\>1     |
|    343 |        176 | 2012 | North Macedonia          |     1 | 2-\>1    |      1 | 2-\>1     |      0 | 1-\>1     |
|    770 |         29 | 1978 | Pakistan                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    770 |         29 | 1999 | Pakistan                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    770 |         29 | 2013 | Pakistan                 |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    910 |         93 | 1992 | Papua New Guinea         |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|    910 |         93 | 1997 | Papua New Guinea         |     0 | 1-\>1    |      1 | 2-\>1     |      0 | 2-\>2     |
|    910 |         93 | 2004 | Papua New Guinea         |     0 | 1-\>1    |      1 | 2-\>1     |      0 | 2-\>2     |
|    910 |         93 | 2007 | Papua New Guinea         |     0 | 1-\>1    |      0 | 1-\>1     |      1 | 2-\>1     |
|    135 |         30 | 1992 | Peru                     |     1 | 2-\>0    |      1 | 2-\>0     |      1 | 2-\>0     |
|    840 |         46 | 1972 | Philippines              |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    840 |         46 | 1981 | Philippines              |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    840 |         46 | 2004 | Philippines              |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    840 |         46 | 2018 | Philippines              |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    290 |         17 | 2015 | Poland                   |     1 | 3-\>2    |      0 | 3-\>3     |      0 | 3-\>3     |
|    290 |         17 | 2016 | Poland                   |     0 | 2-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    484 |        112 | 1997 | Republic of the Congo    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    365 |         11 | 1993 | Russia                   |     0 | 1-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    365 |         11 | 1996 | Russia                   |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    517 |        129 | 1974 | Rwanda                   |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    433 |         31 | 1982 | Senegal                  |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    340 |        198 | 2013 | Serbia                   |     0 | 2-\>2    |      1 | 2-\>1     |      0 | 2-\>2     |
|    340 |        198 | 2014 | Serbia                   |     0 | 2-\>2    |      0 | 1-\>1     |      1 | 2-\>1     |
|    340 |        198 | 2015 | Serbia                   |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    451 |         95 | 1993 | Sierra Leone             |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    451 |         95 | 1998 | Sierra Leone             |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    317 |        201 | 2013 | Slovakia                 |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    940 |        203 | 1981 | Solomon Islands          |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|    940 |        203 | 1990 | Solomon Islands          |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|    940 |        203 | 2000 | Solomon Islands          |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    940 |        203 | 2006 | Solomon Islands          |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    520 |        130 | 1970 | Somalia                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    520 |        130 | 1984 | Somalia                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    560 |          8 | 1985 | South Africa             |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    560 |          8 | 2007 | South Africa             |     1 | 3-\>2    |      0 | 3-\>3     |      0 | 3-\>3     |
|    560 |          8 | 2013 | South Africa             |     1 | 3-\>2    |      1 | 3-\>2     |      1 | 3-\>2     |
|    732 |         42 | 2018 | South Korea              |     1 | 3-\>2    |      0 | 3-\>3     |      0 | 3-\>3     |
|    780 |        131 | 1982 | Sri Lanka                |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    780 |        131 | 2005 | Sri Lanka                |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    625 |         33 | 1977 | Sudan                    |     1 | 1-\>0    |      0 | 1-\>1     |      0 | 1-\>1     |
|    625 |         33 | 1985 | Sudan                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    625 |         33 | 1990 | Sudan                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    115 |          4 | 1980 | Suriname                 |     1 | 2-\>0    |      1 | 2-\>0     |      1 | 2-\>0     |
|    115 |          4 | 1991 | Suriname                 |     0 | 2-\>2    |      1 | 2-\>1     |      1 | 2-\>1     |
|    652 |         97 | 2013 | Syria                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    713 |         48 | 2010 | Taiwan                   |     1 | 3-\>2    |      0 | 3-\>3     |      0 | 3-\>3     |
|    510 |         47 | 2000 | Tanzania                 |     0 | 2-\>2    |      0 | 2-\>2     |      1 | 2-\>1     |
|    510 |         47 | 2001 | Tanzania                 |     1 | 2-\>1    |      1 | 2-\>1     |      0 | 1-\>1     |
|    510 |         47 | 2009 | Tanzania                 |     1 | 2-\>1    |      1 | 2-\>1     |      0 | 1-\>1     |
|    510 |         47 | 2015 | Tanzania                 |     0 | 2-\>2    |      1 | 2-\>1     |      0 | 1-\>1     |
|    510 |         47 | 2016 | Tanzania                 |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    800 |         49 | 1977 | Thailand                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    800 |         49 | 1991 | Thailand                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    800 |         49 | 2000 | Thailand                 |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|    800 |         49 | 2006 | Thailand                 |     1 | 2-\>0    |      1 | 2-\>1     |      1 | 2-\>1     |
|    800 |         49 | 2007 | Thailand                 |     0 | 0-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    800 |         49 | 2013 | Thailand                 |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    800 |         49 | 2014 | Thailand                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    420 |        117 | 1972 | The Gambia               |     0 | 2-\>2    |      1 | 2-\>1     |      0 | 1-\>1     |
|    420 |        117 | 1978 | The Gambia               |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    420 |        117 | 1990 | The Gambia               |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    420 |        117 | 1995 | The Gambia               |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    461 |        134 | 2010 | Togo                     |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    461 |        134 | 2017 | Togo                     |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    616 |         98 | 1974 | Tunisia                  |     1 | 1-\>0    |      0 | 1-\>1     |      0 | 1-\>1     |
|    616 |         98 | 1987 | Tunisia                  |     0 | 0-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    616 |         98 | 2018 | Tunisia                  |     1 | 3-\>2    |      0 | 2-\>2     |      0 | 2-\>2     |
|    640 |         99 | 1980 | Turkey                   |     1 | 2-\>0    |      1 | 2-\>1     |      1 | 2-\>1     |
|    640 |         99 | 1981 | Turkey                   |     0 | 0-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    640 |         99 | 2013 | Turkey                   |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    701 |        136 | 2012 | Turkmenistan             |     1 | 1-\>0    |      0 | 1-\>1     |      0 | 1-\>1     |
|    500 |         50 | 1985 | Uganda                   |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    500 |         50 | 1994 | Uganda                   |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    369 |        100 | 1998 | Ukraine                  |     1 | 2-\>1    |      1 | 2-\>1     |      1 | 2-\>1     |
|    369 |        100 | 2010 | Ukraine                  |     0 | 2-\>2    |      0 | 2-\>2     |      1 | 2-\>1     |
|    369 |        100 | 2011 | Ukraine                  |     0 | 2-\>2    |      1 | 2-\>1     |      0 | 1-\>1     |
|    369 |        100 | 2012 | Ukraine                  |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    165 |        102 | 1972 | Uruguay                  |     1 | 2-\>1    |      0 | 2-\>2     |      1 | 2-\>1     |
|    165 |        102 | 1973 | Uruguay                  |     1 | 1-\>0    |      1 | 2-\>0     |      1 | 1-\>0     |
|    704 |        140 | 2014 | Uzbekistan               |     0 | 0-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    101 |         51 | 2002 | Venezuela                |     0 | 2-\>2    |      0 | 2-\>2     |      1 | 2-\>1     |
|    101 |         51 | 2003 | Venezuela                |     0 | 2-\>2    |      1 | 2-\>1     |      0 | 1-\>1     |
|    101 |         51 | 2006 | Venezuela                |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    816 |         34 | 1977 | Vietnam                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    816 |         34 | 2016 | Vietnam                  |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    678 |         14 | 2016 | Yemen                    |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
|    551 |         61 | 1996 | Zambia                   |     0 | 2-\>2    |      0 | 1-\>1     |      1 | 2-\>1     |
|    551 |         61 | 1997 | Zambia                   |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    551 |         61 | 2005 | Zambia                   |     1 | 2-\>1    |      0 | 2-\>2     |      0 | 2-\>2     |
|    551 |         61 | 2013 | Zambia                   |     0 | 2-\>2    |      0 | 2-\>2     |      1 | 2-\>1     |
|    551 |         61 | 2014 | Zambia                   |     0 | 2-\>2    |      1 | 2-\>1     |      0 | 1-\>1     |
|    551 |         61 | 2015 | Zambia                   |     1 | 2-\>1    |      0 | 1-\>1     |      0 | 1-\>1     |
|    552 |         62 | 1978 | Zimbabwe                 |     1 | 1-\>0    |      1 | 1-\>0     |      1 | 1-\>0     |
