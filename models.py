from django.db import models

# Create your models here.
class Feedback(models.Model):
    image = models.ImageField(upload_to='images/')
    user_feedback = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"feedback from {self.created_at}"
    
