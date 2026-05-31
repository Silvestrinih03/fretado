from enum import IntEnum


class RideStatusEnum(IntEnum):
    AGUARDANDO_ACEITE = 1
    AGUARDANDO_INICIO = 2
    A_CAMINHO_COLETA = 3
    A_CAMINHO_ENTREGA = 4
    FINALIZADA = 5
    CANCELADA = 6