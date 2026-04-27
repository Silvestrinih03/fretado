from app.enums.vehicle_type import VehicleTypeEnum

FIPE_TYPE_MAP = {
    VehicleTypeEnum.MOTO: "motos",
    VehicleTypeEnum.HATCH: "carros",
    VehicleTypeEnum.SEDAN: "carros",
    VehicleTypeEnum.PICKUP: "caminhoes",   # ajuste se quiser tratar pickup leve como carros
    VehicleTypeEnum.VAN: "carros",
    VehicleTypeEnum.UTILITARIO: "carros",
    VehicleTypeEnum.CAMINHAO: "caminhoes",
}