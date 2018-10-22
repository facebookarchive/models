# MobileNetV2 Quantized

## Use cases

MobileNetV2(https://arxiv.org/abs/1801.04381) improves the state of the art performance of mobile models on multiple tasks and benchmarks as well as across a spectrum of different model sizes. This model is the quantized classification model based on imagenet1K training dataset.

## Description

This is quantized version of mobilenet v2. The original full precision model is trained on Imagenet1K dataset. This is a classification model. We use quantized operators with output scale and output zero point labeled.

Please make sure your Caffe2 has QNNPACK based Int8 operators before running inference on it

## Model

init_net: https://s3.amazonaws.com/download.caffe2.ai/models/mobilenet_v2_1.0_224_quant/init_net.pb
predict_net: https://s3.amazonaws.com/download.caffe2.ai/models/mobilenet_v2_1.0_224_quant/predict_net.pb

| Model | Download | Format | Top-1 accuracy (%) | Top-5 accuracy (%) |
|-|-|-|-|-|
| quant mobilenet v2 1.0 224 | [init_net.pb](https://s3.amazonaws.com/download.caffe2.ai/models/mobilenet_v2_1.0_224_quant/init_net.pb), [predict_net.pb](https://s3.amazonaws.com/download.caffe2.ai/models/mobilenet_v2_1.0_224_quant/predict_net.pb) | caffe2 | 72.10% |
| [fp32 mobilenet v2](https://arxiv.org/abs/1801.04381) | [tf lite model](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/contrib/lite/g3doc/models.md) | tensorflow | 72% |
| Tensorflow quant mobilenet v2 1.0 224 | [tf lite model](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/contrib/lite/g3doc/models.md) | tensorflow | 70.80% |


## Inference

We used Caffe2 as framework to perform inference. 
Please make sure your Caffe2 has QNNPACK based Int8 operators before running inference on it

### Input

(N x 3 x 224 x 224)
The pre-trained model expect input images normalized in the same way, i.e. mini-batches of 3-channel RGB images of shape (N x 3 x H x W), where N is the batch size, and H and W are height and width of the image.

### Preprocessing

The images have to be loaded in to a range of [0, 255] and then normalized using mean = [0.406, 0.456, 0.485] and std = [0.225, 0.224, 0.229]. The transformation should preferrably happen at preprocessing.
The following code shows how to preprocess a NCHW tensor and prepare the input to the model:

```
from caffe2.python import brew, core, model_helper

test_data_db = <Input data path>
test_data_db_type = "lmdb"

test_model = model_helper.ModelHelper(name="test")
with core.NameScope("gpu_0"):
    reader = test_model.CreateDB(
        "test_reader", db=test_data_db, db_type=test_data_db_type
    )

mean_per_channel = [0.406 * 255, 0.456 * 255, 0.485 * 255]
std_per_channel = [0.225 * 255, 0.224 * 255, 0.229 * 255]

namescope = "gpu_0/"
data = namescope + "data_0"
label = namescope + "label"

data, label = brew.image_input(
    test_model,
    reader,
    [data, label],
    batch_size=args.batch_size,
    mean_per_channel=mean_per_channel,
    std_per_channel=std_per_channel,
    scale=256,
    crop=224,
    mirror=0,
    use_caffe_datum=True,
    is_test=1,
    color=3,
)
```

### Output

The model outputs image probablility scores for each of the 1000 classes of ImageNet (https://github.com/onnx/models/blob/master/models/image_classification/synset.txt) calculated using softmax.

### Postprocessing

Since the output of the model is the the softmax probablility scores for each class, no post-processing is needed. You can directly sort the output to report the most probable classes. 

## Dataset

Dataset used for train and validation: ImageNet (ILSVRC2012) (http://www.image-net.org/challenges/LSVRC/2012/). Check imagenet_prep (https://github.com/onnx/models/blob/master/models/image_classification/imagenet_prep.md) for guidelines on preparing the dataset.

## Validation accuracy

The accuracies obtained by the models on the validation set are mentioned above. 

## Training

We used Caffe2 as framework to perform training. 

## Validation

We used Caffe2 as framework to perform validation. 

## References

* https://arxiv.org/abs/1801.04381
* https://arxiv.org/abs/1806.08342

Contributors

* Yiming Wu
* Peizhao Zhang
* Yanghan Wang
* [houseroad](https://github.com/houseroad)

## License

Apache 2.0

