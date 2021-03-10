2021 Update (v11)
=================

- Take out cross-validation fit exercises to speed up model runtime. 
- Comparison of v9 and v11 positive cases. There are substantial differences. 
- Tweaked RF model hyperparameter tuning based on tuning experiments; use 1000 trees but tune mtry, min.node.size, and sample.fraction.
- Change glmnet tuning metric (model3) from logloss to brier (all others are brier).

- The v9 PART data version had a mistake in the coding of the outcome variable "any_neg_change_2yr" for the second to last year in that data. The outcome indicates whether there was a negative regime change in the corresponding year or the subsequent year. I.e. the value for a row with year 2018 should indicate whether RoW decreased from 2017 to 2018, or from 2018 to 2019, which corresponds to values of "1" for "any_neg_change" in the rows with years 2018 and 2019. The v9 PART data was created in the spring of 2019 with last observed "v2x_regime" values in 2018. The 2018 values for "any_neg_change_2yr" thus pertain to observed RoW changes in the years 2018 or 2019. Since the 2019 RoW values were not observed at the time, this should have been missing. Instead it was coded based solely using the observed 2018 changes, with 7 observed positives. The hypothetical real number of positives probably was higher. This has been fixed in the data generating script now and as a result, "any_neg_change_2yr" is now missing entirely for the last 2 years in the data, i.e. `TARGET_YEAR` and the preceding year. 

### Add versioning system. 

For the 2021 update, I (AB) added an explicit versioning for key files that matches the version of the V-Dem data used in that year's forecasts. 

- Key files--the `part` merge data and the actual forecasts--now include a version suffix in the filename. 
- Copies of the key files and associated summary statistics are now preserved in the `archive/` folder. I moved the 2019 forecasts from `forecasts/` to the archive folder. 

There was no 2020 forecast update; this is the first change since the original project development in 2018 and early 2019. 

2019 initial version (v9)
=========================

The project was developed in 2018 and 2019 by Rick Morgan and Andreas Beger. We initially used the v8 version of V-Dem. In the spring of 2019 we switched over to v9 and presented the forecasts as the May 2019 policy day. 
