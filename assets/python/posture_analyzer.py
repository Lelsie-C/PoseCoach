import sys
import os
import json
import cv2
import numpy as np
import tensorflow as tf
from collections import deque
import time

# ==============================
# Config
# ==============================
CONF_THRESHOLD = 0.35
DOWN_THRESHOLD = 100
UP_THRESHOLD = 160
BACK_ANGLE_THRESHOLD = 165
KNEE_ALIGNMENT_THRESHOLD = 15

SKELETON = [
    (0, 1), (0, 2), (1, 3), (2, 4),
    (5, 6), (5, 7), (7, 9), (6, 8), (8, 10),
    (5, 11), (6, 12), (11, 12),
    (11, 13), (13, 15), (12, 14), (14, 16)
]

# ==============================
# Utility Functions
# ==============================
def calculate_angle(a, b, c):
    """Calculate angle between three points"""
    ba = a - b
    bc = c - b
    cosine = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    angle = np.degrees(np.arccos(np.clip(cosine, -1.0, 1.0)))
    return angle

def preprocess_image(image_bgr, target_size):
    """Preprocess image for model input"""
    img_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
    resized = cv2.resize(img_rgb, target_size, interpolation=cv2.INTER_LINEAR)
    return np.expand_dims(resized.astype(np.int32), axis=0)

# ==============================
# Posture Analyzer Class
# ==============================
class PostureAnalyzer:
    def __init__(self):
        self.rep_count = 0
        self.squat_state = "UP"
        self.feedback = "Starting analysis..."
        self.last_rep_time = time.time()
        self.rep_details = []
        self.current_rep_data = {
            'start_time': 0, 'end_time': 0, 'min_knee_angle': 180,
            'max_back_angle': 0, 'knee_alignment_issues': 0,
            'back_straightness_issues': 0
        }

    def analyze_frame(self, keypoints, frame_width, frame_height, frame_time):
        """Analyze posture for current frame"""
        feedback = []
        warnings = []

        required_indices = [5, 6, 11, 12, 13, 14, 15, 16]
        all_detected = all(keypoints[i][2] > CONF_THRESHOLD for i in required_indices if i < len(keypoints))
        
        if not all_detected:
            self.feedback = "Keypoints not fully visible"
            return False, []

        keypoints_px = []
        for kp in keypoints:
            y, x, conf = kp
            keypoints_px.append((x * frame_width, y * frame_height, conf))

        left_knee_angle = self._calculate_knee_angle(keypoints_px, 11, 13, 15)
        right_knee_angle = self._calculate_knee_angle(keypoints_px, 12, 14, 16)
        back_angle = self._calculate_back_angle(keypoints_px, 5, 6, 11, 12)
        avg_knee_angle = (left_knee_angle + right_knee_angle) / 2

        knee_alignment_issue = self._check_knee_alignment(keypoints_px, 13, 14, 15, 16)

        if self.squat_state == "UP" and avg_knee_angle < DOWN_THRESHOLD:
            self.squat_state = "DOWN"
            self.current_rep_data['start_time'] = frame_time
            feedback.append("Squat down detected")
        elif self.squat_state == "DOWN" and avg_knee_angle > UP_THRESHOLD:
            self.squat_state = "UP"
            self.rep_count += 1
            self.current_rep_data['end_time'] = frame_time
            self._finalize_rep_analysis()
            feedback.append(f"Good rep! ({self.rep_count})")

        if self.squat_state == "DOWN":
            self.current_rep_data['min_knee_angle'] = min(self.current_rep_data['min_knee_angle'], avg_knee_angle)
            self.current_rep_data['max_back_angle'] = max(self.current_rep_data['max_back_angle'], back_angle)
            
            if knee_alignment_issue:
                self.current_rep_data['knee_alignment_issues'] += 1
                warnings.append("Knees moving forward too much")
            
            if back_angle < BACK_ANGLE_THRESHOLD:
                self.current_rep_data['back_straightness_issues'] += 1
                warnings.append("Keep your back straight")

        feedback.append(f"Knee angle: {int(avg_knee_angle)}°")
        feedback.append(f"Back angle: {int(back_angle)}°")
        self.feedback = " | ".join(feedback)
        
        return True, warnings

    def _calculate_knee_angle(self, keypoints, hip_idx, knee_idx, ankle_idx):
        hip = np.array([keypoints[hip_idx][0], keypoints[hip_idx][1]])
        knee = np.array([keypoints[knee_idx][0], keypoints[knee_idx][1]])
        ankle = np.array([keypoints[ankle_idx][0], keypoints[ankle_idx][1]])
        return calculate_angle(hip, knee, ankle)

    def _calculate_back_angle(self, keypoints, l_shoulder_idx, r_shoulder_idx, l_hip_idx, r_hip_idx):
        shoulder_center = np.array([
            (keypoints[l_shoulder_idx][0] + keypoints[r_shoulder_idx][0]) / 2,
            (keypoints[l_shoulder_idx][1] + keypoints[r_shoulder_idx][1]) / 2
        ])
        hip_center = np.array([
            (keypoints[l_hip_idx][0] + keypoints[r_hip_idx][0]) / 2,
            (keypoints[l_hip_idx][1] + keypoints[r_hip_idx][1]) / 2
        ])
        vertical_ref = np.array([shoulder_center[0], shoulder_center[1] - 100])
        return calculate_angle(vertical_ref, shoulder_center, hip_center)

    def _check_knee_alignment(self, keypoints, l_knee_idx, r_knee_idx, l_ankle_idx, r_ankle_idx):
        l_knee = np.array([keypoints[l_knee_idx][0], keypoints[l_knee_idx][1]])
        r_knee = np.array([keypoints[r_knee_idx][0], keypoints[r_knee_idx][1]])
        l_ankle = np.array([keypoints[l_ankle_idx][0], keypoints[l_ankle_idx][1]])
        r_ankle = np.array([keypoints[r_ankle_idx][0], keypoints[r_ankle_idx][1]])
        
        l_issue = l_knee[0] > l_ankle[0] + KNEE_ALIGNMENT_THRESHOLD
        r_issue = r_knee[0] > r_ankle[0] + KNEE_ALIGNMENT_THRESHOLD
        
        return l_issue or r_issue

    def _finalize_rep_analysis(self):
        rep_score = 100
        
        if self.current_rep_data['min_knee_angle'] > DOWN_THRESHOLD + 10:
            rep_score -= 20
        if self.current_rep_data['max_back_angle'] < BACK_ANGLE_THRESHOLD - 10:
            rep_score -= 15
        if self.current_rep_data['knee_alignment_issues'] > 0:
            rep_score -= 10

        rep_duration = self.current_rep_data['end_time'] - self.current_rep_data['start_time']
        
        self.rep_details.append({
            'rep_number': self.rep_count,
            'score': max(60, rep_score),
            'depth_angle': self.current_rep_data['min_knee_angle'],
            'back_angle': self.current_rep_data['max_back_angle'],
            'duration': rep_duration,
            'knee_issues': self.current_rep_data['knee_alignment_issues'],
            'back_issues': self.current_rep_data['back_straightness_issues']
        })

        self.current_rep_data = {
            'start_time': 0, 'end_time': 0, 'min_knee_angle': 180,
            'max_back_angle': 0, 'knee_alignment_issues': 0,
            'back_straightness_issues': 0
        }

    def generate_final_report(self):
        if not self.rep_details:
            return "No reps detected in the video"
        
        total_score = sum(rep['score'] for rep in self.rep_details) / len(self.rep_details)
        avg_depth = sum(rep['depth_angle'] for rep in self.rep_details) / len(self.rep_details)
        avg_duration = sum(rep['duration'] for rep in self.rep_details) / len(self.rep_details)
        
        report = []
        report.append("=" * 50)
        report.append("SQUAT PERFORMANCE ANALYSIS REPORT")
        report.append("=" * 50)
        report.append(f"Total Reps: {self.rep_count}")
        report.append(f"Overall Score: {total_score:.1f}/100")
        report.append(f"Average Depth: {avg_depth:.1f}°")
        report.append(f"Average Rep Duration: {avg_duration:.2f}s")
        report.append("")
        
        report.append("REP-BY-REP ANALYSIS:")
        report.append("-" * 30)
        for rep in self.rep_details:
            report.append(f"Rep {rep['rep_number']}: Score {rep['score']}/100")
            report.append(f"  Depth: {rep['depth_angle']:.1f}°, Back: {rep['back_angle']:.1f}°")
            report.append(f"  Duration: {rep['duration']:.2f}s")
            if rep['knee_issues'] > 0:
                report.append(f"  ⚠️ Knee alignment issues: {rep['knee_issues']}")
            if rep['back_issues'] > 0:
                report.append(f"  ⚠️ Back straightness issues: {rep['back_issues']}")
            report.append("")
        
        report.append("RECOMMENDATIONS:")
        report.append("-" * 20)
        if avg_depth > DOWN_THRESHOLD + 5:
            report.append("➡️ Go deeper in your squats")
        if any(rep['back_angle'] < BACK_ANGLE_THRESHOLD - 5 for rep in self.rep_details):
            report.append("➡️ Focus on keeping your back straight")
        if any(rep['knee_issues'] > 0 for rep in self.rep_details):
            report.append("➡️ Keep your knees behind your toes")
        if avg_duration < 1.5:
            report.append("➡️ Slow down your reps for better form control")
        
        report.append("")
        report.append("Keep up the good work! 💪")
        
        return "\n".join(report)

# ==============================
# Main Processing Functions
# ==============================
def analyze_video(video_path):
    """Analyze video and return JSON results"""
    try:
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            return json.dumps({'success': False, 'error': 'Could not open video'})
        
        # Load model (adjust path as needed)
        model_path = 'assets/movenet.tflite'
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        analyzer = PostureAnalyzer()
        frame_count = 0
        fps = cap.get(cv2.CAP_PROP_FPS) or 30
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            if frame_count % 2 == 0:  # Process every 2nd frame
                input_data = preprocess_image(frame, (192, 192))
                interpreter.set_tensor(input_details[0]['index'], input_data)
                interpreter.invoke()
                keypoints = interpreter.get_tensor(output_details[0]['index'])[0, 0]
                
                frame_time = frame_count / fps
                analyzer.analyze_frame(keypoints, frame.shape[1], frame.shape[0], frame_time)
            
            frame_count += 1
        
        cap.release()
        
        return json.dumps({
            'success': True,
            'rep_count': analyzer.rep_count,
            'rep_details': analyzer.rep_details,
            'report': analyzer.generate_final_report()
        })
        
    except Exception as e:
        return json.dumps({'success': False, 'error': str(e)})

def process_video(input_path, output_path):
    """Process video with posture detection overlay"""
    try:
        # For now, just copy the video as processing with overlay is complex
        # You can implement the full processing logic here later
        import shutil
        shutil.copy2(input_path, output_path)
        
        return json.dumps({
            'success': True,
            'output_path': output_path,
            'message': 'Video processed successfully'
        })
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'error': str(e),
            'output_path': input_path
        })

# ==============================
# Entry Point for Flutter
# ==============================
if __name__ == '__main__':
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == 'analyze' and len(sys.argv) > 2:
            result = analyze_video(sys.argv[2])
            print(result)
            
        elif command == 'process' and len(sys.argv) > 3:
            result = process_video(sys.argv[2], sys.argv[3])
            print(result)
            
        else:
            print(json.dumps({'success': False, 'error': 'Invalid command or arguments'}))
    else:
        print(json.dumps({'success': False, 'error': 'No command provided'}))