## SSD: Single Shot MultiBox Detector
SSD is a unified pipeline for **object detection**, you can find the details from [here](https://github.com/weiliu89/caffe/tree/ssd). Here we use it as a workload(network) of our benchmark, the source code of this network is forked from the [example](https://github.com/intel-analytics/analytics-zoo/tree/master/pipeline/objectDetection/ssd) of [BigDL](https://github.com/intel-analytics/BigDL) project. we may modify the source code for easy use, so it's recommended to get the code from [here](https://github.com/kaiseu/analytics-zoo/tree/master/pipeline/objectDetection).

### Environment
- Maven 3
- Java 7 or higher
- Apache Spark 2.2.0
- Python2.7
- Hadoop 2.6 or higher(optinal)

### Basical Structure
- bin
    - prepare.sh: script for prepare dataset, base model, etc. 
    - train.sh: train the model(Not support yet)
    - predict.sh: script for predicting based on user's configuration
- conf
    - localSetting.conf: SSD specific settings, which includes dataset, model, store dir, quantization, Spark parameters, etc.
- data
    - coco: some scripts for COCO dataset
    - pascal: scripts for PASCAL dataset
- src
    - models: source code of module models
    - objectDetection: source code of SSD
- logs

### How to Run
Follow below instructions to run the benchmark.
#### Prerequisites
- Spark environment should be ready
- Java Home and Spark Home should be set, System PATH should be updated
- If you store the data on HDFS, Hadoop Home should be set
- Maven 3 is needed, it need to build from source code if it's the first time to run this workload, so network connecting is needed

#### Configurations for the workload
- Edit ${DLBenchmark}/conf/localSetting.conf based on the instructions in this file. Below are the frequently used settings:
    - SPARK_MASTER: Spark master to use
    - HDFS_NAMENODE: if stores dataset on HDFS
    - EXECUTOR_CORES:  number of cores for executor
    - NUM_EXECUTORS: number of executors
    - DRIVER_MEMORY: memory for Spark driver
    - EXECUTOR_MEMORY:  memory for Spark executors
    - BASE_MODEL： Base Model Name of SSD
    - DATA_SET： Data Set to use
    - IS_QUANT_ENABLE： Whether to  enable quantization?
    - IMAGE_RESOLUTION： Image Resolution, currently it only can be 300 or 512
    - FOLDER_TYPE： Local image folder or hdfs sequence folder, can only be local or seq
    - IS_HDFS: The image data/sequence files is on HDFS or local disks, Can be true or false, true is for HDFS, default is true
    - DATA_REPLICA: Data replica for a given dataset, not HDFS data replica, the default value is 1
    - TEMP_DATA_DIR: Dir to store the temp data
- Prepare dataset and base model
    - One can execute from DLBenchmark entry(formal) or only have a test from SSD entry
    - For DLBenchmark entry, you need edit ${DLBenchmark}/conf/userSettings.conf, and execute ${DLBenchmark}/bin/run.sh
        - ENGINE="bigdl"
        - NETWORK="ssd"
        - PHASE="prepare"
    - For SSD entry, execute ${SSD_ROOT}/bin/prepare.sh after all the settings done
- Run predict
    - Also, one can execute from DLBenchmark entry(formal) or only have a test from SSD entry
    - For DLBenchmark entry, you need edit ${DLBenchmark}/conf/userSettings.conf, and execute ${DLBenchmark}/bin/run.sh
        - ENGINE="bigdl"
        - NETWORK="ssd"
        - PHASE="predict"
    - For SSD entry, execute ${SSD_ROOT}/bin/predict.sh after all the settings done
- Results and logs
    - The running logs as well as the user's configuration/setting files should be stored in ${DLBenchmark}/logs/bigdl/logs-bigdl-ssd-${date}
    - The temp log would stores in ${SSD_ROOT}/logs/logs_bigdl-XXX.log
- Run all in one-click
    - One can run all the above with just one-click, which is what our DLBenchmark target for. To run with one-click, One can put them together:
        - ENGINE="bigdl"
        - NETWORK="ssd"
        - PHASE="prepare,predict"
### Backups
Some notes.
#### Build From source code
If the executable jar does not exist(e.g. for the first time to run), it will automatically try to download the jar from internal server, for external use we suggest follow below steps to build from source code.
- Option one
    1. Clone analystics-zoo source code
    ```
    git clone https://github.com/kaiseu/analytics-zoo
    ```
    2. Build SSD  
    ```
    cd ${analytics-zoo}/pipeline/objectDetection
    ./build.sh
    ```
    3. Copy the executable jar to DLBenchmark
    ```
    mkdir -p ${TEMP_DATA_DIR}/models/ssd/jars/
    cp -r ${analytics-zoo}/pipeline/objectDetection/dist/target/object-detection-0.1-SNAPSHOT-jar-with-dependencies-and-spark.jar  ${TEMP_DATA_DIR}/models/ssd/jars/
    ```
- Option two
    1. Clone DLBenchmark source code
    ```
    git clone https://github.com/kaiseu/DLBenchmark.git
    ```
    2. Build Automatically
    ```
    cd ${DLBenchmark}/framework/bigdl/networks/ssd/src
    ./build.sh
    ```
    - ${analytics-zoo} is analystics-zoo source code path
    - ${TEMP_DATA_DIR} is the dir for temp data storage, which is configured in ${DLBenchmark}/framework/bigdl/networks/conf/localSetting.conf
    - ${DLBenchmark} represents the path of DLBenchmark.

#### Issues may occur
**1. From pycocotools.coco import COCO fails**
  - Traceback (most recent call last):
    File "/root/XX/DLBenchmark/framework/bigdl/networks/ssd/data/coco/PythonAPI/scripts/split_annotation.py", line 9, in <module>
      from pycocotools.coco import COCO
    File "/root/XX/DLBenchmark/framework/bigdl/networks/ssd/data/coco/PythonAPI/pycocotools/coco.py", line 55, in <module>
      from . import mask as maskUtils
    File "/root/XX/DLBenchmark/framework/bigdl/networks/ssd/data/coco/PythonAPI/pycocotools/mask.py", line 3, in <module>
      import pycocotools._mask as _mask
  ImportError: /root/XX/DLBenchmark/framework/bigdl/networks/ssd/data/coco/PythonAPI/pycocotools/_mask.so: undefined symbol: PyFPE_jbuf
  
  >**Solved:** 
  ```
      cd coco/PythonAPI
      make
      sudo make install
      sudo python setup.py install
   ```
  
