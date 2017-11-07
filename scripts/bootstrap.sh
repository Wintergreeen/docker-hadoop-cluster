#!/bin/bash

if [ -n $MASTER ]; then
    hdfs namenode -format spark-cluster
    hadoop-daemon.sh --script hdfs start namenode
    yarn-daemon.sh start resourcemanager
    yarn-daemon.sh start nodemanager
else
    hadoop-daemon --script hdfs start datanode
fi
