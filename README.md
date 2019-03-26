# An XAI-Approach for Anomaly Detection with Isolation Forest 

The Isolation Forest approach for anomaly detection developed by H2o is able to detect anomalies in a very simple way. However, the approach does not yet provide any indication of how the algorithm derives the detected anomalies. Thus, we provide a new functionality to make the results of the Isolation Forest traceable and comprehensible.

### Isolation Forest

The idea of an Isolation Forest is to uncover which observations can be quickly partitioned.
In the Isolation Forest, the partitioning of data is carried out several times using binary trees. Each tree consists of a random subset of the data with a defined sample size. The dataset is partitioned until either each data point is isolated in a leaf node or an average depth is exceeded. This procedure is valid because only anomalous data points are of interest, which are already isolated before the average depth is reached. The partitioning feature and threshold are chosen randomly. Multiple Isolation Trees form an Isolation Forest. In order to determine whether an observation is an anomaly, the average depth of all trees in the Isolation Forest is calculated for each observation. The smaller this measure, the more unusual the observation is.

### XAI-Approach

The function *findShortestPath* is used to reveal why a particular observation is an anomaly. The function expects two parameters: an observation (for our purpose an identified anomaly) and the Isolation Forest model. The algorithm traverses all trees in the Isolation Forest and determines the length of the path from the root to the observationof each tree. The path that isolates the anomaly fastest (shortest path) represents the basis for the explanation of the anomaly. The features lying on this shortest path represent unusual values or combinations of values and are thus declared as responsible for classifying the observation as an anomaly.

### Example 

In the following we want to apply the Isolation Forest and our new XAI-Approach to the [Titanic dataset of the kaggle Challenge](https://www.kaggle.com/biswajee/titanic-dataset). The dataset contains information about Titanic passengers such as their age, gender or name. We preprocessed the [dataset](https://github.com/viadee/isolationForestXAIUtils/blob/master/titanic.csv) and made it available in this git repository: The preprocessing was necessary because our anomaly explanation approach only works on numerical values. For this reason, all non-numerical features were transformed in advance. In general, however, an Isolation Forest can be applied to any data type and scale level of the features.

The first step is to identify anomalies. First the data has to be loaded and an Isolation Forest model has to be trained.

```
# 1. load data and packages
library(h2o)
library(dplyr)
library(ggplot2)
source("./XAIUtils.R") 
titanic = read.csv("./titanic.csv")
h2o.init()

# 2. generate train and test data
train = titanic[1:round(nrow(titanic)*0.8),]
test = titanic[round(nrow(titanic)*0.8):nrow(titanic),]

trainh2o = as.h2o(train[,c(-1,-2,-3,-12)]) # remove useless columns (e.g. IDs)
testh2o = as.h2o(test[,c(-1,-2,-3,-12)])

# 3. train model
model_iso <- h2o.isolationForest(training_frame = trainh2o, model_id = "isoForest", seed = 42, ntrees = 100)
 
iso_DF = h2o.predict(model_iso, testh2o) %>% as.data.frame()
```

Now anomalies can be identified. The mean length of all data points is plotted. In this case we select the five observations with the lowest depth.

```
# 4. identify anomalies
anomaly_threshold = 5.5 # Set threshold by looking at the graph!
 
iso_DF_ordered = iso_DF %>% arrange(desc(mean_length))
ggplot(iso_DF_ordered, aes(x=c(1:nrow(iso_DF_ordered)), y=iso_DF_ordered$mean_length))   geom_point(size=2, shape=1)   
ylab("Mean Length")   xlab(" ")   geom_hline(yintercept = anomaly_threshold)   theme(legend.position="none")
 
iso_anomaly = data.frame(iso_DF,test) %>% filter(mean_length < anomaly_threshold)
```

In the last step we aim to explain the detected anomalies. We do this exemplary for one anomaly.

```
findShortestPath(model_iso, iso_anomaly[5,])
```

The result shows that Passenger 827 was classified as an anomaly because he did not survive and has more than 6.5 parents and siblings.
