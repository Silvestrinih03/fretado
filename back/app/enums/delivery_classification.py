from enum import Enum

class DeliveryClassificationEnum(str, Enum):
    IMMEDIATE_DELIVERY = "IMMEDIATE_DELIVERY"
    SCHEDULED_FREIGHT = "SCHEDULED_FREIGHT"
