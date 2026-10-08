ALTER TABLE ride_cancellations
    ADD COLUMN original_destination_address VARCHAR(255),
    ADD COLUMN original_destination_address_complement VARCHAR(255),
    ADD COLUMN original_destination_reference_point VARCHAR(255),
    ADD COLUMN original_destination_latitude NUMERIC(9,6),
    ADD COLUMN original_destination_longitude NUMERIC(9,6),
    ADD COLUMN quote_prepared_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN return_started_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN return_completed_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN distance_calculation_source VARCHAR(30);

UPDATE ride_cancellations cancellation
SET
    original_destination_address = detail.destination_address,
    original_destination_address_complement = detail.destination_address_complement,
    original_destination_reference_point = detail.destination_reference_point,
    original_destination_latitude = detail.destination_latitude,
    original_destination_longitude = detail.destination_longitude,
    quote_prepared_at = COALESCE(
        cancellation.driver_confirmed_at,
        cancellation.driver_location_recorded_at
    ),
    distance_calculation_source = CASE
        WHEN cancellation.traveled_distance_km IS NOT NULL
          OR cancellation.return_distance_km IS NOT NULL
        THEN 'mapbox_route'
        ELSE NULL
    END
FROM ride_details detail
WHERE detail.ride_id = cancellation.ride_id;

UPDATE ride_cancellations cancellation
SET
    return_started_at = COALESCE(return_ride.started_at, cancellation.completed_at),
    return_completed_at = return_ride.finished_at
FROM rides return_ride
WHERE return_ride.id = cancellation.return_ride_id;

ALTER TABLE ride_cancellations
    ADD CONSTRAINT chk_ride_cancellation_original_destination_coordinates
    CHECK (
        (original_destination_latitude IS NULL AND original_destination_longitude IS NULL)
        OR (
            original_destination_latitude BETWEEN -90 AND 90
            AND original_destination_longitude BETWEEN -180 AND 180
        )
    ),
    ADD CONSTRAINT chk_ride_cancellation_distance_source
    CHECK (
        distance_calculation_source IS NULL
        OR distance_calculation_source = 'mapbox_route'
    );

CREATE UNIQUE INDEX uq_ride_cancellations_return_ride
ON ride_cancellations (return_ride_id)
WHERE return_ride_id IS NOT NULL;

ALTER TABLE driver_earnings
    DROP CONSTRAINT chk_driver_earnings_type;

UPDATE driver_earnings earning
SET earning_type = 'cancellation_return'
FROM ride_cancellations cancellation
WHERE earning.ride_id = cancellation.return_ride_id;

ALTER TABLE driver_earnings
    ADD CONSTRAINT chk_driver_earnings_type
    CHECK (
        earning_type IN (
            'ride_completion',
            'cancellation_fee',
            'cancellation_return'
        )
    );
