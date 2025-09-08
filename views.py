from django.shortcuts import render,redirect
from .forms import FeedbackForm 
from .models import Feedback 
import numpy as np
from PIL import Image 

def feedback_view(request):
    if request.method == 'POST':
        import tensorflow as tf
        form = FeedbackForm(request.POST, request.FILES)
        if form.is_valid():
            feedback_instance = form.save()

            try:
                image = Image.open(feedback_instance.image.path)
                image = image.convert('RGB')  
                image_array = np.array(image).astype(np.float32) / 255.0  
                input_image = tf.expand_dims(image_array, axis=0)
            except (FileNotFoundError, OSError) as e:
                form.add_error('image', 'Could not open the uploaded image file.')
                return render(request, 'feedback/feedback_form.html', {'form': form})

            # Load MoveNet model
            model = tf.saved_model.load('absolute/or/relative/path/to/your/movenet/model')
            movenet = model.signatures['serving_default']

            # Run inference
            keypoints_with_scores = movenet(input_image)

            # Process keypoints
            keypoints = keypoints_with_scores['output_0'].numpy()
            import logging
            logger = logging.getLogger(__name__)
            logger.debug(keypoints)
            print(keypoints)

            from django.contrib import messages
            messages.success(request, 'Feedback submitted successfully!')
            return redirect('feedback_success')

    else:
        form = FeedbackForm()

    return render(request, 'feedback/feedback_form.html', {'form': form})