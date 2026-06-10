"""Pydantic istek modelleri."""
from typing import Optional

from pydantic import BaseModel, Field


class LoadBookReq(BaseModel):
    name: str


class GenerateCardsReq(BaseModel):
    range: str = Field(..., description="Sayfa araligi, orn. '25-50'")
    max_cards: int = Field(40, ge=1, le=120)
    enhance: bool = False
    source: str = "auto"  # auto | text | ocr
    set_title: Optional[str] = None


class GenerateQuizReq(BaseModel):
    range: str
    n_questions: int = Field(10, ge=1, le=40)
    enhance: bool = False
    source: str = "auto"
    title: Optional[str] = None


class SetCreateReq(BaseModel):
    title: str
    description: Optional[str] = None


class SetUpdateReq(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None


class CardCreateReq(BaseModel):
    front: str
    back: str
    term: Optional[str] = None
    kind: Optional[str] = "manual"
    page: Optional[int] = None


class CardUpdateReq(BaseModel):
    front: Optional[str] = None
    back: Optional[str] = None
    term: Optional[str] = None
    image_url: Optional[str] = None
    position: Optional[int] = None


class MatchReq(BaseModel):
    range: str
    document_id: Optional[str] = None  # set dokumana bagli degilse zorunlu
    term: Optional[str] = None
    source: str = "auto"


class SelectImageReq(BaseModel):
    dip_doc_id: str
    path: str  # work/{dip_doc_id}/ altindaki goreli yol, orn. candidates/femur_0.png


class ReviewReq(BaseModel):
    card_id: str
    grade: int = Field(..., ge=0, le=3, description="0=again 1=hard 2=good 3=easy")


class ImportReq(BaseModel):
    set_title: Optional[str] = None


class AutoImagesReq(BaseModel):
    range: Optional[str] = None
    document_id: Optional[str] = None


class QuizUpdateReq(BaseModel):
    title: str
