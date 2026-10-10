from decimal import Decimal, ROUND_HALF_UP

from fastapi import HTTPException
from sqlalchemy import exists, func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.ride import Ride
from app.models.ride_cancellation import RideCancellation
from app.models.ride_offer import RideOffer
from app.models.ride_rating import RideRating
from app.models.user import User
from app.models.user_profile import UserProfile
from app.schemas.ride_rating import (
    PendingRideRatingSummary,
    PendingRideRatingsPage,
    ReceivedRideRatingSummary,
    ReceivedRideRatingsPage,
    RideRatingCreate,
    RideRatingStateResponse,
    UserRatingSummaryResponse,
)


DRIVER_CRITERIA = (
    ("punctuality", "Pontualidade"),
    ("cargo_care", "Cuidado com a encomenda"),
    ("communication", "Boa comunicacao"),
    ("courtesy", "Atendimento cordial"),
)
CLIENT_CRITERIA = (
    ("communication", "Boa comunicacao"),
    ("pickup_access", "Facilidade na coleta"),
    ("accurate_information", "Informacoes corretas"),
    ("punctuality", "Pontualidade"),
)
ACCEPTED = int(RideOfferStatusEnum.ACEITA)
FINISHED = int(RideStatusEnum.FINALIZADA)


def create_rating(
    db: Session,
    ride_id: int,
    reviewer: User,
    payload: RideRatingCreate,
) -> RideRating:
    ride = (
        db.query(Ride)
        .filter(Ride.id == ride_id)
        .with_for_update()
        .populate_existing()
        .first()
    )
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")

    reviewee_id, reviewee_role = _resolve_participants(ride, reviewer)
    if ride.status_id != FINISHED:
        raise HTTPException(
            status_code=409,
            detail="A avaliacao esta disponivel somente apos a corrida ser finalizada.",
        )

    offer = _final_offer(db, ride)
    if offer is None:
        raise HTTPException(
            status_code=409,
            detail="Nao foi possivel identificar a atribuicao final da corrida.",
        )

    duplicate = db.query(RideRating.id).filter(
        RideRating.ride_id == ride.id,
        RideRating.reviewer_user_id == reviewer.id,
    ).first()
    if duplicate is not None:
        raise HTTPException(status_code=409, detail="Esta corrida ja foi avaliada por voce.")

    allowed = {key for key, _ in _criteria_for_role(reviewee_role)}
    invalid = set(payload.criteria) - allowed
    if invalid:
        raise HTTPException(
            status_code=422,
            detail="Um ou mais criterios nao sao validos para este perfil.",
        )

    rating = RideRating(
        ride_id=ride.id,
        ride_offer_id=offer.id,
        reviewer_user_id=reviewer.id,
        reviewee_user_id=reviewee_id,
        score=payload.score,
        criteria=payload.criteria,
        comment=payload.comment,
    )
    try:
        db.add(rating)
        db.commit()
        db.refresh(rating)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Esta corrida ja foi avaliada por voce.")
    except Exception:
        db.rollback()
        raise
    return rating


def get_rating_state(
    db: Session,
    ride_id: int,
    reviewer: User,
) -> RideRatingStateResponse:
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    reviewee_id, reviewee_role = _resolve_participants(ride, reviewer)
    reviewee = _party(db, reviewee_id, reviewee_role)
    rating = db.query(RideRating).filter(
        RideRating.ride_id == ride.id,
        RideRating.reviewer_user_id == reviewer.id,
    ).first()

    reason = None
    eligible = ride.status_id == FINISHED and _final_offer(db, ride) is not None
    if ride.status_id != FINISHED:
        reason = "A corrida ainda nao foi finalizada."
    elif not eligible:
        reason = "A atribuicao final da corrida nao foi encontrada."
    elif rating is not None:
        eligible = False
        reason = "Avaliacao ja enviada."

    return RideRatingStateResponse(
        ride_id=ride.id,
        eligible=eligible,
        ineligible_reason=reason,
        reviewee=reviewee,
        allowed_criteria=_criterion_options(reviewee_role),
        rating=rating,
    )


def list_pending_ratings(
    db: Session,
    reviewer: User,
    limit: int,
    before_id: int | None,
) -> PendingRideRatingsPage:
    query = db.query(Ride).filter(Ride.status_id == FINISHED)
    if reviewer.user_type_id == int(UserTypeEnum.CLIENT):
        query = query.filter(
            Ride.client_user_id == reviewer.id,
            Ride.driver_user_id.is_not(None),
        )
    elif reviewer.user_type_id == int(UserTypeEnum.DRIVER):
        query = query.filter(Ride.driver_user_id == reviewer.id)
    else:
        raise HTTPException(status_code=403, detail="Perfil sem acesso a avaliacoes.")

    query = query.filter(
        exists().where(
            (RideOffer.ride_id == Ride.id)
            & (RideOffer.driver_user_id == Ride.driver_user_id)
            & (RideOffer.status_id == ACCEPTED)
        ),
        ~exists().where(
            (RideRating.ride_id == Ride.id)
            & (RideRating.reviewer_user_id == reviewer.id)
        ),
    )
    if before_id is not None:
        query = query.filter(Ride.id < before_id)
    rides = query.order_by(Ride.id.desc()).limit(limit + 1).all()
    has_more = len(rides) > limit
    rides = rides[:limit]

    items = []
    for ride in rides:
        reviewee_id, reviewee_role = _resolve_participants(ride, reviewer)
        source_ride_id = db.query(RideCancellation.ride_id).filter(
            RideCancellation.return_ride_id == ride.id,
        ).scalar()
        items.append(PendingRideRatingSummary(
            ride_id=ride.id,
            source_ride_id=source_ride_id,
            finished_at=ride.finished_at or ride.updated_at or ride.created_at,
            reviewee=_party(db, reviewee_id, reviewee_role),
            allowed_criteria=_criterion_options(reviewee_role),
        ))
    return PendingRideRatingsPage(
        items=items,
        next_before_id=rides[-1].id if has_more and rides else None,
        has_more=has_more,
    )


def list_received_ratings(
    db: Session,
    user: User,
    limit: int,
    before_id: int | None,
) -> ReceivedRideRatingsPage:
    query = db.query(RideRating).filter(RideRating.reviewee_user_id == user.id)
    if before_id is not None:
        query = query.filter(RideRating.id < before_id)
    rows = query.order_by(RideRating.id.desc()).limit(limit + 1).all()
    has_more = len(rows) > limit
    rows = rows[:limit]
    items = []
    for row in rows:
        reviewer_user = db.query(User).filter(User.id == row.reviewer_user_id).first()
        reviewer_role = _role_name(reviewer_user.user_type_id) if reviewer_user else "unknown"
        items.append(ReceivedRideRatingSummary(
            **{
                "id": row.id,
                "ride_id": row.ride_id,
                "ride_offer_id": row.ride_offer_id,
                "reviewer_user_id": row.reviewer_user_id,
                "reviewee_user_id": row.reviewee_user_id,
                "score": row.score,
                "criteria": row.criteria,
                "comment": row.comment,
                "created_at": row.created_at,
            },
            reviewer=_party(db, row.reviewer_user_id, reviewer_role),
        ))
    return ReceivedRideRatingsPage(
        items=items,
        next_before_id=rows[-1].id if has_more and rows else None,
        has_more=has_more,
    )


def get_user_rating_summary(db: Session, user_id: int) -> UserRatingSummaryResponse:
    if db.query(User.id).filter(User.id == user_id).first() is None:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")
    average, count = db.query(
        func.avg(RideRating.score),
        func.count(RideRating.id),
    ).filter(RideRating.reviewee_user_id == user_id).one()
    normalized_average = None
    if average is not None:
        normalized_average = Decimal(str(average)).quantize(
            Decimal("0.1"),
            rounding=ROUND_HALF_UP,
        )
    return UserRatingSummaryResponse(
        user_id=user_id,
        rating_average=normalized_average,
        rating_count=int(count or 0),
    )


def _resolve_participants(ride: Ride, reviewer: User) -> tuple[int, str]:
    if (
        reviewer.user_type_id == int(UserTypeEnum.CLIENT)
        and ride.client_user_id == reviewer.id
        and ride.driver_user_id is not None
    ):
        return ride.driver_user_id, "driver"
    if (
        reviewer.user_type_id == int(UserTypeEnum.DRIVER)
        and ride.driver_user_id == reviewer.id
    ):
        return ride.client_user_id, "client"
    raise HTTPException(status_code=403, detail="Voce nao pode avaliar esta corrida.")


def _final_offer(db: Session, ride: Ride) -> RideOffer | None:
    if ride.driver_user_id is None:
        return None
    return (
        db.query(RideOffer)
        .filter(
            RideOffer.ride_id == ride.id,
            RideOffer.driver_user_id == ride.driver_user_id,
            RideOffer.status_id == ACCEPTED,
        )
        .order_by(RideOffer.updated_at.desc(), RideOffer.id.desc())
        .first()
    )


def _party(db: Session, user_id: int, role: str) -> dict:
    profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    full_name = "Usuario"
    if profile is not None:
        full_name = f"{profile.first_name} {profile.last_name}".strip()
    return {"id": user_id, "full_name": full_name, "role": role}


def _role_name(user_type_id: int) -> str:
    if user_type_id == int(UserTypeEnum.CLIENT):
        return "client"
    if user_type_id == int(UserTypeEnum.DRIVER):
        return "driver"
    return "unknown"


def _criteria_for_role(role: str):
    return DRIVER_CRITERIA if role == "driver" else CLIENT_CRITERIA


def _criterion_options(role: str) -> list[dict]:
    return [{"key": key, "label": label} for key, label in _criteria_for_role(role)]
