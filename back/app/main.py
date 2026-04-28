from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes.register import router as register_router
from app.api.routes.auth import router as auth_router
from app.api.routes.user import router as user_router
from app.api.routes.vehicle import router as vehicle_router
from app.api.routes.vehicle_catalog import router as vehicle_catalog_router
from app.api.routes.vehicle_type import router as vehicle_type_router
from app.api.routes.driver_license_category import router as driver_license_category_router
from app.api.routes.driver_document import router as driver_document_router
from app.core.config import settings

app = FastAPI(title=settings.APP_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ALLOW_ORIGINS,
    allow_origin_regex=settings.CORS_ALLOW_ORIGIN_REGEX,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(register_router)
app.include_router(auth_router)
app.include_router(user_router)
app.include_router(vehicle_router)
app.include_router(vehicle_catalog_router)
app.include_router(vehicle_type_router)
app.include_router(driver_license_category_router)
app.include_router(driver_document_router)

@app.get("/")
def root():
    return {"message": "Fretado API is running"}
