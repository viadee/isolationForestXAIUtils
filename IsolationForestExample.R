# 1. load data and packages
library(h2o)
library(dplyr)
library(ggplot2)
source("./XAIUtils.R") # library to explain isolationForest
titanic = read.csv("./titanic.csv")
h2o.init()

# 2. generate train and test data
train = titanic[1:round(nrow(titanic)*0.8),]
test = titanic[round(nrow(titanic)*0.8):nrow(titanic),]

trainh2o = as.h2o(train[,c(-1,-2,-3,-12)]) # remove useless columns (e.g. IDs)
testh2o = as.h2o(test[,c(-1,-2,-3,-12)])


# 3. train model
model_iso <- h2o.isolationForest(training_frame = trainh2o, 
                                 model_id = "isoForest", 
                                 seed = 42, ntrees = 100)

iso_DF = h2o.predict(model_iso, testh2o) %>% as.data.frame()

# 4. identify anomalies
anomaly_threshold = 5.5 # Set threshold by looking at the graph!
iso_DF_ordered = iso_DF %>% arrange(desc(mean_length))
ggplot(iso_DF_ordered, aes(x=c(1:nrow(iso_DF_ordered)), y=iso_DF_ordered$mean_length)) +
  geom_point(size=2, shape=1) + ylab("Mean Length") + xlab(" ") + geom_hline(yintercept = anomaly_threshold) + theme(legend.position="none")


iso_anomaly = data.frame(iso_DF,test) %>% filter(mean_length < anomaly_threshold)

# 5. Explain anomalies
findShortestPath(model_iso, iso_anomaly[1,])
findShortestPath(model_iso, iso_anomaly[2,])
findShortestPath(model_iso, iso_anomaly[3,])
findShortestPath(model_iso, iso_anomaly[4,])
findShortestPath(model_iso, iso_anomaly[5,])
findShortestPath(model_iso, iso_anomaly[6,])
findShortestPath(model_iso, iso_anomaly[7,])


