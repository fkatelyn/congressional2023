import glob
import os
import shutil
import gradio as gr
import torch
from PIL import Image
from ultralytics import YOLO



# Images
torch.hub.download_url_to_file('https://github.com/ultralytics/yolov5/raw/master/data/images/zidane.jpg', 'zidane.jpg')
torch.hub.download_url_to_file('https://github.com/ultralytics/yolov5/raw/master/data/images/bus.jpg', 'bus.jpg')

# Open an existing image
img = Image.open("bus.jpg")

# Define the size
size = (300, 300)

# Resize the image
img_resized = img.resize(size, Image.LANCZOS)


# Model
#model = torch.hub.load('ultralytics/yolov8', 'yolov7s')  #
# force_reload=True to update
model = YOLO(f'/Users/katelyn/Downloads/palmtree/weights/7/best.pt')
model.export(format='coreml', nms=True)#, weights_dir='/content/runs/detect/train/weights')


def yolo_img(im, conf, size=640):
    g = (size / max(im.size))  # gain
    im = im.resize((int(x * g) for x in im.size), Image.LANCZOS)  # resize

    results = model(im)  # inference
    results.render()  # updates results.imgs with boxes and labels
    #print(results.imgs)
    #print(results.imgs[0].shape)
    #results.imgs[0] = np.asarray(results.imgs[0]
    return Image.fromarray(results.ims[0])


def yolo_video(im, conf, size=640):
    print(im)
    print(conf)
    print(size)
    OUTPUT_DIR = '/tmp/demo'
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)

    results = model.predict(im, conf=conf, project=OUTPUT_DIR, name='runs',
                            save=True)  #
    file_name = os.path.basename(im)
    return f'{OUTPUT_DIR}/runs/{file_name}'
    # inference

    #print(results.imgs)
    #print(results.imgs[0].shape)
    #results.imgs[0] = np.asarray(results.imgs[0]
    return results[0].path
    #return im


inputs = gr.inputs.Image(type='pil', label="Original Image")
outputs = gr.outputs.Image(type="pil", label="Output Image")

title = "Palm Oil Tree health detection"
description = "Upload an image or click an example image to use."
article = ""

examples = glob.glob(f'~/Downloads/*.mp4')
examples = list(map(lambda x: [x], examples))
#gr.Interface(yolo, inputs, outputs, title=title, description=description,
# article=article, examples=examples, analytics_enabled=False).launch(
#    debug=True)

gr.Interface(yolo_video,
             inputs=[gr.Video(type='file'), gr.Slider(0.0, 1.0, 0.5)],
             outputs=gr.Video(),

             title=title,
             description=description,
             examples=examples,
             analytics_enabled=False).launch(debug=True)
