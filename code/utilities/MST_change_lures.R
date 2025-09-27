library(dplyr)


SetC_4 <- SetC_4_Sheet1 
#    %>% filter(endsWith(image, "b.jpg"))

# Create a new column 'lure_4' based on the quantiles of '%old'
SetC_4 <- SetC_4 %>%
    mutate(lure_4 = ntile(-percent_old, 4))


# Remove "setsof2/" and either "a.jpg" or "b.jpg" from the first column
SetC_4$image <- gsub("^setsof2/|a.jpg$|b.jpg$", "", SetC_4$image)

# Remove columns 2 through 7
SetC_4 <- SetC_4[, -c(2:9)]



# Save the dataframe to a text file without header
write.table(SetC_4, "SetC_4.txt", row.names = FALSE, col.names = FALSE)
