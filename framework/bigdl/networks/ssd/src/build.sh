#! /bin/bash
CURRENT_DIR=$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )
cd ${CURRENT_DIR}/models
mvn clean install
cd ${CURRENT_DIR}/objectDetection
mvn clean package -DskipTests
