import coremltools

# Load the .mlpackage file
#model_package = coremltools.models.MLModel(
#    '/Users/katelyn/Downloads/palmtree/weights/7/best.mlpackage')
model_package = coremltools.models.ML(
    '/Users/katelyn/Downloads/palmtree/weights/7/best.pt')

# Save the model as a .mlmodel file
model_package.save('/tmp/model.mlmodel')