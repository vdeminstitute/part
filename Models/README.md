Forecast (and tuning) models
============================

Scripts etc. to run the forecast models. They key output are the two `mdl6_` RDS files in [output/predictions/](output/predictions/).

See [run-forecasts.R](run-forecasts.R) for running the forecast models.

`scripts/` also contains files for running experiments to investigate hyperparameter tuning for the glmnet, random forest (ranger), and xgboost models. The actual forecast scripts use fixed hyperparameters derived from these experiments.

