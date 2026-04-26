from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.models.driver_document import DriverDocument
from app.models.driver_license_category import DriverLicenseCategory
from app.models.user import User
from app.schemas.driver_document import DriverDocumentRequest, DriverDocumentResponse
from app.schemas.driver_license_category import DriverLicenseCategoryResponse

router = APIRouter(prefix="/driver_documents", tags=["Driver Documents"])


@router.get("/categories", response_model=List[DriverLicenseCategoryResponse], status_code=status.HTTP_200_OK)
def get_categories(db: Session = Depends(get_db)):
    return db.query(DriverLicenseCategory).order_by(DriverLicenseCategory.id.asc()).all()


@router.get("/user/{user_id}", response_model=DriverDocumentResponse, status_code=status.HTTP_200_OK)
def get_driver_document(user_id: int, db: Session = Depends(get_db)):
    document = db.query(DriverDocument).filter(DriverDocument.user_id == user_id).first()

    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver document not found.",
        )

    return document


@router.post("/user/{user_id}", response_model=DriverDocumentResponse, status_code=status.HTTP_201_CREATED)
def create_driver_document(user_id: int, payload: DriverDocumentRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found.",
        )

    existing_document = db.query(DriverDocument).filter(DriverDocument.user_id == user_id).first()
    if existing_document:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User already has a driver document.",
        )

    existing_license = (
        db.query(DriverDocument)
        .filter(DriverDocument.license_number == payload.license_number)
        .first()
    )

    if existing_license:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="License number already registered.",
        )

    category = (
        db.query(DriverLicenseCategory)
        .filter(DriverLicenseCategory.id == payload.license_category_id)
        .first()
    )

    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="License category not found.",
        )

    document = DriverDocument(
        user_id=user_id,
        license_number=payload.license_number,
        license_category_id=payload.license_category_id,
        issue_date=payload.issue_date,
        expiration_date=payload.expiration_date,
    )

    try:
        db.add(document)
        db.commit()
        db.refresh(document)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not create driver document.",
        )

    return document


@router.put("/{document_id}", response_model=DriverDocumentResponse, status_code=status.HTTP_200_OK)
def update_driver_document(document_id: int, payload: DriverDocumentRequest, db: Session = Depends(get_db)):
    document = db.query(DriverDocument).filter(DriverDocument.id == document_id).first()

    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver document not found.",
        )

    category = (
        db.query(DriverLicenseCategory)
        .filter(DriverLicenseCategory.id == payload.license_category_id)
        .first()
    )

    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="License category not found.",
        )

    existing_license = (
        db.query(DriverDocument)
        .filter(
            DriverDocument.license_number == payload.license_number,
            DriverDocument.id != document_id,
        )
        .first()
    )

    if existing_license:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="License number already registered.",
        )

    document.license_number = payload.license_number
    document.license_category_id = payload.license_category_id
    document.issue_date = payload.issue_date
    document.expiration_date = payload.expiration_date

    try:
        db.commit()
        db.refresh(document)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not update driver document.",
        )

    return document
