# recursive function to traverse all nodes of one tree for a specific anomaly and return path
recursiveTree <- function(rootnode, feature, threshold, documentation, anomaly){
  
  anomalyFeature <- as.numeric(anomaly[colnames(anomaly) == feature])
  eq = ifelse(threshold < anomalyFeature,">=","<")
  documentationNew <- data.frame(Feature = as.character(feature), Eq = eq, Threshold = threshold, stringsAsFactors = FALSE)
  documentationNew = rbind(documentation,documentationNew)
  

  # Case 1: left node
  if(is.na(threshold)){
    newnode = rootnode@left_child
    if(class(newnode)[1] != "H2OLeafNode"){ # stop if node is leaf node
      newfeature = rootnode@left_child@split_feature
      newthreshold = rootnode@left_child@threshold
      recursiveTree(newnode,newfeature,newthreshold,documentationNew,anomaly)
    }else{
      return(documentationNew)
    }
  }# Case 2: right node
  
  else if(is.na(anomalyFeature) || anomalyFeature >= threshold ){
    newnode = rootnode@right_child
    if(class(newnode)[1] != "H2OLeafNode"){ #stop if node is leaf node
      newfeature = rootnode@right_child@split_feature
      newthreshold = rootnode@right_child@threshold
      recursiveTree(newnode,newfeature,newthreshold,documentationNew,anomaly)
    }else{
      return(documentationNew)
    }
    # Case 3: left node
  }else{
    newnode = rootnode@left_child
    if(class(newnode)[1] != "H2OLeafNode"){ # stop if node is leaf node
      newfeature = rootnode@left_child@split_feature
      newthreshold = rootnode@left_child@threshold
      recursiveTree(newnode,newfeature,newthreshold,documentationNew,anomaly)
    }else{
      return(documentationNew)
    }
  }
}

# call recursive function that traverses tree for a specific anomaly
traverseTree = function(anomaly,isoTree){
  options(scipen = 999)
  documentation <- data.frame(Feature=character(), Eq = character(), Threshold = double(),stringsAsFactors=FALSE)
  root = isoTree@root_node
  feature = root@split_feature
  threshold = root@threshold
  return(recursiveTree(root,feature,threshold,documentation,anomaly))
}

#' Find shortest path of an h2o isolation forest.
#'
#' If there are multiple shortest paths return the last one.
#' Access to h2o is assumed.
#'
#' @param isoForest The forest to explain.
#' @param anomaly A particular case to explain.
#' @keywords h2o, Isolation Forest, XAI
#' @export
findShortestPath = function(isoForest,anomaly){
  tree = h2o.getModelTree(model = isoForest, tree_number = 1)
  shortestPath = traverseTree(anomaly,tree)
  numberOfCriteria = nrow(shortestPath)
  
  for(i in 2:100){
    tree = h2o.getModelTree(model = isoForest, tree_number = i)
    if(numberOfCriteria >= nrow(traverseTree(anomaly,tree))){
      shortestPath = traverseTree(anomaly,tree)
      numberOfCriteria = nrow(traverseTree(anomaly,tree))
    }
  }
  return(shortestPath)
}


# If there are multiple shortest paths (with same length)
# find all of them (including their split features and thresholds)
findShortestPaths = function(isoForest,anomaly){
  tree = h2o.getModelTree(model = isoForest, tree_number = 1)
  shortestPath = traverseTree(anomaly,tree)
  numberOfCriteria = nrow(shortestPath)
  
  for(i in 2:100){
    tree = h2o.getModelTree(model = isoForest, tree_number = i)
    if(numberOfCriteria >= nrow(traverseTree(anomaly,tree))){
      shortestPath = traverseTree(anomaly,tree)
      numberOfCriteria = nrow(traverseTree(anomaly,tree))
    }
  }
  
  for(i in 1:100){
    tree = h2o.getModelTree(model = isoForest, tree_number = i)
    path = traverseTree(anomaly,tree)
    if(numberOfCriteria == nrow(path)){
      return(path)
    }
  }
}
