from filter_and_peaks import validate_signal_quality, BEAT_CORRELATION_THRESHOLD


def is_good_quality(signal, fs=24):
    """Legacy wrapper; returns True when morphology QA passes."""
    ok, _reason = validate_signal_quality(signal, fs)
    return ok


__all__ = ['is_good_quality', 'BEAT_CORRELATION_THRESHOLD', 'validate_signal_quality']
