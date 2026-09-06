INSERT INTO vehicle_types (
    type,
    default_fuel_type_id,
    default_consumption_km_l,
    default_load_capacity_kg,
    default_cargo_width_cm,
    default_cargo_height_cm,
    default_cargo_length_cm,
    operational_cost_per_km
)
VALUES
(
    'moto',
    (SELECT id FROM fuel_types WHERE type = 'gasoline'),
    35.00, 20, 45, 45, 45, 0.25
),
(
    'hatch',
    (SELECT id FROM fuel_types WHERE type = 'gasoline'),
    11.00, 200, 100, 75, 110, 0.45
),
(
    'sedan',
    (SELECT id FROM fuel_types WHERE type = 'gasoline'),
    10.00, 250, 120, 80, 130, 0.50
),
(
    'pickup',
    (SELECT id FROM fuel_types WHERE type = 'diesel'),
    9.00, 700, 180, 120, 180, 0.90
),
(
    'van',
    (SELECT id FROM fuel_types WHERE type = 'diesel'),
    8.00, 1200, 260, 140, 260, 1.20
),
(
    'utilitário',
    (SELECT id FROM fuel_types WHERE type = 'diesel'),
    7.00, 1500, 320, 170, 320, 1.40
),
(
    'caminhão',
    (SELECT id FROM fuel_types WHERE type = 'diesel'),
    4.00, 5000, 600, 240, 600, 2.50
);