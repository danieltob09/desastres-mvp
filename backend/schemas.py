from datetime import date
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class DisasterCreate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    id_tipo_desastre: int = Field(gt=0)
    id_municipio: int = Field(gt=0)
    codigo_externo: str | None = Field(default=None, max_length=100)
    nombre: str = Field(min_length=3, max_length=200)
    descripcion: str | None = None
    fecha_inicio: date
    fecha_fin: date | None = None
    latitud: Decimal | None = Field(default=None, ge=-90, le=90)
    longitud: Decimal | None = Field(default=None, ge=-180, le=180)
    estado: Literal["registrado", "activo", "finalizado"] = "registrado"

    @model_validator(mode="after")
    def validar_fechas(self):
        if self.fecha_fin and self.fecha_fin < self.fecha_inicio:
            raise ValueError(
                "La fecha final no puede ser anterior a la fecha inicial."
            )
        return self