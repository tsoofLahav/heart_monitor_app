import cv2
import numpy as np

import globals


def get_video_duration_seconds(input_path):
    """Returns actual playback duration in seconds from the video file."""
    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        raise Exception("Failed to open video file.")
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_count = cap.get(cv2.CAP_PROP_FRAME_COUNT)
    cap.release()
    if fps <= 0 or frame_count <= 0:
        raise Exception("Could not read video duration.")
    return frame_count / fps


def process_video_frames(input_path, target_fps=24, target_duration=None):
    """Reads a video, resamples to target_fps over target_duration seconds, returns FPS & intensities."""
    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        raise Exception("Failed to open video file.")

    if target_duration is None:
        target_duration = get_video_duration_seconds(input_path)

    target_duration = max(float(target_duration), 0.5)
    target_frames = max(int(target_fps * target_duration), 1)
    frames = []
    frame_width, frame_height = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

    center_x, center_y = frame_width // 2, frame_height // 2
    radius = min(center_x, center_y) // 2
    Y, X = np.ogrid[:frame_height, :frame_width]
    mask = (np.sqrt((X - center_x) ** 2 + (Y - center_y) ** 2) <= radius)

    intensities = []
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(frame)

    cap.release()
    if not frames:
        raise Exception("No frames found in video.")

    frame_indices = np.linspace(0, len(frames) - 1, target_frames).astype(int)
    resampled_frames = [frames[i] for i in frame_indices]

    for frame in resampled_frames:
        green_channel = frame[:, :, 2]
        roi_values = green_channel[mask]
        intensities.append(-np.mean(roi_values))

    return target_fps, intensities, target_duration
