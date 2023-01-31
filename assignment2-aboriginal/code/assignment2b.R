# Assignment 2b: Replicating Pendakur & Pendakur (2011)

# Preliminaries -------------------------------------------------------------------------------------------

# Load libraries

library(tidyverse)
library(haven)
library(quantreg)
library(modelsummary)

# Load data (2016 Individual Microdata for the Canadian census)

census_raw <-
  read_dta('assignment2-aboriginal/data/Census_2016_Individual_PUMF.dta')

# Cleaning the data ---------------------------------------------------------------------------------------

# I put NAs for all missing or not available values

# I also relevel the age, marital_statusd- factor to have the reference group that I want 

df_pre <-
  census_raw %>% 
  mutate(
    income = case_when(
      EmpIn %in% c(88888888, 99999999) ~ as.numeric(NA),
      TRUE ~ EmpIn
    ),
    agegrp = case_when(
      agegrp == 88 ~ as.double(NA),
      TRUE ~ as.double(agegrp)
    ),
    age = as.factor(agegrp) %>% relevel(9),
    marstat = as.factor(MarStH) %>%  relevel(1),
    hhsize = case_when(
      hhsize == 8 ~ as.double(NA),
      TRUE ~ as.double(hhsize)
    ),
    size = as.factor(hhsize) %>% relevel(1),
    kol = case_when(
      kol == 8 ~ as.double(NA),
      TRUE ~ as.double(kol)
    ),
    lang = as.factor(kol) %>% relevel(1),
    cma = as.factor(cma) %>% relevel('999'),
    education = case_when(
      hdgree %in% c(88,99) ~ as.double(NA),
      TRUE~ as.double(hdgree)
      ),
    education = as.factor(education) %>% relevel(2)
  )

# Create the "race" variables which includes all categories of indians

# First remove the NAs

df <- 
  df_pre %>%
  filter(ethder != 88) %>% 
  mutate(
    race = case_when(
      ethder != 1 ~ ethder,
      ethder == 1 & regind == 1 ~ as.double(999), # 999 is Registered Indians,
      ethder == 1 & regind == 0 & aboid != 6 ~ aboid,
      ethder == 1 & regind == 0 & aboid == 6 ~ as.double(998) # 998 is Ancestry
    )
  )



# Reducing the sample -------------------------------------------------------------------------------------

# We filter out people who are not employed by someone else.

df <-
  df %>% 
  filter(cow == 1,
         income > 0)

# Samples for Regressions ---------------------------------------------------------------------------------

# We always do different samples, one for women and another for men

canada_men <-
  df %>% 
  filter(Sex == 2)

canada_women <-
  df %>% 
  filter(Sex == 1)

# Must also do different samples 

# For wage earnings regressions, look only at cow == 1

canada_men_reg <-
  rq(log(income) ~ as.character(race) + marstat + age + hhsize + 
     cma + education + lang, 
     data = canada_men,
     tau = c(0.2,0.5,0.8,0.9))

canada_men_reglm <-
  lm(log(income) ~ as.character(race) + marstat + age + hhsize + 
       cma + education + lang, 
     data = canada_men)

summary(canada_men_reglm)

canada_men_reg %>% summary()
canada_men_reg$coefficients -> coefs