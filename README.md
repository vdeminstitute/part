Predicting Adverse Regime Transitions (PART)
============================================

Data and code for the V-Dem PART project to predict the risk of adverse regime transitions. The dashboard with forecasts can be seen at [https://www.v-dem.net/vforecast_dash](https://www.v-dem.net/vforecast_dash). (To run a local version that is probably faster, see [dashboard/README.md](dashboard/README.md))

Reproduction
------------

To reproduce the forecasts, see [Models/](Models/). The general workflow from data building to models to dashboard is also described in the updating instructions below.

Contributing
------------

We welcome any error and bug reports dealing with mistakes in the existing code and data. Please open an issue here on GitHub.

This repo is not under active development and mainly serves for the sake of transparency and to allow reproduction of the forecasts and dashboard. There is no plan for continuing development aside from, potentially, annual forecast updates in the future. It is thus unlikely that more substantive feedback, like suggestions about additional features/predictors or alternative models, would be incorporated unless you do most of the legwork and can clearly demonstrate improved performance. This is not meant as discouragement, we simply don’t have the resources to put more time in this and want to prevent disappointment.

Citation
--------

If you want to cite the dashboard or forecasts:

Richard K. Morgan, Andreas Beger, and Adam Glynn, 2019, "Varieties of forecasts: predicting adverse regime transitions", V-Dem Working Paper 2019:89, https://dx.doi.org/10.2139/ssrn.3389194. 

``` bibtex
@unpublished{morgan2019varieties,
  title = {Varieties of forecasts: predicting adverse regime transitions},
  author = {Morgan, Richard K. and Beger, Andreas and Glynn, Adam},
  year = {2019},
  note = {V-Dem Working Paper 2019:89},
  url = {https://dx.doi.org/10.2139/ssrn.3389194}
}
```

Updating
--------

The [`UPDATING.md`](UPDATING.md) file has notes on how to update the forecasts.

Also see the [`CHANGELOG.md`](CHANGELOG.md) for a summary of the project history and changes between the different versions of the forecasts. 



