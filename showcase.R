
# data.table --------------------------------------------------------------

install.packages('data.table')
library(data.table)

# useful option: print data.table column classes like in dplyr 
options(datatable.print.class = TRUE)

# you might be familiar with data.table's dt[i, j, by] notation and its 
# outstanding efficiency (benchmarks: https://h2oai.github.io/db-benchmark/)
idt <- as.data.table(iris)

# mutate
idt[, Sepal.Area := Sepal.Width * Sepal.Length]
# grouped summary
idt[, .(mean_area = mean(Sepal.Area)), by = Species]

# The power and flexibility of the 'j' entry -----------------------------------

# beware:  R is a softly typed programming language, but data.table is hard-typed
# to change column types, it has to be done by overwriting the column by reference
idt[, Species := as.character(Species)]

# the 'j' entry in data.table can execute basically anything!

# #example 1. write individual .csv files by group
idt[, fwrite(.SD, paste0(as.character(.BY), '.csv')), by = Species]
list.files(pattern = '.csv')

# example2. read a list of .csv files into a single data.table
files <- data.table(filenames = list.files(pattern = '.csv')) # get the file names in a table
files[, fread(filenames), by = filenames] # read directly

# example3. get grouped top N by values
# top 3 by Sepal.Length
idt[order(-Sepal.Length), head(.SD,3), by = Species]


# purrr -------------------------------------------------------------------

install.packages('purrr')
library(purrr)

# the most powerful functions on the purrr package are the map family of functions.
# Like upgraded versions of the _apply family of functions, they map each element
# of a list or vector into a function, allowing for very complex and efficient 
# one-line executions

# _ example 1. create an interactive box plot by group for each numerical column ----
install.packages('ggplot2')
library(ggplot2)
install.packages('plotly')
library(plotly)

boxplots <- map(.x = colnames(purrr::keep(iris, is.numeric)) %>% set_names(.),
                .f = ~ggplotly(ggplot(data = iris, 
                                      mapping = aes_string(x = 'Species', 
                                                           y = .x,
                                                           fill = 'Species')) + 
                                 geom_boxplot() +
                                 theme_minimal()))

boxplots$Sepal.Length
boxplots$Sepal.Width


# _example 2. run kmeans segmentation for different K values over the same data  --------

set.seed(1)
walk(.x = 2:5,
    .f = ~idt[, eval(paste0(.x, 'clusters')) := kmeans(keep(.SD, is.numeric), centers = .x)$cluster])

# _example 2.1 Run cluster statistics for each k
install.packages('openxlsx')
library(openxlsx)


cluster_cols <- colnames(idt)[grepl(x = colnames(idt), pattern = 'clusters')] %>%
  set_names(.)

cluster_statistics <- map(.x = cluster_cols,
                          .f = ~idt[, .(.N, 
                                        per_setosa = sum(Species == 'setosa'),
                                        per_virginica = sum(Species == 'virginica'),
                                        per_versicolor = sum(Species == 'versicolor')), by = .x
                                  ][, population_percentage := N/sum(N)
                                  ][order(get(.x))])

cluster_statistics %>% write.xlsx('custer_statistics.xlsx', gridLines = FALSE, asTable = TRUE)

