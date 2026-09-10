import math

from datetime import datetime, timedelta, timezone

from filter_and_peaks import SIGNAL_START_OFFSET_SEC, peak_detection_window


def parse_recording_started_at(value):
    """Parse ISO-8601 UTC timestamp from the client, or None."""
    if not value or not str(value).strip():
        return None
    text = str(value).strip().replace('Z', '+00:00')
    dt = datetime.fromisoformat(text)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def build_peak_window_metadata(duration_sec, recording_started_at=None,
                               counting_start_sec=None, counting_end_sec=None):
    """
    Use client cue boundaries when supplied; otherwise use the legacy window.
    Returns seconds relative to video start and optional UTC bounds.
    """
    if counting_start_sec is None and counting_end_sec is None:
        start_sec, end_sec = peak_detection_window(duration_sec)
    else:
        try:
            start_sec = float(counting_start_sec)
            end_sec = float(counting_end_sec)
        except (TypeError, ValueError) as exc:
            raise ValueError('Both counting cue offsets must be numeric') from exc
        if not (math.isfinite(start_sec) and math.isfinite(end_sec)
                and SIGNAL_START_OFFSET_SEC <= start_sec < end_sec <= float(duration_sec)):
            raise ValueError('Counting cue interval is outside the usable video')
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
