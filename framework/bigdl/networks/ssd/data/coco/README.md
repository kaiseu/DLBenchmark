1. First needs to install some dependencies(for CentOS)
```
pip install Cython matplotlib
yum install -y tkinter
```
2. Folder PythonAPI and common is modified from [here](https://github.com/weiliu89/coco/tree/dev)
```
git clone https://github.com/weiliu89/coco.git
cd coco
git checkout dev
cd PythonAPI
python setup.py build_ext --inplace
# Check scripts/batch_split_annotation.py and change settings accordingly.
python scripts/batch_split_annotation.py
```
2. Below files is modified from [here](https://github.com/intel-analytics/analytics-zoo/tree/master/pipeline/objectDetection/data/coco)
     *   create_list.py
     *   convert_coco.sh


#### Known issue
1. When building coco API to parse annotations, if Cython is not installed, ``` python setup.py build_ext --inplace ``` would failed with below error. So first install Cython.
     >     Traceback (most recent call last):
     >     File "setup.py", line 2, in <module>
     >     from Cython.Build import cythonize
     >     ImportError: No module named Cython.Build
  
 ```
 sudo pip install Cython
 ```
