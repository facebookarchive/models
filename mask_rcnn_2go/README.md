# MaskRCNN2GO Model

Owner: Peizhao Zhang (stzpz@fb.com)

## Model
* MaskRCNN2GO (bbox + segmentation) with 81 classes
* float32 and int8 models
* Trained on COCO 2014 dataset
* int8 model fine-tuned with fake-quantization

## Performance 
  * Evaluation dataset: COCO 2014 minival
  * Metric: mAP[IoU=0.50:0.95]
  * Proposals: 3000/100 (pre/post nms) 

   Model  | Bbox | Segmentation
  ------- | ---- | ------------
  float32 | 25.1 |     21.6
  int8    | 24.8 |     21.7

## Input
  * data (1, 3, H, W), min(H, W) = 320, BGR in range [0, 255]
  * im_info (1, 3) [scaled_height, scaled_width, scale]

## Evaluation
* Download COCO 2014 minival dataset
* Update path in run_eval.sh
* Run run_eval.sh

## Model source
* f93520960
* f96110081:934610037

## Acknowledgement

Thanks a lot for the help from Carole-Jean Wu, Fei Sun, Yiming Wu and Yanghan Wang.
