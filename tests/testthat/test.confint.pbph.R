context("confint.pbph")

test_that("confint.pbph", {

  # Force finite CI
  set.seed(32432)
  n <- 100
  d <- data.frame(abc = rnorm(n),
                  x = rnorm(n),
                  z = rnorm(n),
                  t = rep(0:1, each = n/2))
  d$abc <- with(d, x + t + x*t*.5 + rnorm(n))

  mod1 <- lm(abc ~ x + z, data = d, subset = t == 0)

  e <- pbph(mod1, t, data = d)

  ci <- confint(e, forceDisplayConfInt = TRUE)
  ci

  expect_equal(dim(ci), c(2,2))
  expect_equal(rownames(ci), c("treatment", "pred"))

  # Ci's should have lower and upper correct
  expect_true(all(apply(ci, 1, function(x) diff(x) > 0)))

  expect_equal(ci[1,], confint.lm(e)[1,])
  expect_false(isTRUE(all.equal(ci[2,], confint.lm(e)[2,])))

  expect_true(e$coef[1] > ci[1,1] & e$coef[1] < ci[1,2])
  expect_true(e$coef[2] > ci[2,1] & e$coef[2] < ci[2,2])

  # Force infinite CI
  set.seed(4)
  d <- data.frame(abc = rnorm(10),
                  x = rnorm(10),
                  z = rnorm(10),
                  t = rep(0:1, each = 5))

  mod1 <- lm(abc ~ x + z, data = d, subset = t == 0)

  e <- pbph(mod1, t, d)

  ci <- confint(e, forceDisplayConfInt = TRUE)

  expect_true(all(!is.finite(ci[2,])))

})

test_that("CI arguments", {

  # Force finite CI
  set.seed(32432)
  n <- 100
  d <- data.frame(abc = rnorm(n),
                  x = rnorm(n),
                  z = rnorm(n),
                  t = rep(0:1, each = n/2))
  d$abc <- with(d, x + t + x*t*.5 + rnorm(n))

  mod1 <- lm(abc ~ x + z, data = d, subset = t == 0)

  e <- pbph(mod1, t, d)

  ci <- confint(e, forceDisplayConfInt = TRUE)
  ci

  ci1 <- confint(e, parm = "treatment", forceDisplayConfInt = TRUE)
  expect_equal(rownames(ci1), "treatment")
  expect_equal(ci1[1,], ci[1,])

  ci2 <- confint(e, parm = "pred", forceDisplayConfInt = TRUE)
  expect_equal(rownames(ci2), "pred")
  expect_equal(ci2[1,], ci[2,])

  ci3 <- confint(e, parm = c("pred", "pred", "treatment"), forceDisplayConfInt = TRUE)
  expect_equal(rownames(ci3), c("pred", "pred", "treatment"))

  # Confidence level should shrink
  ci4 <- confint(e, level = .5, forceDisplayConfInt = TRUE)
  expect_true(all((ci4 - ci)[,1] > 0))
  expect_true(all((ci4 - ci)[,2] < 0))
})

test_that("wald-style CI's", {
  set.seed(8)
  d <- data.frame(abc = rnorm(10),
                  x = rnorm(10),
                  z = rnorm(10),
                  t = rep(0:1, each = 5))

  mod1 <- lm(abc ~ x + z, data = d, subset = t == 0)

  e <- pbph(mod1, t, d)

  ci <- confint(e, forceDisplayConfInt = TRUE)
  ci2 <- confint(e, wald.style = TRUE)

  expect_false(identical(ci[2,],ci2[2,]))

  expect_warning(confint(e, forceDisplayConfInt = TRUE, wald.style = TRUE), "ignored")
})

test_that("forceDisplayConfInt and returnShape", {

  set.seed(8)
  d <- data.frame(abc = rnorm(10),
                  x = rnorm(10),
                  z = rnorm(10),
                  t = rep(0:1, each = 5))

  mod1 <- lm(abc ~ x + z, data = d, subset = t == 0)

  e <- pbph(mod1, t, d)

  expect_output(c1 <- confint(e), "suppressing associated confidence interval")
  expect_silent(c2 <- confint(e, forceDisplayConfInt = TRUE))
  expect_true(all(!is.na(c1[1,])))
  expect_true(all(is.na(c1[2,])))
  expect_true(all(!is.na(c2[1,])))
  expect_true(all(!is.na(c2[2,])))

  expect_silent(c3 <- confint(e, returnShape = TRUE))
  expect_true(all(!is.na(c3)))
  expect_equal(attr(c3, "shape"), "finite")

  expect_silent(c4 <- confint(e, returnShape = TRUE, forceDisplayConfInt = FALSE))
  expect_identical(c3,c4)

})

test_that("disjoint CI's", {
  set.seed(3)
  d <- data.frame(x = rnorm(10),
                  z = rnorm(10),
                  t = rep(0:1, each = 5))
  d$y <- d$x + rnorm(10)

  mod1 <- lm(y ~ x + z, data = d, subset = t == 0)

  e <- pbph(mod1, t, d)
  e$coef[2] <- 2 # kinda breaks everything, but ensures significance later on
  expect_silent(c1 <- confint(e, "pred"))
  expect_equal(dim(c1), c(1,2))
  expect_true(all(!is.finite(c1)))
  expect_true(is.null(attr(c1, "shape")))
  c2 <- confint(e, "pred", returnShape = TRUE)
  expect_true(all(is.finite(c2)))
  expect_equal(attr(c2, "shape"), "disjoint")
  c3 <- confint(e, "pred", forceDisplayConfInt = TRUE)
  expect_identical(c2, c3)
  c4 <- confint(e, "pred", forceDisplayConfInt = TRUE, returnShape = TRUE)
  expect_identical(c2, c4)

})
