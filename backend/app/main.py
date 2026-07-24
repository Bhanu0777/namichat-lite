import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.exceptions import AppError
from app.routers import register_routers

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("namichat")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="NamiChat Lite — lightweight realtime chat API.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=False,   # Bearer-token auth; no cookies. False is required with wildcard origins.
    allow_methods=["*"],
    allow_headers=["*"],
)

register_routers(app)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.message})


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled error processing %s", request.url.path)
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})
