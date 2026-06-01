
round_duration = 10  # legacy default; sessions use session_duration from video
testing_mode = False

round_count = 0
round_peaks = []
last_sec = None
ave_gap = 0.7
round_signal = []
session_duration = 0.0
session_fps = 0.0
video_width = 0
video_height = 0


def reset_all():
    global round_count, round_peaks, last_sec, round_signal, session_duration
    global session_fps, video_width, video_height
    round_count = 0
    round_peaks = []
    last_sec = None
    round_signal = []
    session_duration = 0.0
    session_fps = 0.0
    video_width = 0
    video_height = 0


def add_to_round_peaks(peaks):
    global round_peaks
    round_peaks.extend(peaks)


def add_to_round_signal(signal):
    global round_signal
    round_signal.extend([x for x in signal])
