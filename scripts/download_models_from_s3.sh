#!/bin/bash

#
# This script downloads Caffe2 models from Amazon S3 into a local folder.
#
# It can be used to synchronize models between GitHub and S3, but generally
# GitHub is considered the source of truth, so this generally shouldn't need
# to be run in the caffe2/models/ folder.
#
# For example, to download all models from S3 to ~/caffe2-models-s3, run
#
#   cd ~; mkdir caffe2-models-s3
#   cd ~/caffe2-models
#   ./scripts/download_models_from_s3.sh --base-dir ../caffe2-models-s3
#
# To just download a single model, run
#
#   cd ~; mkdir caffe2-models-s3
#   cd ~/caffe2-models
#   ./scripts/download_models_from_s3.sh --base-dir ../caffe2-models-s3 --model squeezenet
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

function download_files {
    model_dir="$1"
    flags=""
    if [ ${dry_run} -ne 0 ]; then
        flags="--dry-run"
    fi
    s3cmd sync ${flags} --acl-public --guess-mime-type "${S3_ROOT}${model_dir}/" "${model_dir}/"
}

function download_model {
    model_dir="$1"
    echo "Syncing ${model_dir}..."

    # Bring the files down
    download_files "${model_dir}"

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

# Iterate over S3 buckets and download
cd "${base_dir}"
if [[ ! -z "${model}" ]]; then
    download_model "${model}"
else
    s3_root_regex=$(echo "${S3_ROOT}" | sed -e 's/[]\/$*.^[]/\\&/g')
    model_buckets=$(s3cmd ls "${S3_ROOT}" | grep -e "^ *DIR *${s3_root_regex}" | sed -e "s/^ *DIR *${s3_root_regex}//" | sed -e "s/\/$//")
    for model_bucket in ${model_buckets}; do
        download_model "${model_bucket}"
    done
fi

echo ""
echo "Finished downloading!"
echo ""
