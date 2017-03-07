# Inspired by Frederic Chazal and Bertrand Michel's practical lesson
# http://www.lsta.upmc.fr/michelb/Enseignements/TDA/Mapper_solutions.html

library(TDAmapper)
library(ggplot2)
library(igraph)
library(RColorBrewer)
library(networkD3)
library(FactoMineR)
library(plotly)
library(Rtsne)

#Read data
#df <- read.csv("data/data_players_7stats_w_position.csv", header=TRUE)
df <- read.csv("data/data_2010-2011.csv", header=TRUE)
positions <- df[,8]
gen_positions <- df[,9]
st <- df[,1:7]

res.pca <- PCA(st, graph = FALSE)

##Use factoextra to plot everything related to PCA
library("factoextra")
fviz_screeplot(res.pca, ncp=40)
fviz_pca_var(res.pca)
fviz_pca_ind(res.pca, geom="point")
fviz_pca_ind(res.pca, geom="point", habillage=positions)
fviz_pca_ind(res.pca, geom="point", habillage=positions, addEllipses=TRUE)
fviz_pca_ind(res.pca, geom="point", habillage=gen_positions)
fviz_pca_ind(res.pca, geom="point", habillage=gen_positions, addEllipses=TRUE)
fviz_pca_biplot(res.pca, geom="point")

#Correlogra
library(corrgram)
corrgram(st)


##Now use plotly to display custom plots
dt = cbind.data.frame(res.pca$ind$coord[, 1:3], positions, gen_positions, rownames(df))
colnames(dt) = c("PCA1", "PCA2", "PCA3", "Position", "GeneralPosition", "Name")
p2d<-plot_ly(data =dt, x = ~PCA1, y = ~PCA2,
    text = ~paste("Name: ", Name, "<br>Position: ", Position),
    type="scatter", mode="markers",
    color = ~GeneralPosition,
    hoverinfo = "text"
    )
p2d
p3d<-plot_ly(data =dt, x = ~PCA1, y = ~PCA2, z=~PCA3,
    text = ~paste("Name: ", Name, "<br>Position: ", Position),
    type="scatter3d", mode="markers",
    color = ~GeneralPosition,
    hoverinfo = "text",
    marker = list(size= 10)
    )
p3d
p2dpp<-plot_ly(data =dt, x = ~PCA1, y = ~PCA2,
    text = ~paste("Name: ", Name, "<br>Position: ", Position),
    type="scatter", mode="markers",
    color = ~Position,
    hoverinfo = "text"
    )
p2dpp
p3dpp<-plot_ly(data =dt, x = ~PCA1, y = ~PCA2, z=~PCA3,
    text = ~paste("Name: ", Name, "<br>Position: ", Position),
    type="scatter3d", mode="markers",
    color = ~Position,
    hoverinfo = "text",
    marker = list(size= 10)
    )
p3dpp

dtm = cbind.data.frame(res.pca$var$coord[, 1:5], colnames(df)[1:7])
colnames(dtm) = c("PCA1", "PCA2", "PCA3", "PCA4", "PCA5", "Feature")
pm2d<-plot_ly(data =dtm, x = ~PCA1, y = ~PCA2,
    text = ~Feature,
    textposition = "top center",
    type="scatter", mode="markers+text",
    marker = list(size = 15)
    )
pm2d
pm3d<-plot_ly(data =dtm, x = ~PCA1, y = ~PCA2, z =~PCA3,
    text = ~Feature,
    type="scatter3d", mode="markers+text"
    )
pm3d

#Both at the same time
pb2d <- plot_ly(data =dtm, x = ~PCA1, y = ~PCA2,
    text = ~Feature,
    type="scatter", mode="markers+text",
    marker = list(symbol="x"),
    hoverinfo = "text"
    ) %>%
    add_trace(data =dt, x = ~PCA1, y = ~PCA2,
        text = ~paste("Name: ", Name, "<br>Position: ", Position),
        type="scatter", mode="markers",
        color = ~Position,
        hoverinfo = "text",
        marker = list(symbol="circle", size=15),
        hoverinfo = "text"
    )
pb2d

pb3d <- plot_ly(data =dtm, x = ~PCA1, y = ~PCA2, z =~PCA3,
    text = ~Feature,
    type="scatter3d", mode="markers+text"
    ) %>%
    add_trace(data =dt, x = ~PCA1, y = ~PCA2, z=~PCA3,
        text = ~paste("Name: ", Name, "<br>Position: ", Position),
        type="scatter3d", mode="markers",
        color = ~Position,
        hoverinfo = "text",
        marker = list(symbol="circle", size=10)
    )
pb3d


#Use r-TSNE to visualize data
res.tsne <- Rtsne(
  as.matrix(st),
  check_duplicates = FALSE,
  perplexity = 100,
  theta = 0.5,
  dims = 2,
  verbose = TRUE
)
tdt = cbind.data.frame(res.tsne$Y, positions, gen_positions, rownames(df))
colnames(tdt) = c("V1", "V2", "Position", "GeneralPosition", "Name")

ptp <- plot_ly(
  data = tdt
  ,x = ~V1
  ,y = ~V2
  #,text = ~paste("Name: ", Name, "<br>Position: ", Position),
  ,text = ~Name
  ,hoverinfo = "text"
  ,type = "scattergl"
  ,color = ~GeneralPosition
  ,mode = 'markers'
  ,marker = list(line = list(width = 2))
)
ptp

#Center and normalize data

st <- scale(st)

#Compute Variance Normalized Euclidean distance
distances = dist(st, method="manhattan")

nba.mapper <- mapper(dist_object = distances,
          filter_values = list(res.pca$ind$coord[,1],res.pca$ind$coord[,2]),
          num_intervals = c(30,30),
          percent_overlap = 50,
          num_bins_when_clustering = 5)

nba.graph <- graph.adjacency(nba.mapper$adjacency, mode="undirected")
plot(nba.graph)

MapperLinks <- mapperEdges(nba.mapper)
MapperNodes <- mapperVertices(nba.mapper, rownames(df))

forceNetwork(Nodes = MapperNodes, Links = MapperLinks,
            Source = "Linksource", Target = "Linktarget",
            Value = "Linkvalue", NodeID = "Nodename",
            Group = "Nodegroup", opacity = 1,
            colourScale = "d3.scale.category10()",
            linkDistance =
    JS('function(){d3.select("body").style("background-color", "#FFFFFF"); return 10;}'), charge = -400, zoom=TRUE)

name <- "Marcus Camby"
#name <- "Tyson Chandler"
cond <- grepl(name,MapperNodes$Nodename)
MapperNodes["cond"]<- cond

forceNetwork(Nodes = MapperNodes, Links = MapperLinks,
            Source = "Linksource", Target = "Linktarget",
            Value = "Linkvalue", NodeID = "Nodename",
            Group = "cond", opacity = 1,
            colourScale = "d3.scale.category10()",
            linkDistance =
    JS('function(){d3.select("body").style("background-color", "#FFFFFF"); return 10;}'), charge = -400, zoom=TRUE)

res.mapper1d <- mapper(dist_object = distances,
           filter_values = list(res.pca$ind$coord[,1]),
           num_intervals = c(30),
           percent_overlap = 50,
           num_bins_when_clustering = 5)
res.graph1d <- graph.adjacency(res.mapper1d$adjacency, mode="undirected")

#Display graph
plot(res.graph1d)

#Display interactive graph
MapperLinks <- mapperEdges(res.mapper1d)
MapperNodes <- mapperVertices(res.mapper1d, 1:length(res.pca$points[1,]) )
forceNetwork(Nodes = MapperNodes, Links = MapperLinks,
            Source = "Linksource", Target = "Linktarget",
            Value = "Linkvalue", NodeID = "Nodename",
            Group = "Nodegroup", opacity = 1,
            linkDistance = 10, charge = -400, zoom=TRUE)
