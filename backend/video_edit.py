import cv2
import numpy as np


def get_video_duration_seconds(input_path):
    """Returns actual playback duration in seconds from the video file."""
    meta = get_video_metadata(input_path)
    return meta["duration"]


def get_video_metadata(input_path):
    """Returns fps, duration, frame count, and resolution from the video file."""
    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        raise Exception("Failed to open video file.")
    fps = float(cap.get(cv2.CAP_PROP_FPS))
    frame_count = float(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    cap.release()
    if frame_count <= 0:
        raise Exception("Could not read video frame count.")
    if fps <= 0 or fps > 240:
        duration = 0.0
    else:
        duration = frame_count / fps
    return {
        "fps": fps,
        "duration": duration,
        "frame_count": int(frame_count),
        "width": width,
        "height": height,
    }


def _resolve_effective_fps(reported_fps, frame_count, duration_sec):
    """Sample rate for the intensity signal derived from the incoming video."""
    if duration_sec > 0 and frame_count > 1:
        return (frame_count - 1) / duration_sec
    if 0 < reported_fps <= 240:
        return reported_fps
    if duration_sec > 0:
        return frame_count / duration_sec
    return 30.0


def process_video_frames(input_path, target_duration=None):
    """Reads a video at native frame rate; returns fps, intensities, duration, width, height."""
    meta = get_video_metadata(input_path)
    reported_fps = meta["fps"]
    frame_width, frame_height = meta["width"], meta["height"]

    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        raise Exception("Failed to open video file.")

    if target_duration is None or target_duration <= 0:
        target_duration = meta["duration"]
    target_duration = max(float(target_duration), 0.5)

    center_x, center_y = frame_width // 2, frame_height // 2
    radius = min(center_x, center_y) // 2
    Y, X = np.ogrid[:frame_height, :frame_width]
    mask = (np.sqrt((X - center_x) ** 2 + (Y - center_y) ** 2) <= radius)

    frames = []
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(frame)
    cap.release()

    if not frames:
        raise Exception("No frames found in video.")

    effective_fps = _resolve_effective_fps(reported_fps, len(frames), target_duration)
    effective_fps = round(float(effective_fps), 2)

    intensities = []
    for frame in frames:
        green_channel = frame[:, :, 2]
        roi_values = green_channel[mask]
        intensities.append(-np.mean(roi_values))

    return effective_fps, intensities, target_duration, frame_width, frame_height
