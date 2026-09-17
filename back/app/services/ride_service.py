from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.ride_status_enum import (
    RideStatusEnum,
)
from app.enums.user_type import (
    UserTypeEnum,
)
from app.models.ride import Ride
from app.models.ride_detail import RideDetail
from app.models.ride_status import RideStatus
from app.models.user import User
from app.schemas.driver_earning import (
    DriverEarningCreate,
)
from app.schemas.ride import (
    RideCreateRequest,
    RideFullResponse,
    RideResponse,
    RideUpdate,
)
from app.schemas.ride_quote import (
    RideQuoteRequest,
    RideQuoteResponse,
)
from app.services.driver_earning_service import (
    create_driver_earning,
)
from app.services.ride_offer_service import (
    create_next_offer,
    process_expired_offer_for_ride,
)
from app.services.ride_quote_service import (
    RideQuoteService,
)


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def calculate_ride_price(
    db: Session,
    payload: RideQuoteRequest,
) -> RideQuoteResponse:
    return RideQuoteService().quote(
        db=db,
        payload=payload,
    )


def create_ride_after_payment(
    db: Session,
    payload: RideCreateRequest,
    quote: RideQuoteResponse | None = None,
):
    if not payload.payment_confirmed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Pagamento deve ser confirmado "
                "antes de criar a corrida."
            ),
        )

    validate_user_exists(
        db=db,
        user_id=payload.client_user_id,
        label="Cliente",
    )

    quote = (
        quote
        or calculate_ride_price(
            db=db,
            payload=payload,
        )
    )

    ride_status = get_ride_status_by_id(
        db=db,
        status_id=int(
            RideStatusEnum.AGUARDANDO_ACEITE
        ),
    )

    ride = Ride(
        client_user_id=(
            payload.client_user_id
        ),
        driver_user_id=None,
        required_vehicle_type_id=(
            quote.required_vehicle_type_id
        ),
        total_price=(
            quote.total_price
        ),
        app_fee_value=(
            quote.pricing.app_fee_value
        ),
        status_id=(
            ride_status.id
        ),
    )

    db.add(ride)
    db.flush()

    ride_detail = RideDetail(
        ride_id=ride.id,

        origin_address=(
            payload.origin_address
        ),
        origin_address_complement=(
            payload.origin_address_complement
        ),
        origin_reference_point=(
            payload.origin_reference_point
        ),

        origin_latitude=(
            payload.origin_latitude
        ),
        origin_longitude=(
            payload.origin_longitude
        ),

        destination_address=(
            payload.destination_address
        ),
        destination_address_complement=(
            payload.destination_address_complement
        ),
        destination_reference_point=(
            payload.destination_reference_point
        ),

        destination_latitude=(
            payload.destination_latitude
        ),
        destination_longitude=(
            payload.destination_longitude
        ),

        package_width=(
            payload.package_width
        ),
        package_height=(
            payload.package_height
        ),
        package_length=(
            payload.package_length
        ),
        package_weight=(
            payload.package_weight
        ),
    )

    db.add(ride_detail)
    db.flush()

    create_next_offer(
        db=db,
        ride_id=ride.id,
    )

    db.commit()
    db.refresh(ride)

    return (
        ride,
        quote,
        ride_status,
    )


def get_rides_by_client_user_id(
    db: Session,
    client_user_id: int,
):
    rides = (
        db.query(Ride)
        .filter(
            Ride.client_user_id
            == client_user_id
        )
        .order_by(
            Ride.created_at.desc()
        )
        .all()
    )

    for ride in rides:
        if (
            ride.status_id
            == int(
                RideStatusEnum
                .AGUARDANDO_ACEITE
            )
        ):
            process_expired_offer_for_ride(
                db=db,
                ride_id=ride.id,
            )

    db.commit()

    return [
        build_full_response(
            db=db,
            ride=ride,
        )
        for ride in rides
    ]


def get_rides_by_driver_user_id(
    db: Session,
    driver_user_id: int,
):
    rides = (
        db.query(Ride)
        .filter(
            Ride.driver_user_id
            == driver_user_id
        )
        .order_by(
            Ride.created_at.desc()
        )
        .all()
    )

    return [
        build_full_response(
            db=db,
            ride=ride,
        )
        for ride in rides
    ]


def get_ride_by_id(
    db: Session,
    ride_id: int,
):
    ride = (
        db.query(Ride)
        .filter(
            Ride.id == ride_id
        )
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    if (
        ride.status_id
        == int(
            RideStatusEnum.AGUARDANDO_ACEITE
        )
    ):
        process_expired_offer_for_ride(
            db=db,
            ride_id=ride.id,
        )

        db.commit()
        db.refresh(ride)

    return build_full_response(
        db=db,
        ride=ride,
    )


def build_full_response(
    db: Session,
    ride: Ride,
) -> RideFullResponse:
    detail = (
        db.query(RideDetail)
        .filter(
            RideDetail.ride_id
            == ride.id
        )
        .first()
    )

    return RideFullResponse(
        **{
            field: getattr(
                ride,
                field,
            )
            for field
            in RideResponse.model_fields
        },
        details=detail,
    )


def update_ride(
    db: Session,
    ride_id: int,
    ride_data: RideUpdate,
):
    ride = (
        db.query(Ride)
        .filter(
            Ride.id == ride_id
        )
        .with_for_update()
        .populate_existing()
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    update_data = (
        ride_data.model_dump(
            exclude_unset=True
        )
    )

    if (
        "driver_user_id"
        in update_data
        and update_data["driver_user_id"]
        != ride.driver_user_id
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Use o aceite da oferta "
                "para atribuir motorista."
            ),
        )

    forbidden_fields = {
        "started_at",
        "finished_at",
        "cancelled_at",
        "required_vehicle_type_id",
        "total_price",
        "app_fee_value",
    }

    if any(
        field in update_data
        for field in forbidden_fields
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Campo controlado pelo servidor."
            ),
        )

    requested_status = (
        update_data.get(
            "status_id",
            ride.status_id,
        )
    )

    if requested_status != ride.status_id:
        if (
            requested_status
            == int(
                RideStatusEnum
                .A_CAMINHO_COLETA
            )
        ):
            return start_ride(
                db=db,
                ride_id=ride_id,
            )

        if (
            requested_status
            == int(
                RideStatusEnum
                .A_CAMINHO_ENTREGA
            )
        ):
            return complete_pickup(
                db=db,
                ride_id=ride_id,
            )

        if (
            requested_status
            == int(
                RideStatusEnum.FINALIZADA
            )
        ):
            return finish_ride(
                db=db,
                ride_id=ride_id,
            )

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Transicao de status invalida.",
        )

    db.commit()
    db.refresh(ride)

    return ride


def get_rides_in_progress_by_user_id(
    db: Session,
    user_id: int,
):
    user = (
        db.query(User)
        .filter(
            User.id == user_id
        )
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario nao encontrado.",
        )

    finished_statuses = [
        int(RideStatusEnum.FINALIZADA),
        int(RideStatusEnum.CANCELADA),
        int(RideStatusEnum.NAO_ATENDIDA),
    ]

    query = (
        db.query(Ride)
        .filter(
            Ride.status_id.notin_(
                finished_statuses
            )
        )
    )

    if (
        user.user_type_id
        == int(UserTypeEnum.CLIENT)
    ):
        query = query.filter(
            Ride.client_user_id
            == user_id
        )

    elif (
        user.user_type_id
        == int(UserTypeEnum.DRIVER)
    ):
        query = query.filter(
            Ride.driver_user_id
            == user_id
        )

    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tipo de usuario invalido.",
        )

    rides = query.all()

    return [
        build_full_response(
            db=db,
            ride=ride,
        )
        for ride in rides
    ]


def start_ride(
    db: Session,
    ride_id: int,
):
    ride = _get_ride_model(
        db=db,
        ride_id=ride_id,
    )

    if ride.driver_user_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Corrida precisa ter motorista "
                "para ser iniciada."
            ),
        )

    if (
        ride.status_id
        != int(
            RideStatusEnum.AGUARDANDO_INICIO
        )
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Apenas corridas aguardando inicio "
                "podem ser iniciadas."
            ),
        )

    ride.status_id = int(
        RideStatusEnum.A_CAMINHO_COLETA
    )

    ride.started_at = utc_now()

    db.commit()
    db.refresh(ride)

    return ride


def complete_pickup(
    db: Session,
    ride_id: int,
):
    ride = _get_ride_model(
        db=db,
        ride_id=ride_id,
    )

    if (
        ride.status_id
        != int(
            RideStatusEnum.A_CAMINHO_COLETA
        )
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Apenas corridas a caminho da coleta "
                "podem concluir a coleta."
            ),
        )

    ride.status_id = int(
        RideStatusEnum.A_CAMINHO_ENTREGA
    )

    db.commit()
    db.refresh(ride)

    return ride


def finish_ride(
    db: Session,
    ride_id: int,
):
    ride = (
        db.query(Ride)
        .filter(
            Ride.id == ride_id
        )
        .with_for_update()
        .populate_existing()
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    if (
        ride.status_id
        != int(
            RideStatusEnum.A_CAMINHO_ENTREGA
        )
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Apenas corridas a caminho da entrega "
                "podem ser finalizadas."
            ),
        )

    if ride.driver_user_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Corrida nao possui motorista.",
        )

    ride.status_id = int(
        RideStatusEnum.FINALIZADA
    )

    ride.finished_at = utc_now()

    create_driver_earning(
        db=db,
        driver_earning_data=(
            DriverEarningCreate(
                driver_user_id=(
                    ride.driver_user_id
                ),
                ride_id=ride.id,
            )
        ),
        commit=False,
    )

    db.commit()
    db.refresh(ride)

    return ride


def validate_user_exists(
    db: Session,
    user_id: int,
    label: str,
) -> None:
    user = (
        db.query(User)
        .filter(
            User.id == user_id
        )
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{label} nao encontrado.",
        )


def get_ride_status_by_id(
    db: Session,
    status_id: int,
) -> RideStatus:
    ride_status = (
        db.query(RideStatus)
        .filter(
            RideStatus.id == status_id
        )
        .first()
    )

    if not ride_status:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Status da corrida nao encontrado.",
        )

    return ride_status


def _get_ride_model(
    db: Session,
    ride_id: int,
) -> Ride:
    ride = (
        db.query(Ride)
        .filter(
            Ride.id == ride_id
        )
        .first()
    )

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    return ride