from fastapi import FastAPI
from app.api.routes.register import router as register_router
from app.api.routes.auth import router as auth_router
from app.api.routes.user import router as user_router
from app.api.routes.vehicle import router as vehicle_router
from app.api.routes.vehicle_catalog import router as vehicle_catalog_router
from app.api.routes.vehicle_type import router as vehicle_type_router
from app.api.routes.driver_license_category import router as driver_license_category_router
from app.api.routes.driver_document import router as driver_document_router
from app.api.routes.ride import router as ride_router
from app.api.routes.user_cards import router as user_cards_router
from app.api.routes.ride_offer import router as ride_offer_router
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
import webbrowser
from fastapi import FastAPI

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
app.include_router(ride_router)
app.include_router(ride_offer_router)
app.include_router(user_cards_router)
@app.on_event("startup")
async def startup():
    webbrowser.open("http://127.0.0.1:8000/docs")
