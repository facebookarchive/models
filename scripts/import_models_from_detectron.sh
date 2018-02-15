#!/bin/bash

#
# This script converts models from the Detectron model zoo at
#
#    https://github.com/facebookresearch/Detectron/blob/master/MODEL_ZOO.md
#
# into pb files suitable for pure Caffe2 deployment and inference on CPU.
#
#   * Only a small number of models are currently supported. *
#
# For example, to convert all *supported* models and save them
# to ~/caffe2-models, run
#
#   cd ~/caffe2-models
#   ./scripts/import_models_from_detectron.sh
#
# To just convert a single model, run
#
#   cd ~/caffe2-models
#   ./scripts/import_models_from_detectron.sh --model e2e_faster_rcnn_R-50-C4_1x_35857197
#

set -e

# Exit immediately for Ctrl-C
trap "exit" INT

DETECTRON_S3_ROOT="https://s3-us-west-2.amazonaws.com/detectron/"

SUPPORTED_MODELS=(
  "e2e_faster_rcnn_R-50-C4_1x"
  "e2e_faster_rcnn_R-50-C4_2x"
)

# Defaults
caffe2_models_dir="$PWD"
caffe2_dir="$(dirname ${caffe2_models_dir})/caffe2"
detectron_dir="$(dirname ${caffe2_models_dir})/detectron"
model=""
dry_run=0

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --caffe2-models-dir)
            shift
            caffe2_models_dir="$1"
            ;;
        --caffe2-dir)
            shift
            caffe2_dir="$1"
            ;;
        --detectron-dir)
            shift
            detectron_dir="$1"
            ;;
        --model)
            shift
            model="$1"
            ;;
        --dry-run)
            dry_run=1
            ;;
        *)
            echo "Invalid option: $1"
            exit 1
            ;;
    esac
    shift
done

function download_pkl {
    model="$1"
}

function import_model {
    model="$1"
    id=""
    base_name=""
    net_name=""
    pkl_name=""
    pkl_url=""
    cfg=""
    value_info_data=""
    zoo_url=""
    backbone=""
    type=""
    lr_schedule=""

    if [ "${model}" == "e2e_faster_rcnn_R-50-C4_1x" ]; then
        # Include model id number at the end
        id="35857197"
        base_name="${model}_${id}"
        net_name="detectron_${base_name}"
        pkl_name="${base_name}.pkl"
        pkl_url="${DETECTRON_S3_ROOT}35857197/12_2017_baselines/e2e_faster_rcnn_R-50-C4_1x.yaml.01_33_49.iAX0mXvW/output/train/coco_2014_train%3Acoco_2014_valminusminival/generalized_rcnn/model_final.pkl"
        cfg="configs/12_2017_baselines/e2e_faster_rcnn_R-50-C4_1x.yaml"
        # We can't reliably extract these from the model, so specified here
        value_info_data='{"data": [1, [1, 3, 800, 800]]}'
        zoo_url="https://github.com/facebookresearch/Detectron/blob/master/MODEL_ZOO.md#end-to-end-faster--mask-r-cnn-baselines"
        backbone="R-50-C4"
        type="Faster"
        lr_schedule="1x"
    elif [ "${model}" == "e2e_faster_rcnn_R-50-C4_2x" ]; then
        # Include model id number at the end
        id="35857281"
        base_name="${model}_${id}"
        net_name="detectron_${base_name}"
        pkl_name="${base_name}.pkl"
        pkl_url="${DETECTRON_S3_ROOT}35857281/12_2017_baselines/e2e_faster_rcnn_R-50-C4_2x.yaml.01_34_56.ScPH0Z4r/output/train/coco_2014_train%3Acoco_2014_valminusminival/generalized_rcnn/model_final.pkl"
        cfg="configs/12_2017_baselines/e2e_faster_rcnn_R-50-C4_2x.yaml"
        # We can't reliably extract these from the model, so specified here
        value_info_data='{"data": [1, [1, 3, 800, 800]]}'
        zoo_url="https://github.com/facebookresearch/Detectron/blob/master/MODEL_ZOO.md#end-to-end-faster--mask-r-cnn-baselines"
        backbone="R-50-C4"
        type="Faster"
        lr_schedule="2x"
    else
        echo "Detectron model ${model} isn't supported yet. Exiting."
        exit 1
    fi

    # Construct README.md content
    readme_data="# Detectron ${model}

* Original: ${zoo_url}
* Backbone: ${backbone}
* Type: ${type}
* LR Schedule: ${lr_schedule}
* Model ID: ${id}

### Install

To install this model, run

    python -m caffe2.python.models.download -i detectron/${model}

"

    pushd "${detectron_dir}"
    mkdir -p "models/pb_output"

    # Download the pkl file
    if [ ! -f "models/${pkl_name}" ]; then
        echo "Downloading ${model}..."
        wget "${pkl_url}" -O "models/${pkl_name}"
    fi

    # Convert for CPU and run a test image
    echo "Converting ${model}..."
    python tools/convert_pkl_to_pb.py --use_nnpack 0 --net_name "${net_name}" --cfg "${cfg}" --out_dir "models/pb_output/${model}/" --test_img "demo/16004479832_a748d55f21_k.jpg" TEST.WEIGHTS "models/${pkl_name}"

    # Convert for NNPACK and *don't* pass in a test image, since this
    # likely won't work on a server machine
    # python tools/convert_pkl_to_pb.py --use_nnpack 1 --net_name "${net_name}" --cfg "${cfg}" --out_dir "models/pb_output/${model}_nnpack/" TEST.WEIGHTS "models/${pkl_name}"

    # Switch back to Caffe2 models directory
    popd

    # Copy the model files over
    if [ ${dry_run} -eq 0 ]; then
        mkdir -p "detectron/${model}"
        cp "${detectron_dir}/models/pb_output/${model}/model_init.pb" "detectron/${model}/init_net.pb"
        cp "${detectron_dir}/models/pb_output/${model}/model.pb" "detectron/${model}/predict_net.pb"
        cp "${detectron_dir}/models/pb_output/${model}/model.pbtxt" "detectron/${model}/predict_net.pbtxt"
        cp "${detectron_dir}/models/pb_output/${model}/model_def.png" "detectron/${model}/predict_net_def.png"
        cp "${detectron_dir}/models/pb_output/${model}/model_def.png" "detectron/${model}/predict_net_def.png"
        echo "${value_info_data}" > "detectron/${model}/value_info.json"
        echo "${readme_data}" > "detectron/${model}/README.md"
    fi

    echo ""
}

# Detectron requires the build directory in our path
if [ ! -d "${caffe2_dir}/build" ]; then
    echo "Detectron requires builds in the ${caffe2_dir}/build folder."
    echo "Please re-build Caffe2 for Detectron by running:"
    echo ""
    echo "    pip uninstall caffe2"
    echo "    cd ${caffe2_dir}"
    echo "    mkdir build && cd build"
    echo "    cmake .."
    echo "    sudo make install"
    echo ""
    exit 1
fi
export LD_LIBRARY_PATH="${caffe2_dir}/build/lib:${LD_LIBRARY_PATH}"
export PYTHONPATH="${caffe2_dir}/build:${PYTHONPATH}"

# Move to the models directory
cd "${caffe2_models_dir}"

# Setup git lfs
if ! git lfs 1> /dev/null 2> /dev/null; then
    if [ "$(uname)" == 'Darwin' ]; then
        echo "git lfs command not found. Please install it with:"
        echo ""
        echo "    brew install git-lfs"
        echo "    git lfs install"
        echo ""
        echo "More details at https://git-lfs.github.com/"
        echo ""
    else
        echo "git lfs command not found. Please install it and run:"
        echo ""
        echo "    git lfs install"
        echo ""
        echo "More details at https://git-lfs.github.com/"
        echo ""
    fi
    exit 1
fi
git lfs pull

# Iterate over models and convert
if [[ ! -z "${model}" ]]; then
    import_model "${model}"
else
    for model_dir in ${SUPPORTED_MODELS[@]}; do
        import_model "${model_dir}"
    done
fi

echo ""
echo "Finished importing!"
echo ""
