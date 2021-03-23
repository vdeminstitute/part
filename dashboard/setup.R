#
#   Setup dashboard dependencies
#
#   This script can be sourced.
#
#   To generate/update the dependency list:
#
#   library(abmisc)
#   setwd("dashboard")
#   check <- c("global.R", "server.R", "StartUp.R")
#   deps <- sort(unique(unlist(sapply(check, find_packages))))
#   dput(deps)

deps <- c("dplyr", "highcharter", "leaflet", "sf", "shiny", "shinyWidgets")

installed <- rownames(installed.packages())
need <- deps[!deps %in% installed]

if (length(need) > 0) {
  cat("The following packages need to be installed for the dashboard:\n")
  cat(paste0(need, collapse = ", "))
  key <- readline(prompt = "Install these packages? [y/n]: ")
  if (key=="y") {
    install.packages(pkgs = need)
  } else {
    stop("Not installing. The dashboard will not work.")
  }
}

cat("All dependencies are met")
