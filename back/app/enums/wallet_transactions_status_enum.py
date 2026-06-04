from enum import IntEnum

class WalletTransactionsStatusEnum(IntEnum):
    PROCESSANDO = 1
    FINALIZADO = 2       
    FALHADA = 3
    CANCELADO = 4