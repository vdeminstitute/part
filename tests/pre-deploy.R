#
#   Pre-deployment tests, e.g.:
#
#     - make sure dashboard tarball is current
#

library(here)

get_mtime <- function(...) {
  file.info(here::here(...))[, "mtime"]
}

#
#   Make sure the Shiny app tarball is current ----
#

test_that("tarball is current", {
  files <- c(
    "global.r", "server.r", "ui.r", "styles.css",
    paste0("data/", dir(here::here("dashboard/data")))
  )
  files <- paste0("dashboard/", files)
  file_modtime <- get_mtime(files)

  tarball_modtime <- get_mtime("dashboard/part-dashboard.tar.gz")

  expect_true(all(tarball_modtime >= file_modtime))
})


