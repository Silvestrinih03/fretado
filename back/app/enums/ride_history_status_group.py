from enum import Enum


class RideHistoryStatusGroup(str, Enum):
    ALL = "all"
    PENDING = "pending"
    COMPLETED = "completed"
    INTERRUPTED = "interrupted"
