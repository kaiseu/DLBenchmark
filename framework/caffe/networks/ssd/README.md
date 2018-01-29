## SSD: Single Shot MultiBox Detector
SSD is a unified pipeline for **object detection**, you can find the details from [here](https://github.com/weiliu89/caffe/tree/ssd).

### Environment
- Python 2.7
- Cmake
- protobuf, glog, gflags, hdf5
- [BLAS](https://en.wikipedia.org/wiki/Basic_Linear_Algebra_Subprograms) via ATLAS, MKL, or OpenBLAS
- [Boost](http://www.boost.org/) >= 1.55
### Basical Structure
- bin
    - prepare.sh: script for prepare dataset, base model, etc. 
    - train.sh: train the model(Not support yet)
    - predict.sh: script for predicting based on user's configuration
- conf
    - localSetting.conf: SSD specific settings, which includes dataset, model, store dir, etc.
- data
    - coco: some scripts for COCO dataset
    - pascal: scripts for PASCAL dataset
- src

- logs

### How to Run
Follow below instructions to run SSD with Caffe.
#### Build Caffe From source code
We referenced the [Guide to multi-node training with Intel® Distribution of Caffe*](https://github.com/intel/caffe/wiki/Multinode-guide).
Here we test on CentOS7.4, it may have slight variance due to different OS distribution, please refer the [guide](http://caffe.berkeleyvision.org/installation.html) for your distribution.
1. Install dependencies and system tools
```shell
yum -y install python-devel boost boost-devel cmake numpy numpy-devel gflags gflags-devel glog glog-devel protobuf protobuf-devel hdf5 hdf5-devel lmdb lmdb-devel leveldb leveldb-devel snappy-devel opencv opencv-devel
```
pacages: numpy-devel gflags gflags-devel glog glog-devel hdf5 hdf5-devel lmdb lmdb-devel leveldb leveldb-devel may not be available from your OS repo, please install them manaually.

