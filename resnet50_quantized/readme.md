# ResNet50 Quantized Model

## Use cases

ResNet models perform image classification - they take images as input and classify the major object in the image into a set of pre-defined classes. They are trained on ImageNet dataset which contains images from 1000 classes. ResNet models provide very high accuracies with affordable model sizes. They are ideal for cases when high accuracy of classification is required. 

This quantized model is based on the ResNet50 model with weights and activations quantized to int8. It achieves comparable accuracy to the original ResNet50 with lower memory bandwidth requirement and better performance. 

## Description

Deeper neural networks are more difficult to train. Residual learning framework ease the training of networks that are substantially deeper. The research explicitly reformulate the layers as learning residual functions with reference to the layer inputs, instead of learning unreferenced functions. It also provide comprehensive empirical evidence showing that these residual networks are easier to optimize, and can gain accuracy from considerably increased depth. 

This quantized ResNet50 model is generated in the following steps. After training ResNet50 model using ImageNet data set, the quantization parameters of weights and activations for each operator were chosen based on their histograms using 10K sampled images from training dataset. Instead of pessimistically choosing quantization parameters to represent all the numbers observed including the global minimum and maximum, we choose quantization parameters that minimize L2 quantization errors with respect to the collected histogram. We use symmetric quantization (float value 0.0f is quantized to 0) for weights to minimize saturation when 16-bit accumulation is used (this is a work around a fact that 16-bit accumulation is needed for high performance in current x86 processors). Then the operators in the trained Resnet50 model was converted into the quantized version of operators using these quantization parameters except for Softmax operator. Each of these quantized operator has two arguments: Y_scale and Y_zero_point, which are the quantization parameters for the output tensor of the operator. The DNNLOWP engine is used in the quantized operators to utilize fbgemm and handle the quantized arithmetics.

## Model

The model below are the original fp32 ResNet50 model and quantized int8 ResNet50 model trained on ImageNet data set. 

| Model | Download | Format | Top-1 accuracy (%) | Top-5 accuracy (%) |
|-|-|-|-|-|
| Original ResNet50 |  [resnet50.json](https://github.com/facebook/FAI-PEP/blob/master/specifications/models/caffe2/resnet50/resnet50.json) | Caffe2 pb | 75.9% | 92.9% |
| Quantized ResNet50 | [resnet50_quantized_init_net.pb](https://s3.amazonaws.com/download.caffe2.ai/models/resnet50_quantized/resnet50_quantized_init_net.pb), [resnet50_quantized_init_net.pbtxt](https://s3.amazonaws.com/download.caffe2.ai/models/resnet50_quantized/resnet50_quantized_init_net.pbtxt), [resnet50_quantized_predict_net.pb](https://s3.amazonaws.com/download.caffe2.ai/models/resnet50_quantized/resnet50_quantized_predict_net.pb), [resnet50_quantized_predict_net.pbtxt](https://s3.amazonaws.com/download.caffe2.ai/models/resnet50_quantized/resnet50_quantized_predict_net.pbtxt) | Caffe2 pb | 75.7% | 92.9% |

## Inference

We used Caffe2 as framework to perform inference. 

### Input

The pre-trained model expect input images normalized in the same way, i.e. mini-batches of 3-channel RGB images of shape (N x 3 x H x W), where N is the batch size, and H and W are height and width of the image. 

### Preprocessing

The images have to be loaded in to a range of [0, 255] and then normalized using mean = [0.406, 0.456, 0.485] and std = [0.225, 0.224, 0.229]. The transformation should preferrably happen at preprocessing.
The following code shows how to preprocess a NCHW tensor and prepare the input to the model:

```python
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

* ResNet-v1 Deep residual learning for image recognition (https://arxiv.org/abs/1512.03385) He, Kaiming, Xiangyu Zhang, Shaoqing Ren, and Jian Sun. In Proceedings of the IEEE conference on computer vision and pattern recognition, pp. 770-778. 2016.
* ResNet-v2 Identity mappings in deep residual networks (https://arxiv.org/abs/1603.05027) He, Kaiming, Xiangyu Zhang, Shaoqing Ren, and Jian Sun. In European Conference on Computer Vision, pp. 630-645. Springer, Cham, 2016.
* Caffe2 (https://caffe2.ai/)

## Contributors

* [hx89](https://github.com/hx89) (Facebook)
* [csummersea](https://github.com/csummersea) (Facebook)
* [dskhudia](https://github.com/dskhudia) (Facebook)
* [harouwu](https://github.com/harouwu) (Facebook)
* [prigoya](https://github.com/prigoyal) (Facebook)
* [jspark1105](https://github.com/jspark1105) (Facebook)
* [houseroad](https://github.com/houseroad) (Facebook)

## License

Apache 2.0
