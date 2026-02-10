# 모든 모델을 import하여 Alembic이 인식할 수 있도록 함
from app.models.user import User
from app.models.pet import (
    Pet, PetSpecies, PetSex, AgeInputMode, AgeStage,
    HealthConcernCode, PetHealthConcern,
    AllergenCode, PetFoodAllergy, PetOtherAllergy
)
from app.models.pet_current_food import (
    PetCurrentFood, FeedType, DailyAmountLevel, TreatsLevel
)
from app.models.product import (
    Product,
    ProductIngredientProfile,
    ProductNutritionFacts,
    ProductAllergen,
    ClaimCode,
    ProductClaim
)
from app.models.offer import ProductOffer, Merchant
from app.models.price import PriceSnapshot, PriceSummary
from app.models.tracking import Tracking, TrackingStatus
from app.models.alert import Alert, AlertEvent, AlertRuleType, AlertEventStatus
from app.models.outbound_click import OutboundClick, ClickSource
from app.models.recommendation import RecommendationRun, RecommendationItem, RecStrategy
from app.models.campaign import (
    Campaign, CampaignRule, CampaignAction, 
    UserCampaignImpression, UserCampaignReward,
    CampaignKind, CampaignPlacement, CampaignTemplate,
    CampaignTrigger, CampaignActionType, RewardStatus
)
from app.models.point import PointWallet, PointLedger
from app.models.referral import ReferralCode, Referral, ReferralStatus

__all__ = [
    "User",
    "Pet", "PetSpecies", "PetSex", "AgeInputMode", "AgeStage",
    "HealthConcernCode", "PetHealthConcern",
    "AllergenCode", "PetFoodAllergy", "PetOtherAllergy",
    "PetCurrentFood", "FeedType", "DailyAmountLevel", "TreatsLevel",
    "Product",
    "ProductIngredientProfile",
    "ProductNutritionFacts",
    "ProductAllergen",
    "ClaimCode",
    "ProductClaim",
    "ProductOffer", "Merchant",
    "PriceSnapshot",
    "PriceSummary",
    "Tracking", "TrackingStatus",
    "Alert",
    "AlertEvent", "AlertRuleType", "AlertEventStatus",
    "OutboundClick", "ClickSource",
    "RecommendationRun", "RecommendationItem", "RecStrategy",
    "Campaign", "CampaignRule", "CampaignAction",
    "UserCampaignImpression", "UserCampaignReward",
    "CampaignKind", "CampaignPlacement", "CampaignTemplate",
    "CampaignTrigger", "CampaignActionType", "RewardStatus",
    "PointWallet", "PointLedger",
    "ReferralCode", "Referral", "ReferralStatus",
]
