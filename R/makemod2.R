##' (Internal) Fit the second stage of the Peters-Belson with
##' Prognostic Heterogeneity model.
##'
##' Given a first stage model fit only on the control group, fit a second stage
##' model with formula.
##'
##' resp - pred ~ pred | treatment == 1
##'
##' @param mod1 First stage model fit
##' @param treatment A vector of treatment statuses, should be all
##'   \code{0} or \code{1}.
##' @param data Data where variables in \code{form} live.
##' @param center Default \code{TRUE}. Should the predicted values be
##'   centered in the second stage?
##' @return A \code{list} consisting of \code{mod2}, the second stage
##'   model, and \code{pred}, the predicted values from \code{mod1}.
makemod2 <- function(mod1, treatment, data, center = TRUE) {

  # Get predicted values.
  predicted <- predict(mod1, type = "response", newdata = data)

  # Second stage linear model.
  respname <- formula(mod1)[[2]]
  newdata <- data.frame(pred      = predicted[treatment == 1],
                        treatment = rep(1, sum(treatment)))
  newdata[[paste0(respname, " - pred")]] <- eval(respname, envir = data)[treatment == 1] - newdata$pred

  # newdata is only treatment group from above, so this centering is on treatment only
  if (center) newdata$pred <- scale(newdata$pred, scale = FALSE)

  form <- as.formula(paste0("`", respname, " - pred` ~ treatment + pred + 0"))

  mod2 <- lm(form, data = newdata, subset = (treatment == 1))

  mod2$call$formula <- as.formula(paste0(respname, " - pred ~ treatment + pred"))

  return(list(mod2 = mod2, pred = predicted))
}
