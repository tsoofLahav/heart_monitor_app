"""HTTP routes for experiment participant / trial / assessment / session APIs."""

from __future__ import annotations

import logging
from datetime import datetime

from flask import Blueprint, jsonify, request

from db import is_db_configured
from experiment_service import (
    bootstrap_participant,
    get_progress,
    save_assessment,
    save_session,
    update_participant_profile,
)

logger = logging.getLogger(__name__)

experiment_bp = Blueprint("experiment", __name__)


def _parse_iso_datetime(value):
    if value is None or value == "":
        return None
    if isinstance(value, datetime):
        return value
    text = str(value).strip().replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(text)
        return dt.replace(tzinfo=None) if dt.tzinfo else dt
    except ValueError as exc:
        raise ValueError(f"invalid datetime: {value}") from exc


def _client_install_id_from_request() -> str:
    data = request.get_json(silent=True) or {}
    return (
        data.get("client_install_id")
        or request.args.get("client_install_id")
        or request.headers.get("X-Client-Install-Id")
        or ""
    ).strip()


def _db_unavailable():
    return jsonify({"error": "database_not_configured"}), 503


@experiment_bp.route("/bootstrap", methods=["POST"])
def bootstrap():
    if not is_db_configured():
        return _db_unavailable()
    try:
        client_id = _client_install_id_from_request()
        progress = bootstrap_participant(client_id)
        return jsonify(progress), 200
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    except Exception:
        logger.exception("bootstrap failed")
        return jsonify({"error": "bootstrap_failed"}), 500


@experiment_bp.route("/progress", methods=["GET"])
def progress():
    if not is_db_configured():
        return _db_unavailable()
    try:
        client_id = _client_install_id_from_request()
        result = get_progress(client_id)
        if result is None:
            return jsonify({"error": "not_found"}), 404
        return jsonify(result), 200
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    except Exception:
        logger.exception("progress failed")
        return jsonify({"error": "progress_failed"}), 500


@experiment_bp.route("/assessments", methods=["POST"])
def assessments():
    if not is_db_configured():
        return _db_unavailable()
    data = request.get_json(silent=True) or {}
    try:
        client_id = _client_install_id_from_request()
        trial_id = int(data["trial_id"])
        phase = data.get("phase")
        heartbeat = data.get("heartbeat_score")
        questionnaire = data.get("questionnaire_score")
        progress = save_assessment(
            client_install_id=client_id,
            trial_id=trial_id,
            phase=phase,
            heartbeat_score=float(heartbeat) if heartbeat is not None else None,
            questionnaire_score=float(questionnaire) if questionnaire is not None else None,
        )
        return jsonify(progress), 200
    except KeyError:
        return jsonify({"error": "trial_id and phase are required"}), 400
    except (ValueError, TypeError) as exc:
        return jsonify({"error": str(exc)}), 400
    except LookupError as exc:
        return jsonify({"error": str(exc)}), 404
    except Exception:
        logger.exception("save assessment failed")
        return jsonify({"error": "assessment_failed"}), 500


@experiment_bp.route("/sessions", methods=["POST"])
def sessions():
    if not is_db_configured():
        return _db_unavailable()
    data = request.get_json(silent=True) or {}
    try:
        client_id = _client_install_id_from_request()
        trial_id = int(data["trial_id"])
        session_number = int(data["session_number"])
        score = data.get("score")
        progress = save_session(
            client_install_id=client_id,
            trial_id=trial_id,
            session_number=session_number,
            score=float(score) if score is not None else None,
            accuracy=float(data["accuracy"]) if data.get("accuracy") is not None else None,
            avg_heart_rate=(
                float(data["avg_heart_rate"])
                if data.get("avg_heart_rate") is not None
                else None
            ),
            duration_seconds=(
                float(data["duration_seconds"])
                if data.get("duration_seconds") is not None
                else None
            ),
            started_at=_parse_iso_datetime(data.get("started_at")),
            completed_at=_parse_iso_datetime(data.get("completed_at")),
        )
        return jsonify(progress), 200
    except KeyError:
        return jsonify({"error": "trial_id and session_number are required"}), 400
    except (ValueError, TypeError) as exc:
        return jsonify({"error": str(exc)}), 400
    except LookupError as exc:
        return jsonify({"error": str(exc)}), 404
    except Exception:
        logger.exception("save session failed")
        return jsonify({"error": "session_failed"}), 500


@experiment_bp.route("/participants/me", methods=["PATCH"])
def patch_participant():
    if not is_db_configured():
        return _db_unavailable()
    data = request.get_json(silent=True) or {}
    try:
        client_id = _client_install_id_from_request()
        age = data.get("age")
        progress = update_participant_profile(
            client_id,
            name=data.get("name"),
            age=int(age) if age is not None else None,
        )
        return jsonify(progress), 200
    except (ValueError, TypeError) as exc:
        return jsonify({"error": str(exc)}), 400
    except LookupError as exc:
        return jsonify({"error": str(exc)}), 404
    except Exception:
        logger.exception("patch participant failed")
        return jsonify({"error": "participant_update_failed"}), 500
