import csv
from decimal import Decimal, InvalidOperation
from pathlib import Path

from backend.database import get_connection


BASE_DIR = Path(__file__).resolve().parents[2]
CSV_PATH = BASE_DIR / "database" / "imports" / "divipola.csv"


def convertir_coordenada(valor):
    valor = (valor or "").strip()

    if not valor:
        return None

    try:
        return Decimal(valor.replace(",", "."))
    except InvalidOperation as exc:
        raise ValueError(f"Coordenada no válida: {valor!r}") from exc


def cargar_datos():
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as archivo:
        filas = list(csv.DictReader(archivo))

    requeridas = {
        "cod_dpto",
        "dpto",
        "cod_mpio",
        "nom_mpio",
        "tipo_municipio",
        "longitud",
        "latitud",
    }

    if not filas or not requeridas.issubset(filas[0].keys()):
        raise ValueError("El CSV está vacío o sus encabezados no coinciden.")

    departamentos = {}

    for fila in filas:
        codigo = fila["cod_dpto"].strip()
        nombre = fila["dpto"].strip()

        if not codigo or not nombre:
            raise ValueError("Hay departamentos con código o nombre vacío.")

        departamentos[codigo] = nombre

    municipios = [
        fila for fila in filas
        if fila["tipo_municipio"].strip() == "Municipio"
    ]

    if len(municipios) != 1103:
        raise ValueError(
            f"Se esperaban 1103 municipios; se encontraron {len(municipios)}."
        )

    codigos_municipio = [fila["cod_mpio"].strip() for fila in municipios]

    if any(not codigo for codigo in codigos_municipio):
        raise ValueError("Hay municipios sin código DIVIPOLA.")

    if len(set(codigos_municipio)) != len(codigos_municipio):
        raise ValueError("Hay códigos municipales duplicados en el CSV.")

    with get_connection() as conn:
        with conn.transaction():
            for codigo, nombre in sorted(departamentos.items()):
                conn.execute(
                    """
                    INSERT INTO departamentos (codigo_dane, nombre)
                    VALUES (%s, %s)
                    ON CONFLICT (codigo_dane)
                    DO UPDATE SET nombre = EXCLUDED.nombre
                    """,
                    (codigo, nombre),
                )

            for fila in municipios:
                codigo_departamento = fila["cod_dpto"].strip()
                codigo_municipio = fila["cod_mpio"].strip()

                departamento = conn.execute(
                    """
                    SELECT id_departamento
                    FROM departamentos
                    WHERE codigo_dane = %s
                    """,
                    (codigo_departamento,),
                ).fetchone()

                if departamento is None:
                    raise ValueError(
                        f"No existe el departamento {codigo_departamento}."
                    )

                conn.execute(
                    """
                    INSERT INTO municipios (
                        id_departamento,
                        codigo_dane,
                        nombre,
                        latitud,
                        longitud
                    )
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT (codigo_dane)
                    DO UPDATE SET
                        id_departamento = EXCLUDED.id_departamento,
                        nombre = EXCLUDED.nombre,
                        latitud = EXCLUDED.latitud,
                        longitud = EXCLUDED.longitud
                    """,
                    (
                        departamento["id_departamento"],
                        codigo_municipio,
                        fila["nom_mpio"].strip(),
                        convertir_coordenada(fila["latitud"]),
                        convertir_coordenada(fila["longitud"]),
                    ),
                )

            conteos = conn.execute(
                """
                SELECT
                    (SELECT COUNT(*) FROM departamentos) AS departamentos,
                    (SELECT COUNT(*) FROM municipios) AS municipios
                """
            ).fetchone()

    print("Carga DIVIPOLA completada.")
    print(f"Filas de origen: {len(filas)}")
    print(f"Departamentos en la base: {conteos['departamentos']}")
    print(f"Municipios en la base: {conteos['municipios']}")


if __name__ == "__main__":
    cargar_datos()
