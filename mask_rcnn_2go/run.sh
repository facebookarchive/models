#!/bin/bash

set -ex

export MAX_JOBS=1

# define some variables
FAI_PEP_DIR=/tmp/FAI-PEP
CONFIG_DIR=/tmp/config
LOCAL_REPORTER_DIR=/tmp/reporter
REPO_DIR=/tmp/pytorch

SCRIPT=$(realpath "$0")
FILE_DIR=$(dirname "$SCRIPT")
COCO_DIR=$1
MODEL=$2
MODEL_DIR=${FILE_DIR}/model/${MODEL}
BENCHMARK_FILE=${FILE_DIR}/MaskRCNN2Go_COCO_minival_2014.json

mkdir -p "$CONFIG_DIR"
mkdir -p "$LOCAL_REPORTER_DIR"

# clone FAI-PEP
if [ ! -d ${FAI_PEP_DIR} ]; then
  rm -rf ${FAI_PEP_DIR}
  git clone https://github.com/facebook/FAI-PEP.git "$FAI_PEP_DIR"
  pip install six requests
fi

pip install numpy cython
pip install matplotlib pycocotools

# set up default arguments
echo "
{
  \"--commit\": \"master\",
  \"--exec_dir\": \"${CONFIG_DIR}/exec\",
  \"--framework\": \"caffe2\",
  \"--local_reporter\": \"${CONFIG_DIR}/reporter\",
  \"--model_cache\": \"${CONFIG_DIR}/model_cache\",
  \"--platforms\": \"android/with_host\",
  \"--remote_repository\": \"origin\",
  \"--repo\": \"git\",
  \"--repo_dir\": \"${REPO_DIR}\",
  \"--screen_reporter\": null
}
" > ${CONFIG_DIR}/config.txt

# clone/install pytorch
pip install numpy pyyaml mkl mkl-include setuptools cmake cffi typing

if [ ! -d "${REPO_DIR}" ]; then
  git clone --recursive --quiet https://github.com/pytorch/pytorch.git "$REPO_DIR"
fi

# install ninja to speedup the build
pip install ninja

cp ${BENCHMARK_FILE} ${BENCHMARK_FILE}_tmp
python ${FAI_PEP_DIR}/benchmarking/run_bench.py -b ${BENCHMARK_FILE} --string_map "{\"COCO_DIR\": \"${COCO_DIR}\", \"MODEL_DIR\": \"${MODEL_DIR}\"}" --config_dir "${CONFIG_DIR}"
mv ${BENCHMARK_FILE}_tmp ${BENCHMARK_FILE}
