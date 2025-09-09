import tensorflow as tf
import tensorflow_hub as hub
import os

# Create assets directory if it doesn't exist
os.makedirs('assets', exist_ok=True)

# Download and convert MoveNet Lightning
print("Downloading MoveNet Lightning from TensorFlow Hub...")
model_handle = 'https://tfhub.dev/google/movenet/singlepose/lightning/4'

try:
    # Load the model from TF Hub
    model = hub.load(model_handle)
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_concrete_functions(
        [model.signatures['serving_default']])
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save the model
    with open('assets/movenet.tflite', 'wb') as f:
        f.write(tflite_model)
    
    print("Success! movenet.tflite has been saved to your assets folder")
    print("File size:", len(tflite_model), "bytes")
    
except Exception as e:
    print("Error occurred:", str(e))
    print("\nTrying alternative method...")
    
    # Alternative approach
    try:
        # Alternative way to get the model
        interpreter = tf.lite.Interpreter(model_path=hub.load(model_handle))
        with open('assets/movenet.tflite', 'wb') as f:
            f.write(interpreter.get_model_content())
        print("Success with alternative method!")
    except Exception as e2:
        print("Also failed with alternative method:", str(e2))