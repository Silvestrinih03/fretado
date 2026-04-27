from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.models.driver_license_category import DriverLicenseCategory
from app.schemas.driver_license_category import DriverLicenseCategoryResponse

router = APIRouter(
    prefix="/driver-license-categories",
    tags=["Driver License Categories"],
)

@router.get("", response_model=List[DriverLicenseCategoryResponse], status_code=status.HTTP_200_OK)
def list_driver_license_categories(db: Session = Depends(get_db)):
    return db.query(DriverLicenseCategory).order_by(DriverLicenseCategory.id.asc()).all()

@router.get("/{category_id}", response_model=DriverLicenseCategoryResponse, status_code=status.HTTP_200_OK)
def get_driver_license_category_by_id(category_id: int, db: Session = Depends(get_db)):
    category = (
        db.query(DriverLicenseCategory)
        .filter(DriverLicenseCategory.id == category_id)
        .first()
    )

    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver license category not found.",
        )

    return category
