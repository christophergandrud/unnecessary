
# clear workspace
rm(list = ls())

# set working directory
setwd("~/Desktop/unnecessary/")

# load packages
library(tidyverse)
library(magrittr)

# load data
ge <- read_csv("data/ge.csv")

# drop missing
keep <- c("court", "dq", "cr", "pc", "ag", "sp", "pe", "cc", "ap", "dc", "st", "sg")
ge <- na.omit(ge[, keep])

# formula
f <- court ~ dq + cr + pc + ag + sp + pe + cc + ap + dc + st + sg

# estimate models
fit <- glm(f, data = ge, family = binomial(link = "probit"))

# predicted probability
beta_hat <- coef(fit)
Sigma_hat <- vcov(fit)
beta_tilde <- MASS::mvrnorm(10000, mu = beta_hat, Sigma = Sigma_hat)
X_c <- cbind(1, as.matrix(select(ge, -court)))
tau_tilde <- t(pnorm(X_c%*%t(beta_tilde)))

tau_hat_avg <- apply(tau_tilde, 2, median)  # simulation average

tau_hat_mle <- pnorm(X_c%*%beta_hat)  # mle

tau_df <- data.frame(mle = tau_hat_mle, 
                     avg = tau_hat_avg)
ggplot(tau_df, aes(x = tau_hat_mle, tau_hat_avg)) + 
  scale_color_gradient2(mid = "black", low = "blue", high = "red") + 
  geom_point(shape = 21) + 
  geom_abline(intercept = 0, slope = 1) + 
  theme_bw() + 
  labs(title = "Probability of a Conservative Decision",
       x = "Maximum Likelihood Estimate",
       y = "Simulation Estimate")
ggsave("doc/figs/ge-pr.pdf", height = 3, width = 4)

# first difference for sg
X_lo <- X_hi <- X_c
X_lo[, "sg"] <- 0
X_hi[, "sg"] <- 1

# Wrong one ------------
tau_tilde <- t(pnorm(X_hi%*%t(beta_tilde)) - pnorm(X_lo%*%t(beta_tilde)))
tau_hat_avg <- apply(tau_tilde, 2, median)  # simulation average
# ----------------------

# Correct one ----------
tau_tilde_hi <- t(pnorm(X_hi%*%t(beta_tilde)))
tau_hat_hi_avg <- apply(tau_tilde_hi, 2, median)               

tau_tilde_lo <-  t(pnorm(X_lo%*%t(beta_tilde)))
tau_hat_lo_avg <- apply(tau_tilde_lo, 2, median) 

tau_hat_avg <- tau_hat_hi_avg - tau_hat_lo_avg
# ----------------

tau_hat_mle <- pnorm(X_hi%*%beta_hat) - pnorm(X_lo%*%beta_hat)  # mle
tau_df <- data.frame(mle = tau_hat_mle, 
                     avg = tau_hat_avg) 
gg2 <- ggplot(tau_df, aes(x = tau_hat_mle, tau_hat_avg)) + 
  geom_point(shape = 21) + 
  geom_abline(intercept = 0, slope = 1) + 
  theme_bw() + 
  labs(title = "Effect of a Solicitor General Brief",
       x = "Maximum Likelihood Estimate",
       y = "Simulation Estimate")
ggsave("doc/figs/ge-fd.pdf", height = 3, width = 4)

# hanmer and kalkan
summarize(tau_df, avg_avg = median(avg), avg_mle = median(mle))
  