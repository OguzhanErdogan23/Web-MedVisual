"""Quiz listeleme/goruntuleme/silme (uretim documents router'inda)."""
from fastapi import APIRouter, Depends

from app.db import get_db
from app.deps import AuthUser, get_current_user
from app.helpers import get_owned_row

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


@router.delete("/{quiz_id}", status_code=204)
def delete_quiz(quiz_id: str, user: AuthUser = Depends(get_current_user)):
    get_owned_row("quizzes", quiz_id, user.id)
    get_db().table("quizzes").delete().eq("id", quiz_id).execute()
