"""Experiment domain services: participants, trials, assessments, sessions."""

from __future__ import annotations

import logging
import random
from datetime import datetime, timezone
from typing import Any

from db import get_connection, row_to_dict

logger = logging.getLogger(__name__)

STATUSES = {
    "not_started",
    "pre_assessment",
    "training",
    "post_assessment",
    "completed",
}


def _utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _next_participant_code(cursor) -> str:
    cursor.execute(
        """
        SELECT TOP 1 ParticipantCode
        FROM Participants
        ORDER BY Id DESC
        """
    )
    row = cursor.fetchone()
    if not row or not row[0]:
        return "P001"
    raw = str(row[0]).strip().upper()
    digits = "".join(ch for ch in raw if ch.isdigit())
    n = int(digits) + 1 if digits else 1
    return f"P{n:03d}"


def _compute_trail_step(
    has_pre: bool,
    has_post: bool,
    completed_sessions: list[int],
) -> int:
    if not has_pre:
        return 1
    for session_number in range(1, 9):
        if session_number not in completed_sessions:
            # trail steps 2..9 map to sessions 1..8
            return session_number + 1
    if not has_post:
        return 10
    return 10  # completed; client uses status


def _training_mode_from_condition(condition: str | None) -> str:
    """Neutral client field: never expose real/control wording."""
    if (condition or "").strip().lower() == "control":
        return "audio"
    return "ppg"


def _progress_payload(
    *,
    participant_code: str,
    trial_id: int,
    status: str,
    current_session: int,
    has_pre: bool,
    has_post: bool,
    completed_sessions: list[int],
    condition: str | None = None,
) -> dict[str, Any]:
    trail_step = _compute_trail_step(has_pre, has_post, completed_sessions)
    return {
        "participant_code": participant_code,
        "trial_id": trial_id,
        "status": status,
        "current_session": current_session,
        "trail_step": trail_step,
        "completed_session_numbers": sorted(completed_sessions),
        "has_pre_assessment": has_pre,
        "has_post_assessment": has_post,
        "training_mode": _training_mode_from_condition(condition),
        # Condition intentionally omitted
    }


def _load_progress(cursor, participant_id: int) -> dict[str, Any] | None:
    cursor.execute(
        """
        SELECT Id, ParticipantCode, Condition
        FROM Participants
        WHERE Id = ?
        """,
        participant_id,
    )
    participant = row_to_dict(cursor, cursor.fetchone())
    if not participant:
        return None

    cursor.execute(
        """
        SELECT TOP 1 Id, Status, CurrentSession
        FROM Trials
        WHERE ParticipantId = ?
        ORDER BY Id DESC
        """,
        participant_id,
    )
    trial = row_to_dict(cursor, cursor.fetchone())
    if not trial:
        return None

    trial_id = int(trial["Id"])
    cursor.execute(
        """
        SELECT Phase FROM Assessments WHERE TrialId = ?
        """,
        trial_id,
    )
    phases = {str(r[0]).lower() for r in cursor.fetchall()}

    cursor.execute(
        """
        SELECT SessionNumber FROM Sessions WHERE TrialId = ?
        """,
        trial_id,
    )
    completed = [int(r[0]) for r in cursor.fetchall()]

    return _progress_payload(
        participant_code=str(participant["ParticipantCode"]),
        trial_id=trial_id,
        status=str(trial["Status"]),
        current_session=int(trial["CurrentSession"] or 0),
        has_pre="pre" in phases,
        has_post="post" in phases,
        completed_sessions=completed,
        condition=str(participant.get("Condition") or ""),
    )


def bootstrap_participant(client_install_id: str) -> dict[str, Any]:
    client_install_id = (client_install_id or "").strip()
    if not client_install_id:
        raise ValueError("client_install_id is required")

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT Id FROM Participants WHERE ClientInstallId = ?
            """,
            client_install_id,
        )
        existing = cursor.fetchone()
        if existing:
            progress = _load_progress(cursor, int(existing[0]))
            if progress:
                return progress
            # Participant exists but no trial — create one
            participant_id = int(existing[0])
        else:
            code = _next_participant_code(cursor)
            condition = random.choice(["real", "control"])
            cursor.execute(
                """
                INSERT INTO Participants (ClientInstallId, ParticipantCode, Condition)
                OUTPUT INSERTED.Id
                VALUES (?, ?, ?)
                """,
                client_install_id,
                code,
                condition,
            )
            participant_id = int(cursor.fetchone()[0])

        cursor.execute(
            """
            INSERT INTO Trials (ParticipantId, Status, CurrentSession, StartedAt)
            OUTPUT INSERTED.Id
            VALUES (?, ?, 0, ?)
            """,
            participant_id,
            "pre_assessment",
            _utcnow(),
        )
        trial_id = int(cursor.fetchone()[0])
        cursor.execute(
            "SELECT ParticipantCode, Condition FROM Participants WHERE Id = ?",
            participant_id,
        )
        row = cursor.fetchone()
        code = str(row[0])
        condition = str(row[1] or "")
        return _progress_payload(
            participant_code=code,
            trial_id=trial_id,
            status="pre_assessment",
            current_session=0,
            has_pre=False,
            has_post=False,
            completed_sessions=[],
            condition=condition,
        )


def get_progress(client_install_id: str) -> dict[str, Any] | None:
    client_install_id = (client_install_id or "").strip()
    if not client_install_id:
        raise ValueError("client_install_id is required")

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT Id FROM Participants WHERE ClientInstallId = ?",
            client_install_id,
        )
        row = cursor.fetchone()
        if not row:
            return None
        return _load_progress(cursor, int(row[0]))


def update_participant_profile(
    client_install_id: str,
    *,
    name: str | None = None,
    age: int | None = None,
) -> dict[str, Any]:
    client_install_id = (client_install_id or "").strip()
    if not client_install_id:
        raise ValueError("client_install_id is required")

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT Id FROM Participants WHERE ClientInstallId = ?",
            client_install_id,
        )
        row = cursor.fetchone()
        if not row:
            raise LookupError("participant not found")
        participant_id = int(row[0])

        if name is not None:
            cursor.execute(
                "UPDATE Participants SET Name = ? WHERE Id = ?",
                name.strip() or None,
                participant_id,
            )
        if age is not None:
            cursor.execute(
                "UPDATE Participants SET Age = ? WHERE Id = ?",
                age,
                participant_id,
            )
        progress = _load_progress(cursor, participant_id)
        if not progress:
            raise LookupError("trial not found")
        return progress


def save_assessment(
    *,
    client_install_id: str,
    trial_id: int,
    phase: str,
    heartbeat_score: float | None,
    questionnaire_score: float | None,
) -> dict[str, Any]:
    phase = (phase or "").strip().lower()
    if phase not in {"pre", "post"}:
        raise ValueError("phase must be 'pre' or 'post'")

    with get_connection() as conn:
        cursor = conn.cursor()
        participant_id = _assert_trial_owned(cursor, client_install_id, trial_id)

        cursor.execute(
            """
            MERGE Assessments AS target
            USING (SELECT ? AS TrialId, ? AS Phase) AS source
            ON target.TrialId = source.TrialId AND target.Phase = source.Phase
            WHEN MATCHED THEN
                UPDATE SET HeartbeatScore = ?, QuestionnaireScore = ?
            WHEN NOT MATCHED THEN
                INSERT (TrialId, Phase, HeartbeatScore, QuestionnaireScore)
                VALUES (?, ?, ?, ?);
            """,
            trial_id,
            phase,
            heartbeat_score,
            questionnaire_score,
            trial_id,
            phase,
            heartbeat_score,
            questionnaire_score,
        )

        if phase == "pre":
            cursor.execute(
                """
                UPDATE Trials
                SET Status = N'training'
                WHERE Id = ? AND Status IN (N'not_started', N'pre_assessment')
                """,
                trial_id,
            )
        else:
            cursor.execute(
                """
                UPDATE Trials
                SET Status = N'completed', CompletedAt = ?
                WHERE Id = ?
                """,
                _utcnow(),
                trial_id,
            )

        progress = _load_progress(cursor, participant_id)
        if not progress:
            raise LookupError("trial not found")
        return progress


def save_session(
    *,
    client_install_id: str,
    trial_id: int,
    session_number: int,
    score: float | None,
    accuracy: float | None = None,
    avg_heart_rate: float | None = None,
    duration_seconds: float | None = None,
    started_at: datetime | None = None,
    completed_at: datetime | None = None,
) -> dict[str, Any]:
    if session_number < 1 or session_number > 8:
        raise ValueError("session_number must be 1..8")

    completed_at = completed_at or _utcnow()

    with get_connection() as conn:
        cursor = conn.cursor()
        participant_id = _assert_trial_owned(cursor, client_install_id, trial_id)

        cursor.execute(
            """
            MERGE Sessions AS target
            USING (SELECT ? AS TrialId, ? AS SessionNumber) AS source
            ON target.TrialId = source.TrialId AND target.SessionNumber = source.SessionNumber
            WHEN MATCHED THEN
                UPDATE SET
                    Score = ?, Accuracy = ?, AvgHeartRate = ?, DurationSeconds = ?,
                    StartedAt = COALESCE(?, StartedAt), CompletedAt = ?
            WHEN NOT MATCHED THEN
                INSERT (
                    TrialId, SessionNumber, Score, Accuracy, AvgHeartRate,
                    DurationSeconds, StartedAt, CompletedAt
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """,
            trial_id,
            session_number,
            score,
            accuracy,
            avg_heart_rate,
            duration_seconds,
            started_at,
            completed_at,
            trial_id,
            session_number,
            score,
            accuracy,
            avg_heart_rate,
            duration_seconds,
            started_at,
            completed_at,
        )

        next_status = "post_assessment" if session_number >= 8 else "training"
        cursor.execute(
            """
            UPDATE Trials
            SET CurrentSession = CASE
                    WHEN ? > CurrentSession THEN ?
                    ELSE CurrentSession
                END,
                Status = CASE
                    WHEN Status = N'completed' THEN Status
                    ELSE ?
                END
            WHERE Id = ?
            """,
            session_number,
            session_number,
            next_status,
            trial_id,
        )

        progress = _load_progress(cursor, participant_id)
        if not progress:
            raise LookupError("trial not found")
        return progress


def _assert_trial_owned(cursor, client_install_id: str, trial_id: int) -> int:
    client_install_id = (client_install_id or "").strip()
    if not client_install_id:
        raise ValueError("client_install_id is required")

    cursor.execute(
        """
        SELECT p.Id
        FROM Participants p
        INNER JOIN Trials t ON t.ParticipantId = p.Id
        WHERE p.ClientInstallId = ? AND t.Id = ?
        """,
        client_install_id,
        trial_id,
    )
    row = cursor.fetchone()
    if not row:
        raise LookupError("trial not found for this participant")
    return int(row[0])
