"""Normalize administrative state fields without guessing from address text."""

import unicodedata


_STATE_NAMES = {
    "AC": "ACRE",
    "AL": "ALAGOAS",
    "AP": "AMAPA",
    "AM": "AMAZONAS",
    "BA": "BAHIA",
    "CE": "CEARA",
    "DF": "DISTRITO FEDERAL",
    "ES": "ESPIRITO SANTO",
    "GO": "GOIAS",
    "MA": "MARANHAO",
    "MT": "MATO GROSSO",
    "MS": "MATO GROSSO DO SUL",
    "MG": "MINAS GERAIS",
    "PA": "PARA",
    "PB": "PARAIBA",
    "PR": "PARANA",
    "PE": "PERNAMBUCO",
    "PI": "PIAUI",
    "RJ": "RIO DE JANEIRO",
    "RN": "RIO GRANDE DO NORTE",
    "RS": "RIO GRANDE DO SUL",
    "RO": "RONDONIA",
    "RR": "RORAIMA",
    "SC": "SANTA CATARINA",
    "SP": "SAO PAULO",
    "SE": "SERGIPE",
    "TO": "TOCANTINS",
}
_STATE_CODES = {name: code for code, name in _STATE_NAMES.items()}


def normalize_brazilian_state(value: object) -> str | None:
    """Accept a Brazilian UF, BR-prefixed ISO code, or full state name."""
    if not isinstance(value, str):
        return None
    normalized = " ".join(
        "".join(
            character
            for character in unicodedata.normalize("NFKD", value)
            if not unicodedata.combining(character)
        ).upper().split()
    ).removeprefix("BR-")
    if normalized in _STATE_NAMES:
        return normalized
    return _STATE_CODES.get(normalized)
