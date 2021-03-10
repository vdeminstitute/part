Comparing v9 and v11 RoW changes
================

Andreas Beger  
2021-03-10

There are substantial differences in the sets of identified negative
Regimes of the World (RoW) indicator changes between the v9 and v11
version of the V-Dem data.

The v9 and v11 versions of the RoW change data range jointly from 1970
to 2019. The v9 version has 189 negative RoW changes in that period; v11
has 160. Furthermore, the sets of cases identified are quite different:

    ##    v11
    ## v9    0   1
    ##   0   0  30
    ##   1  66 120

Only 120 cases are identified in both. The v9 data has 66 changes that
are not in v11 and vice versa there are 30 in v11 that are not in v9.

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

Below is a table of positive cases in either dataset.

| gwcode | country\_id | year | country\_name            | v9pos | v9change | v11pos | v11change | category |
| -----: | ----------: | ---: | :----------------------- | ----: | :------- | -----: | :-------- | :------- |
|    115 |           4 | 1980 | Suriname                 |     1 | 2-\>0    |      1 | 2-\>0     | in both  |
|    115 |           4 | 1991 | Suriname                 |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    452 |           7 | 1973 | Ghana                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    452 |           7 | 1981 | Ghana                    |     1 | 2-\>0    |      1 | 2-\>0     | in both  |
|    452 |           7 | 2015 | Ghana                    |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    560 |           8 | 1985 | South Africa             |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    560 |           8 | 2007 | South Africa             |     1 | 3-\>2    |      0 | 3-\>3     | only v9  |
|    560 |           8 | 2013 | South Africa             |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    365 |          11 | 1993 | Russia                   |     0 | 1-\>1    |      1 | 2-\>1     | only v11 |
|    365 |          11 | 1996 | Russia                   |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    339 |          12 | 2017 | Albania                  |     1 | 3-\>2    |      0 | 2-\>2     | only v9  |
|    339 |          12 | 2019 | Albania                  |    NA | 3-\>NA   |      1 | 2-\>1     | missing  |
|    651 |          13 | 2013 | Egypt                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    678 |          14 | 2016 | Yemen                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    100 |          15 | 1977 | Colombia                 |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    100 |          15 | 1984 | Colombia                 |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    290 |          17 | 2015 | Poland                   |     1 | 3-\>2    |      0 | 3-\>3     | only v9  |
|    290 |          17 | 2016 | Poland                   |     0 | 2-\>2    |      1 | 3-\>2     | only v11 |
|     92 |          22 | 1980 | El Salvador              |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|     92 |          22 | 1997 | El Salvador              |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    771 |          24 | 1975 | Bangladesh               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    771 |          24 | 1983 | Bangladesh               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    771 |          24 | 2002 | Bangladesh               |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    771 |          24 | 2006 | Bangladesh               |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    771 |          24 | 2007 | Bangladesh               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    771 |          24 | 2012 | Bangladesh               |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    145 |          25 | 1970 | Bolivia                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    145 |          25 | 1981 | Bolivia                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    145 |          25 | 2019 | Bolivia                  |    NA | 2-\>NA   |      1 | 2-\>1     | missing  |
|     41 |          26 | 1989 | Haiti                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|     41 |          26 | 1992 | Haiti                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|     41 |          26 | 2005 | Haiti                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|     91 |          27 | 1973 | Honduras                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|     91 |          27 | 2009 | Honduras                 |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    432 |          28 | 2012 | Mali                     |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    432 |          28 | 2019 | Mali                     |    NA | 2-\>NA   |      1 | 2-\>1     | missing  |
|    770 |          29 | 1978 | Pakistan                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    770 |          29 | 1999 | Pakistan                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    770 |          29 | 2013 | Pakistan                 |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    135 |          30 | 1992 | Peru                     |     1 | 2-\>0    |      1 | 2-\>0     | in both  |
|    433 |          31 | 1982 | Senegal                  |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    625 |          33 | 1977 | Sudan                    |     1 | 1-\>0    |      0 | 1-\>1     | only v9  |
|    625 |          33 | 1985 | Sudan                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    625 |          33 | 1990 | Sudan                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    625 |          33 | 2019 | Sudan                    |    NA | 1-\>NA   |      1 | 1-\>0     | missing  |
|    816 |          34 | 1977 | Vietnam                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    816 |          34 | 2016 | Vietnam                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    700 |          36 | 1974 | Afghanistan              |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    160 |          37 | 1976 | Argentina                |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    160 |          37 | 1977 | Argentina                |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    750 |          39 | 1975 | India                    |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    750 |          39 | 2019 | India                    |    NA | 2-\>NA   |      1 | 2-\>1     | missing  |
|    501 |          40 | 2016 | Kenya                    |     0 | 1-\>2    |      1 | 2-\>1     | only v11 |
|    501 |          40 | 2017 | Kenya                    |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    732 |          42 | 2018 | South Korea              |     1 | 3-\>2    |      0 | 3-\>3     | only v9  |
|    732 |          43 | 2005 | Kosovo                   |     1 | 2-\>1    |     NA | NA        | missing  |
|    347 |          43 | 2011 | Kosovo                   |     0 | 1-\>2    |      1 | 2-\>1     | only v11 |
|    347 |          43 | 2012 | Kosovo                   |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    660 |          44 | 2010 | Lebanon                  |     1 | 2-\>1    |      0 | 1-\>2     | only v9  |
|    660 |          44 | 2018 | Lebanon                  |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    475 |          45 | 1984 | Nigeria                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    475 |          45 | 1994 | Nigeria                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    475 |          45 | 2003 | Nigeria                  |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    840 |          46 | 1972 | Philippines              |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    840 |          46 | 1981 | Philippines              |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    840 |          46 | 2004 | Philippines              |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    840 |          46 | 2018 | Philippines              |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    510 |          47 | 2001 | Tanzania                 |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    510 |          47 | 2009 | Tanzania                 |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    510 |          47 | 2015 | Tanzania                 |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    510 |          47 | 2016 | Tanzania                 |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    713 |          48 | 2010 | Taiwan                   |     1 | 3-\>2    |      0 | 3-\>3     | only v9  |
|    800 |          49 | 1977 | Thailand                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    800 |          49 | 1991 | Thailand                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    800 |          49 | 2000 | Thailand                 |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|    800 |          49 | 2006 | Thailand                 |     1 | 2-\>0    |      1 | 2-\>0     | in both  |
|    800 |          49 | 2013 | Thailand                 |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    800 |          49 | 2014 | Thailand                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    500 |          50 | 1985 | Uganda                   |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    500 |          50 | 1994 | Uganda                   |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    101 |          51 | 2003 | Venezuela                |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    101 |          51 | 2006 | Venezuela                |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    434 |          52 | 2015 | Benin                    |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    434 |          52 | 2019 | Benin                    |    NA | 3-\>NA   |      1 | 2-\>1     | missing  |
|    439 |          54 | 1981 | Burkina Faso             |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    439 |          54 | 1999 | Burkina Faso             |     1 | 2-\>1    |      0 | 1-\>2     | only v9  |
|    439 |          54 | 2003 | Burkina Faso             |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|    439 |          54 | 2015 | Burkina Faso             |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    811 |          55 | 1971 | Cambodia                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    811 |          55 | 1973 | Cambodia                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    790 |          58 | 2002 | Nepal                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    790 |          58 | 2012 | Nepal                    |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|     93 |          59 | 1974 | Nicaragua                |     1 | 1-\>0    |      0 | 1-\>1     | only v9  |
|     93 |          59 | 1979 | Nicaragua                |     0 | 0-\>0    |      1 | 1-\>0     | only v11 |
|     93 |          59 | 2007 | Nicaragua                |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    436 |          60 | 1996 | Niger                    |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    436 |          60 | 2009 | Niger                    |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    436 |          60 | 2010 | Niger                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    551 |          61 | 1997 | Zambia                   |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    551 |          61 | 2005 | Zambia                   |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|    551 |          61 | 2014 | Zambia                   |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    551 |          61 | 2015 | Zambia                   |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    552 |          62 | 1978 | Zimbabwe                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    438 |          63 | 2009 | Guinea                   |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    437 |          64 | 2014 | Ivory Coast              |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    435 |          65 | 1975 | Mauritania               |     0 | 0-\>0    |      1 | 1-\>0     | only v11 |
|    435 |          65 | 2006 | Mauritania               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    435 |          65 | 2008 | Mauritania               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    571 |          68 | 2017 | Botswana                 |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    516 |          69 | 1988 | Burundi                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    516 |          69 | 1996 | Burundi                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    402 |          70 | 1976 | Cape Verde               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    402 |          70 | 2018 | Cape Verde               |     1 | 3-\>2    |      0 | 2-\>2     | only v9  |
|    482 |          71 | 2004 | Central African Republic |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    155 |          72 | 1973 | Chile                    |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    155 |          72 | 1974 | Chile                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    155 |          72 | 2018 | Chile                    |     1 | 3-\>2    |      0 | 3-\>3     | only v9  |
|    155 |          72 | 2019 | Chile                    |    NA | 2-\>NA   |      1 | 3-\>2     | missing  |
|    130 |          75 | 1972 | Ecuador                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|     90 |          78 | 1983 | Guatemala                |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    645 |          80 | 2000 | Iraq                     |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    645 |          80 | 2010 | Iraq                     |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    367 |          84 | 2013 | Latvia                   |     0 | 3-\>3    |      1 | 3-\>2     | only v11 |
|    367 |          84 | 2016 | Latvia                   |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    570 |          85 | 1971 | Lesotho                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    570 |          85 | 1995 | Lesotho                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    570 |          85 | 1999 | Lesotho                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    570 |          85 | 2017 | Lesotho                  |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|    450 |          86 | 1990 | Liberia                  |     1 | 1-\>0    |      0 | 1-\>1     | only v9  |
|    450 |          86 | 1991 | Liberia                  |     0 | 0-\>0    |      1 | 1-\>0     | only v11 |
|    450 |          86 | 2004 | Liberia                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    553 |          87 | 1978 | Malawi                   |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    553 |          87 | 1987 | Malawi                   |     1 | 1-\>0    |      0 | 1-\>1     | only v9  |
|    553 |          87 | 2000 | Malawi                   |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    553 |          87 | 2004 | Malawi                   |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    553 |          87 | 2019 | Malawi                   |    NA | 2-\>NA   |      1 | 2-\>1     | missing  |
|    781 |          88 | 2013 | Maldives                 |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    910 |          93 | 1992 | Papua New Guinea         |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|    910 |          93 | 1997 | Papua New Guinea         |     0 | 1-\>1    |      1 | 2-\>1     | only v11 |
|    910 |          93 | 2004 | Papua New Guinea         |     0 | 1-\>1    |      1 | 2-\>1     | only v11 |
|    451 |          95 | 1993 | Sierra Leone             |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    451 |          95 | 1998 | Sierra Leone             |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    652 |          97 | 2013 | Syria                    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    616 |          98 | 1974 | Tunisia                  |     1 | 1-\>0    |      0 | 1-\>1     | only v9  |
|    616 |          98 | 1987 | Tunisia                  |     0 | 0-\>0    |      1 | 1-\>0     | only v11 |
|    616 |          98 | 2018 | Tunisia                  |     1 | 3-\>2    |      0 | 2-\>2     | only v9  |
|    640 |          99 | 1980 | Turkey                   |     1 | 2-\>0    |      1 | 2-\>0     | in both  |
|    640 |          99 | 2013 | Turkey                   |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    369 |         100 | 1998 | Ukraine                  |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    369 |         100 | 2011 | Ukraine                  |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    369 |         100 | 2012 | Ukraine                  |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    165 |         102 | 1972 | Uruguay                  |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|    165 |         102 | 1973 | Uruguay                  |     1 | 1-\>0    |      1 | 2-\>0     | in both  |
|    540 |         104 | 1993 | Angola                   |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    371 |         105 | 1995 | Armenia                  |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    370 |         107 | 1996 | Belarus                  |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    370 |         107 | 1997 | Belarus                  |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    484 |         112 | 1997 | Republic of the Congo    |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    522 |         113 | 1982 | Djibouti                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|     42 |         114 | 1990 | Dominican Republic       |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    420 |         117 | 1972 | The Gambia               |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    420 |         117 | 1978 | The Gambia               |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    420 |         117 | 1990 | The Gambia               |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    420 |         117 | 1995 | The Gambia               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    404 |         119 | 2008 | Guinea-Bissau            |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    404 |         119 | 2010 | Guinea-Bissau            |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    404 |         119 | 2013 | Guinea-Bissau            |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    404 |         119 | 2018 | Guinea-Bissau            |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|     51 |         120 | 1974 | Jamaica                  |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|     51 |         120 | 1977 | Jamaica                  |     0 | 1-\>1    |      1 | 2-\>1     | only v11 |
|     51 |         120 | 1981 | Jamaica                  |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    703 |         122 | 2016 | Kyrgyzstan               |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    812 |         123 | 1975 | Laos                     |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    812 |         123 | 1991 | Laos                     |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    620 |         124 | 2014 | Libya                    |     1 | 2-\>0    |      1 | 2-\>0     | in both  |
|    580 |         125 | 1972 | Madagascar               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    580 |         125 | 2001 | Madagascar               |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    580 |         125 | 2008 | Madagascar               |     1 | 2-\>1    |      0 | 1-\>2     | only v9  |
|    580 |         125 | 2009 | Madagascar               |     0 | 1-\>1    |      1 | 2-\>1     | only v11 |
|    580 |         125 | 2010 | Madagascar               |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    359 |         126 | 2005 | Moldova                  |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    359 |         126 | 2008 | Moldova                  |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    565 |         127 | 1994 | Namibia                  |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    565 |         127 | 2012 | Namibia                  |     1 | 3-\>2    |      0 | 2-\>2     | only v9  |
|    565 |         127 | 2017 | Namibia                  |     1 | 3-\>2    |      0 | 2-\>2     | only v9  |
|    517 |         129 | 1974 | Rwanda                   |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    520 |         130 | 1970 | Somalia                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    520 |         130 | 1984 | Somalia                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    780 |         131 | 1982 | Sri Lanka                |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    780 |         131 | 2005 | Sri Lanka                |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    461 |         134 | 2010 | Togo                     |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    461 |         134 | 2017 | Togo                     |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    701 |         136 | 2012 | Turkmenistan             |     1 | 1-\>0    |      0 | 1-\>1     | only v9  |
|    704 |         140 | 2014 | Uzbekistan               |     0 | 0-\>0    |      1 | 1-\>0     | only v11 |
|    581 |         153 | 1978 | Comoros                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    581 |         153 | 2000 | Comoros                  |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    581 |         153 | 2015 | Comoros                  |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    344 |         154 | 1999 | Croatia                  |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    411 |         160 | 1979 | Equatorial Guinea        |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    366 |         161 | 1992 | Estonia                  |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    950 |         162 | 1987 | Fiji                     |     1 | 2-\>0    |      1 | 2-\>0     | in both  |
|    950 |         162 | 2000 | Fiji                     |     1 | 2-\>0    |      1 | 2-\>0     | in both  |
|    950 |         162 | 2006 | Fiji                     |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    950 |         162 | 2007 | Fiji                     |     1 | 2-\>0    |      1 | 1-\>0     | in both  |
|    950 |         162 | 2016 | Fiji                     |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    350 |         164 | 2018 | Greece                   |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    666 |         169 | 1976 | Israel                   |     1 | 3-\>2    |      0 | 3-\>3     | only v9  |
|    666 |         169 | 2010 | Israel                   |     1 | 3-\>2    |      0 | 3-\>3     | only v9  |
|    368 |         173 | 2016 | Lithuania                |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    343 |         176 | 2000 | Macedonia                |     1 | 2-\>1    |     NA | NA        | missing  |
|    343 |         176 | 2012 | Macedonia                |     1 | 2-\>1    |     NA | NA        | missing  |
|    820 |         177 | 1970 | Malaysia                 |     1 | 1-\>0    |      1 | 1-\>0     | in both  |
|    590 |         180 | 2017 | Mauritius                |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    341 |         183 | 2006 | Montenegro               |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    341 |         183 | 2010 | Montenegro               |     1 | 2-\>1    |      0 | 1-\>2     | only v9  |
|    341 |         183 | 2013 | Montenegro               |     0 | 1-\>1    |      1 | 2-\>1     | only v11 |
|    341 |         183 | 2016 | Montenegro               |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    340 |         198 | 2013 | Serbia                   |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    340 |         198 | 2015 | Serbia                   |     1 | 2-\>1    |      0 | 1-\>1     | only v9  |
|    317 |         201 | 2013 | Slovakia                 |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    940 |         203 | 1981 | Solomon Islands          |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|    940 |         203 | 1990 | Solomon Islands          |     1 | 2-\>1    |      0 | 2-\>2     | only v9  |
|    940 |         203 | 2000 | Solomon Islands          |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    940 |         203 | 2006 | Solomon Islands          |     1 | 2-\>1    |      1 | 2-\>1     | in both  |
|    310 |         210 | 2006 | Hungary                  |     1 | 3-\>2    |      0 | 3-\>3     | only v9  |
|    310 |         210 | 2010 | Hungary                  |     1 | 3-\>2    |      1 | 3-\>2     | in both  |
|    310 |         210 | 2018 | Hungary                  |     0 | 2-\>2    |      1 | 2-\>1     | only v11 |
|    343 |         176 | 2000 | North Macedonia          |    NA | NA       |      1 | 2-\>1     | missing  |
|    343 |         176 | 2012 | North Macedonia          |    NA | NA       |      1 | 2-\>1     | missing  |
