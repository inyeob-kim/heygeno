# 모든 모델을 import하여 Alembic이 인식할 수 있도록 함
from app.models.user import User, AuthProvider, UserStatus, PlanType
from app.models.user_token import UserToken
from app.models.withdrawal_log import WithdrawalLog
from app.models.subscription_payment import (
    SubscriptionPayment,
    PaymentPlatform,
    SubscriptionPaymentStatus,
)
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
from app.models.product_review import ProductReview
from app.models.product_availability import ProductAvailability, StockStatus
from app.models.offer import ProductOffer, Merchant
from app.models.price import PriceSnapshot, PriceSummary
from app.models.tracking import Tracking, TrackingStatus
from app.models.alert import Alert, AlertEvent, AlertRuleType, AlertEventStatus
from app.models.outbound_click import OutboundClick, ClickSource
from app.models.recommendation import RecommendationRun, RecommendationItem, RecStrategy
from app.models.campaign import (
    Campaign, CampaignRule, CampaignAction, 
    UserCampaignImpression, UserCampaignReward, UserMissionProgress,
    CampaignKind, CampaignPlacement, CampaignTemplate,
    CampaignTrigger, CampaignActionType, RewardStatus, MissionProgressStatus
)
from app.models.point import PointWallet, PointLedger
from app.models.referral import ReferralCode, Referral, ReferralStatus
from app.models.user_reco_prefs import UserRecoPrefs
from app.models.ingredient_config import HarmfulIngredient, AllergenKeyword
from app.models.email_verification_token import EmailVerificationToken

__all__ = [
    "User",
    "AuthProvider",
    "UserStatus",
    "PlanType",
    "UserToken",
    "WithdrawalLog",
    "SubscriptionPayment",
    "PaymentPlatform",
    "SubscriptionPaymentStatus",
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
    "ProductReview",
    "ProductAvailability",
    "StockStatus",
    "ProductOffer", "Merchant",
    "PriceSnapshot",
    "PriceSummary",
    "Tracking", "TrackingStatus",
    "Alert",
    "AlertEvent", "AlertRuleType", "AlertEventStatus",
    "OutboundClick", "ClickSource",
    "RecommendationRun", "RecommendationItem", "RecStrategy",
    "Campaign", "CampaignRule", "CampaignAction",
    "UserCampaignImpression", "UserCampaignReward", "UserMissionProgress",
    "CampaignKind", "CampaignPlacement", "CampaignTemplate",
    "CampaignTrigger", "CampaignActionType", "RewardStatus", "MissionProgressStatus",
    "PointWallet", "PointLedger",
    "ReferralCode", "Referral", "ReferralStatus",
    "UserRecoPrefs",
    "HarmfulIngredient", "AllergenKeyword",
    "EmailVerificationToken",
]
