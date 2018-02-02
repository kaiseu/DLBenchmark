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
1. git clone the source code
```shell
cd /opt
git clone https://github.com/intel/caffe.git intelcaffe
cd intelcaffe
```
2. Install dependencies and system tools
```shell
yum install epel-release
yum clean all
# export system proxy if needed
export https_proxy=your_proxy_server:server_port
yum -y install python-devel boost boost-devel cmake numpy numpy-devel gflags gflags-devel glog glog-devel protobuf protobuf-devel hdf5 hdf5-devel lmdb lmdb-devel leveldb leveldb-devel snappy-devel opencv opencv-devel
```
pacages: numpy-devel gflags gflags-devel glog glog-devel hdf5 hdf5-devel lmdb lmdb-devel leveldb leveldb-devel may not be available from your OS repo, please install them manaually.

```shell
mkdir packages && cd packages
# glog
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/google-glog/glog-0.3.3.tar.gz
tar zxvf glog-0.3.3.tar.gz
cd glog-0.3.3
./configure
make && make install
# gflags
wget https://github.com/schuhschuh/gflags/archive/master.zip
unzip master.zip
cd gflags-master
mkdir build && cd build
export CXXFLAGS="-fPIC" && cmake .. && make VERBOSE=1
make && make install
```

```shell
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libaec-1.0.2-1.el7.x86_64.rpm
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libaec-devel-1.0.2-1.el7.x86_64.rpm
yum install libaec-1.0.2-1.el7.x86_64.rpm libaec-devel-1.0.2-1.el7.x86_64.rpm

# hdf5 hdf5-devel
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/h/hdf5-1.8.12-10.el7.x86_64.rpm
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/h/hdf5-devel-1.8.12-10.el7.x86_64.rpm
yum install hdf5-1.8.12-10.el7.x86_64.rpm hdf5-devel-1.8.12-10.el7.x86_64.rpm

# lmdb lmdb-devel
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/lmdb-libs-0.9.18-1.el7.x86_64.rpm
yum install lmdb-libs-0.9.18-1.el7.x86_64.rpm
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/lmdb-0.9.18-1.el7.x86_64.rpm
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/lmdb-devel-0.9.18-1.el7.x86_64.rpm
yum install lmdb-0.9.18-1.el7.x86_64.rpm lmdb-devel-0.9.18-1.el7.x86_64.rpm

# leveldb leveldb-devel

wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/leveldb-1.12.0-11.el7.x86_64.rpm
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/l/leveldb-devel-1.12.0-11.el7.x86_64.rpm
yum install leveldb-1.12.0-11.el7.x86_64.rpm leveldb-devel-1.12.0-11.el7.x86_64.rpm
```
3. Build from Cmake
```shell
cd /opt/intelcaffe
mkdir build && cd build
```
Execute the following CMake command in order to prepare the build:
```shell
cmake .. -DBLAS=mkl -DUSE_MLSL=1 -DCPU_ONLY=1
```
Execute make command to build Intel® Distribution of Caffe* with multi-node support.
```shell
make -j <number_of_physical_cores> -k
cd ..
```
Copy the built-out binaries across Cluster Nodes:
```shell
pscp -h slaves -r intelcaffe /opt/intelcaffe
```
#### Prepare the LMDB files
```shell
cd $CAFFE_ROOT
# edit DATAPATH in examples/ssd/ssdvars.sh to point to your VOC dataset
source examples/ssd/ssdvars.sh
# Create the trainval.txt, test.txt, and test_name_size.txt
./data/VOC0712/create_list.sh
# It will create lmdb files for trainval and test with encoded original image:
# - $DATAPATH/data/VOCdevkit/VOC0712/lmdb/VOC0712_trainval_lmdb
# - $DATAPATH/data/VOCdevkit/VOC0712/lmdb/VOC0712_test_lmdb
# and make soft links at examples/VOC0712/
./data/VOC0712/create_data.sh
```
#### Notable issues
- Failed to create the LMDB file, after source examples/ssd/ssdvars.sh, nothing happened(no output). It turns out to be caused by the numpy version issue. After reboot and re-try, it showed the error message: "RuntimeError: module compiled against API version 0xa but this version of numpy is 0x7".

resolved by:
```shell
pip install numpy --upgrade
```



