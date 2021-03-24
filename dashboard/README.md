PART Dashboard
==============

Code for the PART Shiny dashboard.

To run the dashboard locally _without_ cloning the whole **part** repository, you can use the code below, which will download and then run a tarball of the dashboard app. This presupposes all necessary packages are installed, see [setup.R](setup.R). 

```r
library(shiny)
runUrl('https://github.com/vdeminstitute/part/raw/main/dashboard/part-dashboard.tar.gz')
```

Updating
--------

To update the dashboard with the latest forecasts:

1. Copy the two `mdl6_` forecast RDS files from `Models/predictions/` to `data-raw`.
2. Re-run `data-raw/data-organization.R` to update the various pre-computed datasets the dashboard uses. Note any lines marked with "UPDATE:", which may need manual updates. 
3. Rebuild the dashboard tarball by running make from the `dashboard/` folder.

