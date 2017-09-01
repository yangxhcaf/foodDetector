#======================================================================
# No run your own CNN
#======================================================================

#======================================================================
# Required packages
#======================================================================

library(mxnet)
library(imager)
library(abind)


#======================================================================
# Some functions
#======================================================================

source("R/functions.R")


#======================================================================
# Prepare data
#======================================================================

# train <- preproc.images("data/training", size = 60)
# center <- apply(train$X, 1:3, mean)
# train$X <- sweep(train$X, 1:3, STATS = center)
# valid <- preproc.images("data/validation", size = 60)
# valid$X <- sweep(valid$X, 1:3, STATS = center)
# test <- preproc.images("data/evaluation", size = 60)
# test$X <- sweep(test$X, 1:3, STATS = center)
# save(train, valid, test, file = "data/food_customized.RData")

load("data/food_customized.RData", verbose = TRUE)


#======================================================================
# Model specification
#======================================================================

# input
data <- mx.symbol.Variable('data')
# first conv
conv1 <- mx.symbol.Convolution(data=data, kernel=c(5,5), num_filter=10)
tanh1 <- mx.symbol.Activation(data=conv1, act_type="tanh")
pool1 <- mx.symbol.Pooling(data=tanh1, pool_type="max",
                           kernel=c(2,2), stride=c(2,2))
# second conv
conv2 <- mx.symbol.Convolution(data=pool1, kernel=c(5,5), num_filter=20)
tanh2 <- mx.symbol.Activation(data=conv2, act_type="tanh")
pool2 <- mx.symbol.Pooling(data=tanh2, pool_type="max",
                           kernel=c(2,2), stride=c(2,2))
# first fullc with dropout
flatten <- mx.symbol.Flatten(data=pool2)
fc1 <- mx.symbol.FullyConnected(data=flatten, num_hidden=50)
tanh3 <- mx.symbol.Activation(data=fc1, act_type="tanh")
dropout <- mx.symbol.Dropout(data = tanh3, p = 0.3)
# second fullc
fc2 <- mx.symbol.FullyConnected(data=dropout, num_hidden=2)
# loss
lenet <- mx.symbol.SoftmaxOutput(data=fc2)


#======================================================================
# Model fit
#======================================================================

mx.set.seed(0)
tic <- proc.time()
device.cpu <- mx.cpu()
model <- mx.model.FeedForward.create(lenet, X=train$X, y=train$y,
                                     ctx=device.cpu, num.round=3, array.batch.size=100,
                                     learning.rate=0.05, momentum=0.9, wd=0.00001,
                                     eval.metric=mx.metric.accuracy,
                                     batch.end.callback=mx.callback.log.train.metric(1),
                                     epoch.end.callback=mx.callback.log.train.metric(100))

# Evaluate on validation set
pred <- round(t(predict(model, valid$X))[, 2])
mean(pred != valid$y) #  0.22
