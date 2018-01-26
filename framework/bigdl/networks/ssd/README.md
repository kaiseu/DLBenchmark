### SSD: Single Shot MultiBox Detector
SSD is a unified pipeline for **object detection**, you can find the details from [here](https://github.com/weiliu89/caffe/tree/ssd). Here we use it as a workload(network) of our benchmark, the source code of this network is forked from the [example](https://github.com/intel-analytics/analytics-zoo/tree/master/pipeline/objectDetection/ssd) of [BigDL](https://github.com/intel-analytics/BigDL) project. we may modify the source code for easy use, so it's recommended to get the code from [here](https://github.com/kaiseu/analytics-zoo/tree/master/pipeline/objectDetection).
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
  
