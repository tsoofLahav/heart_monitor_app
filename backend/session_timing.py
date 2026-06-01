from datetime import datetime, timedelta, timezone

from filter_and_peaks import EDGE_GAP_SEC, peak_detection_window


def parse_recording_started_at(value):
    """Parse ISO-8601 UTC timestamp from the client, or None."""
    if not value or not str(value).strip():
        return None
    text = str(value).strip().replace('Z', '+00:00')
    dt = datetime.fromisoformat(text)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def build_peak_window_metadata(duration_sec, recording_started_at=None):
    """
    Peak search window: recording start + edge gap through duration - edge gap.
    Returns seconds relative to video start and optional UTC bounds.
    """
    start_sec, end_sec = peak_detection_window(duration_sec)
    meta = {
        'peak_window_start_sec': round(start_sec, 3),
        'peak_window_end_sec': round(end_sec, 3),
    }
    if recording_started_at is not None:
        start_utc = recording_started_at + timedelta(seconds=start_sec)
        end_utc = recording_started_at + timedelta(seconds=end_sec)
        meta['peak_window_start_utc'] = _format_utc(start_utc)
        meta['peak_window_end_utc'] = _format_utc(end_utc)
    return meta


def _format_utc(dt):
    return dt.astimezone(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
