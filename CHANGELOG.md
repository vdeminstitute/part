2021 Update (v11)
=================

- Take out cross-validation fit exercises to speed up model runtime. 
- Comparison of v9 and v11 positive cases. There are substantial differences. 
- Tweaked RF model hyperparameter tuning based on tuning experiments; use 1000 trees but tune mtry, min.node.size, and sample.fraction.
- Change glmnet tuning metric (model3) from logloss to brier (all others are brier).

### Add versioning system. 

For the 2021 update, I (AB) added an explicit versioning for key files that matches the version of the V-Dem data used in that year's forecasts. 

- Key files--the `part` merge data and the actual forecasts--now include a version suffix in the filename. 
- Copies of the key files and associated summary statistics are now preserved in the `archive/` folder. I moved the 2019 forecasts from `forecasts/` to the archive folder. 

There was no 2020 forecast update; this is the first change since the original project development in 2018 and early 2019. 

2019 initial version (v9)
=========================

The project was developed in 2018 and 2019 by Rick Morgan and Andreas Beger. We initially used the v8 version of V-Dem. In the spring of 2019 we switched over to v9 and presented the forecasts as the May 2019 policy day. 
