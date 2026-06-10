"""Quiz listeleme/goruntuleme/silme/disa-aktarma (uretim documents router'inda)."""
import urllib.parse

from fastapi import APIRouter, Depends, HTTPException, Query, Response

from app import exporters
from app.db import get_db
from app.deps import AuthUser, get_current_user
from app.helpers import get_owned_row
from app.schemas import QuizUpdateReq

router = APIRouter(prefix="/quizzes", tags=["quizzes"])


@router.get("")
def list_quizzes(user: AuthUser = Depends(get_current_user)):
    res = (
        get_db()
        .table("quizzes")
        .select("*, quiz_questions(count)")
        .eq("user_id", user.id)
        .order("created_at", desc=True)
        .execute()
    )
    quizzes = []
    for q in res.data:
        counts = q.pop("quiz_questions", [])
        q["question_count"] = counts[0]["count"] if counts else 0
        quizzes.append(q)
    return {"quizzes": quizzes}


@router.get("/{quiz_id}")
def get_quiz(quiz_id: str, user: AuthUser = Depends(get_current_user)):
    """Quiz + sorulari (istemci 'generating' durumunu burada poll'lar)."""
    quiz = get_owned_row("quizzes", quiz_id, user.id)
    questions = (
        get_db()
        .table("quiz_questions")
        .select("*")
        .eq("quiz_id", quiz_id)
        .order("position")
        .execute()
        .data
    )
    quiz["questions"] = questions
    return quiz


@router.get("/{quiz_id}/export")
def export_quiz(
    quiz_id: str,
    format: str = Query("json", description="json|csv|txt|pdf"),
    user: AuthUser = Depends(get_current_user),
):
    fmt = format.lower()
    if fmt not in exporters.QUIZ_FORMATS:
        raise HTTPException(400, f"Desteklenmeyen format: {format}")
    quiz = get_owned_row("quizzes", quiz_id, user.id)
    questions = (
        get_db()
        .table("quiz_questions")
        .select("*")
        .eq("quiz_id", quiz_id)
        .order("position")
        .execute()
        .data
    )
    if not questions:
        raise HTTPException(404, "Bu quizde soru yok.")
    fn = exporters.QUIZ_FORMATS[fmt]
    if fmt == "pdf":
        data, mime, ext = fn(questions, quiz.get("title") or "MedVisual Quiz")
    else:
        data, mime, ext = fn(questions)
    safe = urllib.parse.quote((quiz.get("title") or "quiz")[:60])
    return Response(
        content=data,
        media_type=mime,
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{safe}.{ext}"},
    )


@router.patch("/{quiz_id}")
def rename_quiz(
    quiz_id: str, req: QuizUpdateReq, user: AuthUser = Depends(get_current_user)
):
    """Quiz basligini gunceller (yeniden adlandirma)."""
    get_owned_row("quizzes", quiz_id, user.id)
    return (
        get_db()
        .table("quizzes")
        .update({"title": req.title})
        .eq("id", quiz_id)
        .execute()
        .data[0]
    )


@router.delete("/{quiz_id}", status_code=204)
def delete_quiz(quiz_id: str, user: AuthUser = Depends(get_current_user)):
    get_owned_row("quizzes", quiz_id, user.id)
    get_db().table("quizzes").delete().eq("id", quiz_id).execute()
