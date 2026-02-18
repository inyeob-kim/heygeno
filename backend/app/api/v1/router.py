from fastapi import APIRouter

from app.api.v1 import users, pets, products, trackings, alerts, clicks, onboarding, admin, user_reco_prefs, missions, points, campaigns

api_router = APIRouter()

api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(pets.router, prefix="/pets", tags=["pets"])
api_router.include_router(products.router, prefix="/products", tags=["products"])
api_router.include_router(trackings.router, prefix="/trackings", tags=["trackings"])
api_router.include_router(alerts.router, prefix="/alerts", tags=["alerts"])
api_router.include_router(clicks.router, prefix="/clicks", tags=["clicks"])
api_router.include_router(onboarding.router, prefix="/onboarding", tags=["onboarding"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(user_reco_prefs.router, prefix="/user-reco-prefs", tags=["user-reco-prefs"])
api_router.include_router(missions.router, prefix="/missions", tags=["missions"])
api_router.include_router(points.router, prefix="/points", tags=["points"])
api_router.include_router(campaigns.router, prefix="/campaigns", tags=["campaigns"])

