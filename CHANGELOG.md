2021 Update (v11)
=================

Work done in the spring of 2021 to produce updated forecasts for 2021-2022 for the risk of adverse regime transitions (ARTs), i.e. steps down in the 4 category V-Dem regimes of the world scheme. 

Along the way, I made major, non-substantive changes to the forecast that _greatly_ speed up the total model runtime. Although it's hard to attribute any changes in performance in the test forecasts to this as opposed to changes in the updated data with V-Dem v11 data, the test forecast performance did not decrease. 

In fact, if we compare the v9 and v11 `test-perf.md` tables in `Models/output/tables`, the apparent accuracy of the ensemble model (mdl 6) and the models that feed into it (models 3-5) actually slightly increases. E.g. AUC-PR, which showed the biggest shift, increased from 0.38 to 0.45. 

### Simplify models to speed up runtime

I made various changes to the models that collectively speed up runtime from something on the order of 36 hours for all 6 models (I'm estimating, as I never ran all 6 original versions for the 2021 update) previously to now under 1 hour. Models 1, 2, and 6 are quick; model 3 (glmnet) now runs in 12 minutes, model 4 (random forest) in 8m, and model 5 (xgboost) in 2m. 

I did this by:

- Taking out the cross-validation exercises. Previously we had, in addition to the test forecasts, cross-validation on the original non-test forecast training data as an additional out-of-sample data point. These ran _very_ slowly, but since we have many years of test forecasts, it did not seem necessary. 
- Manually tuning the 3 models with hyperparameters (glmnet, ranger, xgboost) and using fixed hyperparameters derived from these tuning experiments in the actual test and live forecast models. 

Two other minor changes in the models were to:

- Change glmnet tuning metric (model3) from logloss to brier (all others are brier).
- Adding a RNG seed for the random forest and xgboost models so that the forecasts are now fully reproducible. 

### Fix outcome coding issue in PART data

The v9 PART data version had a mistake in the coding of the outcome variable "any_neg_change_2yr" for the second to last year in that data. The outcome indicates whether there was a negative regime change in the corresponding year or the subsequent year. I.e. the value for a row with year 2018 should indicate whether RoW decreased from 2017 to 2018, or from 2018 to 2019, which corresponds to values of "1" for "any_neg_change" in the rows with years 2018 and 2019. The v9 PART data was created in the spring of 2019 with last observed "v2x_regime" values in 2018. The 2018 values for "any_neg_change_2yr" thus pertain to observed RoW changes in the years 2018 or 2019. Since the 2019 RoW values were not observed at the time, this should have been missing. Instead it was coded based solely using the observed 2018 changes, with 7 observed positives. The hypothetical real number of positives probably was higher. This has been fixed in the data generating script now and as a result, "any_neg_change_2yr" is now missing entirely for the last 2 years in the data, i.e. `TARGET_YEAR` and the preceding year. 

### Dashboard

Substantial cleaning up in the dashboard. Switched the spatial over to **sf**, streamlining here and there to reduce data sizes and dashboard responsiveness. Added instructions to make it easier to run a preview dashboard locally. 

The new app tarball is 680 KB in size (recording this in case there are future changes). 

### Add versioning system. 

For the 2021 update, I (AB) added an explicit versioning for key files that matches the version of the V-Dem data used in that year's forecasts. 

- Key files--the `part` merge data and the actual forecasts--now include a version suffix in the filename. 
- Copies of the key files and associated summary statistics are now preserved in the `archive/` folder. 

There was no 2020 forecast update; this is the first change since the original project development in 2018 and early 2019. 

### Other changes

- Added a folder with more details on the 2021 update, in `2021-update/`. 
- Comparison of v9 and v11 positive cases. There are substantial differences. See the outcome version comparison in the `2021-update` folder. 


2019 initial version (v9)
=========================

The project was developed in 2018 and 2019 by Rick Morgan and Andreas Beger. We initially used the v8 version of V-Dem. In the spring of 2019 we switched over to v9 and presented the forecasts as the May 2019 policy day. 
