# Caffe2 Model Repository
This is a repository for storing pre-trained Caffe2 models.
You can use Caffe2 to help you download or install the models on your machine.

### Prerequisites

Install [Caffe2](https://github.com/caffe2/caffe2) with Python bindings.

### Download

To download a model locally, run

    python -m caffe2.python.models.download squeezenet

which will create a folder `squeezenet/` containing both an `init_net.pb` and `predict_net.pb`.

### Install

To install a model, run

    python -m caffe2.python.models.download -i squeezenet

which will allow later `import`s of the model directly in Python:

    from caffe2.python.models import squeezenet
    print(squeezenet.init_net.name)
    print(squeezenet.predict_net.name)

### Subdirectories

To download a model in a subdirectory (for example, style transfer), run

    python -m caffe2.python.models.download style_transfer/crayon

and this will create a folder `style_transfer/crayon/` containing both an `init_net.pb` and `predict_net.pb`.

Same applies to the `-i` install option.
