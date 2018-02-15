#!/bin/bash

#
# This script uploads Caffe2 models from a local folder to Amazon S3.
#
# It can be used to synchronize models that have been added or modified
# in GitHub up to S3. Note that this should be run with caution, since
# S3 is where users download models from.
#
#   * AWS credentials with write access are required.
#   * Installing git LFS (https://git-lfs.github.com/) is also required.
#
# For example, to dry-run sync all models, run
#
#   cd ~/caffe2-models
#   ./scripts/upload_models_to_s3.sh --dry-run
#
# To just upload a single model, run
#
#   cd ~/caffe2-models
#   ./scripts/upload_models_to_s3.sh --dry-run --model squeezenet
#

set -e

S3_ROOT="s3://download.caffe2.ai/models/"

# Defaults
base_dir="$PWD"
model=""
dry_run=0

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base-dir)
            shift
            base_dir="$1"
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

function upload_files {
    model_dir="$1"
    shift
    files=("$@")
    flags=()
    if [ ${dry_run} -ne 0 ]; then
        flags+=(" --dry-run")
    fi

    for fname in ${files[@]}; do
        flags+=(" --include '${fname}'")
    done
    s3cmd sync ${flags[@]} --acl-public --guess-mime-type "${model_dir}/" "${S3_ROOT}${model_dir}/"
}

function upload_model {
    model_dir="$1"
    files=()

    # Skip this directory if these files don't exist
    required=(
        "init_net.pb"
        "predict_net.pb"
    )
    for fname in ${required}; do
        if [ ! -f "${model_dir}/${fname}" ]; then
            return
        fi
        if grep -q "^version https:\/\/git\-lfs" "${model_dir}/${fname}"; then
            echo "ERROR: ${model_dir}/${fname} is LFS and not downloaded! Exiting."
            exit 1
        fi
        files+=("${fname}")
    done

    echo "Syncing ${model_dir}..."

    # Warn about these files not existing
    encouraged=(
        "predict_net.pbtxt"
        "value_info.json"
    )
    for fname in ${encouraged}; do
        if [ ! -f "${model_dir}/${fname}" ]; then
            echo "WARNING: ${model_dir}/${fname} not found - still uploading"
        fi
        files+=("${fname}")
    done

    # We want to whitelist everything
    files+=(
        "README.md"
        "original.caffemodel"
        "deploy.prototxt"
        "solver.prototxt"
        "train_val.prototxt"
        "quick_solver.prototxt"  # Under bvlc_googlenet
        "ilsvrc_2012_mean.npy"  # Under bvlc_alexnet and bvlc_reference_caffenet
        "predict_net.pb.del"  # Under shufflenet
        "predict_net.pbtxt.del"  # Under shufflenet
        "predict_net_def.png"  # Under detectron
    )

    # Sync the valid files found
    upload_files "${model_dir}" "${files[@]}"

    echo ""
}

# Setup s3cmd
if [ ! "$(command -v s3cmd)" ]; then
    if [ "$(uname)" == 'Darwin' ]; then
        echo "s3cmd command not found. Please install it with:"
        echo ""
        echo "    brew install s3cmd"
        echo ""
    else
        echo "s3cmd command not found. Please install it."
    fi
    exit 1
fi
if [ ! -f ~/.s3cfg ]; then
    s3cmd --configure
fi

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

# Iterate over directories and upload
cd "${base_dir}"
if [[ ! -z "${model}" ]]; then
    upload_model "${model}"
else
    model_dirs=$(find . -type d -maxdepth 2 -mindepth 1 \
        -not -path '*/\.*' -not -name 'scripts' -not -name 'mnist' | sed 's|^\./||')
    for model_dir in ${model_dirs}; do
        upload_model "${model_dir}"
    done
fi

echo ""
echo "Finished uploading!"
echo ""
