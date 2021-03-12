Updating
========

This note has the rough workflow for updating the forecasts with a new year's worth of data. 

All lines that need specific updates, e.g. version numbers and the target year to which we want to build data, are marked with the string `UPDATE:` (including the colon). 

At various points there are some YAML and CSV files written out specifically with the purpose to make it easier to identify changes and thus potential errors by checking differences on git. The GitHub Desktop app makes this really easy. Check those.  

The repo is organized into the 3 main tasks that need to be done: (1) build the merged PART data, (2) run the forecast models, and (3) the dashboard. Each task folder is written to be self-contained, and _it will not automatically update its necessary inputs_. That is intentional. For example, the forecast models use data in `Models/input/part-v{X}.csv`, but when updating the data in `create-data` it will not automatically be copied and updated from `create-data/output`. 

Workflow to update the forecasts:

- In `create-data`:
    - Update the input data sources in the `input` folder. The scripts needed to update them are in the `demspaces` repo. 
    - Run through the scripts in the order indicated. It's likely that there will have been slight changes in the various respective data sources and that some manual adjustments will be necessary. 
    - _Manually_ copy the new, versioned PART data (`part-v{X}.csv`) to both the `archive/` and `Models/input` folders. 
- In `Models`:
    - Minimally, run the models using `scripts/train-model[1-6].R`. Some of these might take a few hours to run, even in parallel. If running as an RStudio job, it may be necessary to manually run `scripts/assess-model.R` after each model, in which case `model_prefix <- "mdl[1-6]"` should also be manually set. 
    - The final forecasts come from the ensemble model in `scripts/train-model6.R`. This will write a more git-friendly version of the forecasts to `archive`. 
    - _Manually_ ... TODO:
- In `dashboard`:
    - ... TODO:
    
    
## Things to improve in the next cycle

Ideas for what to improve in the next update cycle. 

The models are still overly complicated. Do manual tuning experiments and then just change all the models from self-tuning versions to models with fixed hyperparameters, like I did for model 3 when doing the v11 update, in commit https://github.com/vdeminstitute/part/commit/3eaf98dd5faaadceb59ce309ccf502c6a3da51c8. 







