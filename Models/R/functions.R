
#' Generate test forecasts
#'
#' Iterates over years to generate and save forecasts for one year ahead
#'
#' @param learner mlr task object containing the neccessary training/test data
#' @param task The model to evaluate
#' @param years Sequence of years over which to forecast; integer vector
#'
#' @return A tibble containing one-year ahead forecasts for all years in
#'   "years".
test_forecast <- function(learner, task, years) {

  test_forecasts <- list()

  for (i in TEST_FORECAST_YEARS) {
    # Subset data/tasks
    train_task    <- subsetTask(task, subset = split_data$train_ids$year < i)
    forecast_task <- subsetTask(task, subset = split_data$train_ids$year==i)

    # Train model on data up to but not including year i
    mdl_i <- mlr::train(learner = learner, task = train_task)

    # Forecast for year i
    fcast_i <- predict(mdl_i, task = forecast_task)
    fcast_i <- bind_cols(split_data$train_ids[split_data$train_ids$year == i, c("country_name", "gwcode", "year")],
                         split_data$train[split_data$train_ids$year == i, TARGET, drop = FALSE],
                         fcast_i$data)

    test_forecasts <- c(test_forecasts, list(fcast_i))
  }

  test_forecasts <- bind_rows(test_forecasts) %>%
    mutate(truth = as.integer(as.character(truth)))
  test_forecasts
}


tidy_ResampleResult <- function(x) {
  o <- getRRPredictions(x) %>%
    as_tibble(.) %>%
    mutate(truth = as.integer(as.character(truth)),
           response = as.integer(as.character(response))) %>%
    arrange(id)
  o
}

LagDifFun <- function(x, lag_n){x - lag(x, n = lag_n)}

naCountFun <- function(dat, exclude_year){
    dat%>%
      filter(year < exclude_year)%>%
      sapply(function(x) sum(is.na(x)))%>%
      sort()
}

naCountFun_no_sort <- function(dat, exclude_year){
    dat%>%
      filter(year < exclude_year)%>%
      sapply(function(x) sum(is.na(x)))#%>%
      # sort()
}

# Summary measures for binary classification
bin_class_summary <- function(obs, pred) {
  brier  <- mean((pred-obs)^2)
  ## measures the mean squared difference between: The predicted probability assigned to the possible outcomes for item i The actual outcome o_i.
  ## The lower the Brier score is for a set of predictions, the better the predictions are calibrated.
  aucroc <- tryCatch(MLmetrics::AUC(y_pred = pred, y_true = obs), error = function(e) NA)
  ## ROC is a probability curve and AUC represents degree or measure of separability.
  ## Higher the AUC better the model. "The probability that a random positive is assigned a higher score than a random negative."
  aucpr  <- tryCatch(MLmetrics::PRAUC(y_pred = pred, y_true = obs), error = function(e) NA)
  ## Precision Recall area under curve -- Precision-Recall is a useful measure of success of prediction when the classes are very imbalanced. In information retrieval, precision is a measure of result relevancy, while recall is a measure of how many truly relevant results are returned.
  ## The tradeoff between precision and recall for different threshold, where high precision relates to a low false positive rate, and high recall relates to a low false negative rate.
  ## High scores for both show that the classifier is returning accurate results (high precision), as well as returning a majority of all positive results (high recall).
  cagg   <- e1071::classAgreement(table(obs, as.integer(pred > 0.5)))
  acc    <- cagg[["diag"]]
  kappa  <- cagg[["kappa"]]
  ## The Kappa statistic (or value) is a metric that compares an Observed Accuracy with an Expected Accuracy (random chance).
  ## It takes into account agreement with a random classifier, which generally means it is less misleading than simply using accuracy

  out <- c(Accuracy = acc, Kappa = kappa, AUC_ROC = aucroc, AUC_PR = aucpr,
           Brier = brier)
  out
}

ggsepplot <- function(y, phat, outcome = "Y") {
  # cols <- c("#FEF0D9", "#E34A33")
  cols <- c("#E2AFFE10", "#67029F")
  # cols <- c("lightblue", "steelblue4")
    # onset_colors <- c("#CEADE375", "#4F1C6F")

  df <- data.frame(y = factor(y),
                   phat = phat)
  df <- df[order(df$phat), ]
  df$index <- 1:nrow(df)

  p <- ggplot(df, aes(x = index, y = 1)) +
    geom_bar(aes(fill = y), stat = "identity", position = "identity", width = 2) +
    geom_step(aes(y = phat), colour = "#00C218") +
    scale_fill_manual(guide = FALSE, values = cols) +
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    labs(x = "", y = sprintf("Pr(%s)", outcome)) +
    theme(axis.line = element_blank(),
          axis.title.x = element_blank(),
          axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          panel.background = element_blank(),
          panel.grid = element_blank())
  p
}


roundToTenth <- function(x){ceiling(x * 10) / 10}

BaseSepPlotsFun <- function(file_path = NULL, threshold = 0.1, year, N, preds, truth, any_neg_change, country_names, model_name, kappa_score, auc_pr_score, brier_score){
    onset_colors <- c("#B1A6FE80", "#0496F0", "#320397") 
    accepted <- preds[preds >= threshold]
    tot_above <- length(accepted)
    tot_onset_2yr <- sum(as.numeric(as.character(truth)))
    tot_onset_1yr <- sum(as.numeric(any_neg_change))
    max_pred <- max(preds)
    min_accepted <- min(accepted)
    pred_thres   <- factor(ifelse(preds < min_accepted, 0, 1), levels = c("0", "1"))
    ConfusionMatrix <- table(truth, pred_thres)
    TP <- ConfusionMatrix[2, 2]
    FP <- ConfusionMatrix[1, 2]
    TN <- ConfusionMatrix[1, 1]
    FN <- ConfusionMatrix[2, 1]
    precision <- round(TP/(TP+FP), 3)
    recall <- round(TP/(TP+FN), 3)
    year2 <- year + 1 - 2000
    year_string <- paste(year, year2, sep = "-")
    pdf(file_path, width = 8.5, height = 6)
    par(mfrow = c(1, 2))
    plot.new()
    mtext(paste("Estimated Risk of ART for ", year_string, " using ", model_name, sep = ""), side = 3, line = -1, outer = TRUE, font = 2)
    mtext(paste("AUC-PR: ", round(auc_pr_score, 3), "; ", " Brier: ", round(brier_score, 3), "; ", " Kappa: ", round(kappa_score, 3), sep = ""),
        side = 1, line = 0, outer = FALSE, font = 1, cex = 0.7)
    plot.window(xlim = c(0, max(roundToTenth(preds)) + 0.1), ylim = c(1, length(preds)), mar = c(0, 3, 3, 2))
    axis(3, at = seq(0, max(roundToTenth(preds)) + 0.05, by = 0.05), cex.axis = 0.7)
    axis(2, at = c(1, seq(13, length(preds), 13)),
      labels = c(sort(seq(13, length(preds), 13), decreasing = TRUE), 1), las = 2, cex.axis = 0.7)
    mtext("All Observations", side = 3, line = 2)
    mtext("Ranked Risk", side = 2, line = 2)
    segments(x0 = preds, x1 = 0, y0 = 1:length(preds), lwd = 2, col = onset_colors[1])
    segments(x0 = -0.0225, x1 = preds[truth == 1], y0 = which(truth == 1), lwd = 1, col = "black")
    lines(x = preds, y = 1:length(preds), lwd = 2, col = "#2E827F")
    legend(x = min(preds) + 0.005, y = 70, bty = "n",
      c(paste("Observed Onsets w/in 1 Year: ", tot_onset_1yr, sep = ""),
        paste("Observed Onsets w/in 2 Years: ", tot_onset_2yr, sep = ""),
        "",
        paste("Highest Predicted Risk: ", (max_pred * 100), "%", sep = ""),
        paste("Acceptance Threshold: ", (threshold * 100) , "%", sep = ""),
        paste("Precision - TP/(TP+FP): ", precision, sep = ""),
        paste("Recall - TP/(TP+FN): ", recall, sep = ""),
        "",
        paste("True Positive: ", TP, sep = ""),
        paste("True Negative: ", TN, sep = ""),
        paste("False Positive: ", FP, sep = ""),
        paste("False Negative: ", FN, sep = "")), cex = 0.7)
    abline(h = which(preds == min_accepted)[1], lty = 3)
    segments(x0 = threshold, y0 = 175, y1 = which(preds == min_accepted)[1], lty = 3)
    points(x = threshold, y = which(preds == min_accepted)[1], col = "red", pch = 18)

    o <- order(preds, decreasing = TRUE)
    predsN <- preds[o][1:N]
    truthN <- truth[o][1:N]
    any_neg_changeN <- any_neg_change[o][1:N]
    country_namesN <- country_names[o][1:N]
    obs_onset_colorsN <- case_when(truthN == 0 ~ onset_colors[1],
                                  truthN == 1 & any_neg_changeN == 1 ~ onset_colors[2],
                                  truthN == 1 & any_neg_changeN == 0 ~ onset_colors[3])
    names(predsN) <-  paste(seq(1:N), country_namesN, sep = ": ")
    plot.window(xlim = c(0, max(roundToTenth(predsN)) + 0.1), ylim = c(1, length(predsN)))
    barplot(sort(predsN), horiz = TRUE, col = obs_onset_colorsN[order(predsN)], las = 2, axes = FALSE,
      mar = c(0, 10, 3, 2), cex.names = 0.7, space = 0.25, xlim = c(0, max(roundToTenth(predsN)) + 0.1))
    axis(3, at = seq(0, max(roundToTenth(predsN) + 0.05), by = 0.05), cex.axis = 0.7)
    abline(v = threshold, lty = 3)
    mtext(paste("Top ", N, " Countries", sep = ""), side = 3, line = 2)
    legend("bottomright", bty = "n", pch = 15, col = onset_colors[2:3], c(paste("Observed Onset in", year, sep = " "), paste("Observed Onset in", year2 + 2000, sep = " ")), cex =  0.7, pt.cex = 1.75)
    dev.off()
}


BaseSepPlotsFun_live <- function(file_path = NULL, year, N, preds, country_names, model_name, colors){
    onset_colors <- colors
    max_pred <- max(preds)
    o2 <- order(preds, decreasing = FALSE)
    o <- order(preds, decreasing = TRUE)
    year2 <- year + 1 - 2000
    year_string <- paste(year, year2, sep = "-")
    pdf(file_path, width = 8.5, height = 6)
    par(mfrow = c(1, 2))
    plot.new()
    mtext(paste("Estimated Risk of ART for ", year_string, " using ", model_name, sep = ""), side = 3, line = -1, outer = TRUE, font = 2)
    plot.window(xlim = c(0, max(roundToTenth(preds)) + 0.1), ylim = c(1, length(preds)), mar = c(0, 3, 3, 2))
    axis(3, at = seq(0, max(roundToTenth(preds)) + 0.1, by = 0.05), cex.axis = 0.7)
    axis(2, at = c(1, seq(13, length(preds), 13)),
      labels = c(sort(seq(13, length(preds), 13), decreasing = TRUE), 1), las = 2, cex.axis = 0.7)
    mtext("All Observations", side = 3, line = 2)
    mtext("Ranked Risk", side = 2, line = 2)
    segments(x0 = preds[o2], x1 = 0, y0 = 1:length(preds), lwd = 2, col = onset_colors[o2])
    lines(x = preds[o2], y = 1:length(preds), lwd = 2, col = "#2E827F")
    legend(x = min(preds) + 0.005, y = 13, bty = "n", paste("Highest Predicted Risk: ", (max_pred * 100), "%", sep = ""), cex = 0.7)

    predsN <- preds[o][1:N]
    country_namesN <- country_names[o][1:N]
    names(predsN) <- paste(seq(1:N), country_namesN, sep = ": ")
    onset_colorsN <-  onset_colors[o][1:N]

    plot.window(xlim = c(0, max(roundToTenth(predsN)) + 0.1), ylim = c(1, length(predsN)))
    barplot(sort(predsN), horiz = TRUE, col = rev(onset_colorsN), las = 2, axes = FALSE,
      mar = c(0, 10, 3, 2), cex.names = 0.7, space = 0.25, xlim = c(0, max(roundToTenth(predsN)) + 0.1))
    axis(3, at = seq(0, max(roundToTenth(predsN) + 0.05), by = 0.05), cex.axis = 0.7)
    mtext(paste("Top ", N, " Countries", sep = ""), side = 3, line = 2)
    dev.off()
}

  

#' Mode
#'
#' Get the mode of an input vector
math_mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}


BasePlotTestLiveFun <- function(file_path = NULL, year, year_live, N, preds, truth, any_neg_change, preds_live, colors_live, country_names, country_names_live, model_name, kappa_score, auc_pr_score, brier_score){
    cex_labels <- 1.5
    onset_colors <- c("#CFCAF4", "#0496F0", "#320397") 
    year2 <- year + 1
    year_string <- paste(year, year2, sep = "-")
    png(file_path, width = 20, height = 10, units = "in", res = 650)
    par(mfrow = c(1, 2), mar = c(3, 12, 5, 2))
    o <- order(preds, decreasing = TRUE)
    predsN <- preds[o][1:N]
    truthN <- truth[o][1:N]
    any_neg_changeN <- any_neg_change[o][1:N]
    country_namesN <- country_names[o][1:N]
    obs_onset_colorsN <- case_when(truthN == 0 ~ onset_colors[1],
                                  truthN == 1 & any_neg_changeN == 1 ~ onset_colors[3], #truthN == 1 & any_neg_changeN == 1 ~ onset_colors[2],
                                  truthN == 1 & any_neg_changeN == 0 ~ onset_colors[3])
    names(predsN) <-  paste(seq(1:N), country_namesN, sep = ": ")
    plot.window(xlim = c(0, max(roundToTenth(predsN)) + 0.1), ylim = c(1, length(predsN)))
    # barplot(sort(predsN), horiz = TRUE, col = obs_onset_colorsN[order(predsN)], las = 2, axes = FALSE, cex.names = 0.7, space = 0.25, xlim = c(0, max(roundToTenth(predsN)) + 0.1))
    barplot(sort(predsN), horiz = TRUE, col = obs_onset_colorsN[order(predsN)], las = 2, axes = FALSE, cex.names = cex_labels, space = 0.1, xlim = c(0, 0.60))
    # axis(3, at = seq(0, max(roundToTenth(predsN) + 0.05), by = 0.05), cex.axis = 0.7)
    axis(3, at = seq(0, 0.75, by = 0.05), cex.axis = cex_labels)
    mtext(paste("(A) Top ", N, " Estimated Risks for ", year_string, sep = ""), side = 3, line = 3, cex = cex_labels) #, " using ", model_name
    # legend("bottomright", bty = "n", pch = 15, col = onset_colors[2:3], c(paste("An ART Occurred in", year, sep = " "), paste("An ART Occurred in", year2, sep = " ")), cex = cex_labels, pt.cex = 1.75)
    legend("bottomright", bty = "n", pch = 15, col = onset_colors[3], c(paste("An ART Occurred in ", year, "/", year2, sep = "")), cex = cex_labels, pt.cex = 1.75)
    mtext(paste("Model Performance -- ", "AUC-PR: ", round(auc_pr_score, 3), "; ", " Brier: ", round(brier_score, 3), "; ", " Kappa: ", round(kappa_score, 3), sep = ""),
        side = 1, line = 0, outer = FALSE, font = 1, cex = cex_labels)

    max_pred_live <- max(preds_live)
    o2_live <- order(preds_live, decreasing = FALSE)
    o_live <- order(preds_live, decreasing = TRUE)
    year2_live <- year_live + 1
    year_string_live <- paste(year_live, year2_live, sep = "-")
    predsN_live <- preds_live[o_live][1:N]
    country_namesN_live <- country_names_live[o_live][1:N]
    names(predsN_live) <- paste(seq(1:N), country_namesN_live, sep = ": ")
    plot.window(xlim = c(0, max(roundToTenth(predsN_live)) + 0.1), ylim = c(1, length(predsN_live)))
    # barplot(sort(predsN_live), horiz = TRUE, col = colors_live, las = 2, axes = FALSE, cex.names = 0.7, space = 0.25, xlim = c(0, max(roundToTenth(predsN_live)) + 0.1))
    barplot(sort(predsN_live), horiz = TRUE, col = colors_live, las = 2, axes = FALSE, cex.names = cex_labels, space = 0.1, xlim = c(0, 0.60))
    # axis(3, at = seq(0, max(roundToTenth(predsN_live) + 0.05), by = 0.05), cex.axis = 0.7)
    axis(3, at = seq(0, 0.75, by = 0.05), cex.axis = cex_labels)
    mtext(paste("(B) Top ", N, " Estimated Risks for ", year_string_live, sep = ""), side = 3, line = 3, cex = cex_labels) #, " using ", model_name

    dev.off()
}



BasePredPlotsFun_live <- function(file_path = NULL, year, N, preds, country_names){
    cex_labels <- 1
    onset_colors <- "#A2518880"
    o <- order(preds, decreasing = TRUE)
    year2 <- year + 1
    year_string <- paste(year, year2, sep = "-")
    png(file_path, width = 8.5, height = 6, units = "in", res = 650)
    par(mar = c(0, 12, 5, 2))
    predsN <- preds[o][1:N]
    country_namesN <- country_names[o][1:N]
    names(predsN) <- paste(seq(1:N), country_namesN, sep = ": ")
    plot.window(xlim = c(0, max(roundToTenth(predsN)) + 0.1), ylim = c(1, length(predsN)))
    barplot(sort(predsN), horiz = TRUE, col = rev(onset_colors), las = 2, axes = FALSE,
      mar = c(0, 10, 3, 2), cex.names = cex_labels, space = 0.15, xlim = c(0, max(roundToTenth(predsN)) + 0.1))
    axis(3, at = seq(0, max(roundToTenth(predsN) + 0.05), by = 0.05), cex.axis = cex_labels)
    mtext(paste("Top ", N, " Estimated Risks for ", year_string, sep = ""), side = 3, line = 2, cex = cex_labels)
    dev.off()
}

  