from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, HTTPException
import psycopg

from backend.database import get_connection
from backend.schemas import DisasterCreate

app = FastAPI(
    title="Plataforma de análisis de desastres",
    description=(
        "Servicio de consulta y registro de eventos "
        "y sus ubicaciones geográficas."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

@app.get("/")
def root():
    return {
        "proyecto": "Plataforma de análisis de desastres",
        "estado": "disponible",
        "documentacion": "/docs",
    }


@app.get("/health")
def health():
    try:
        with get_connection() as conn:
            row = conn.execute(
                """
                SELECT
                    current_database() AS base_datos,
                    (
                        SELECT COUNT(*)
                        FROM information_schema.tables
                        WHERE table_schema = 'public'
                          AND table_type = 'BASE TABLE'
                    ) AS tablas
                """
            ).fetchone()

        return {
            "estado": "conectado",
            "base_datos": row["base_datos"],
            "tablas": row["tablas"],
        }
    except psycopg.Error as exc:
        raise HTTPException(
            status_code=503,
            detail="No fue posible conectar con la base de datos.",
        ) from exc


@app.get("/catalogos/municipios")
def listar_municipios():
    try:
        with get_connection() as conn:
            return conn.execute(
                """
                SELECT
                    m.id_municipio,
                    m.nombre AS municipio,
                    dep.nombre AS departamento
                FROM municipios AS m
                JOIN departamentos AS dep
                    ON dep.id_departamento = m.id_departamento
                ORDER BY dep.nombre, m.nombre
                """
            ).fetchall()
    except psycopg.Error as exc:
        raise HTTPException(
            status_code=503,
            detail="No fue posible consultar los municipios.",
        ) from exc

@app.get("/catalogos/tipos-desastre")
def listar_tipos_desastre():
    try:
        with get_connection() as conn:
            return conn.execute(
                """
                SELECT
                    id_tipo_desastre,
                    nombre,
                    descripcion
                FROM tipos_desastre
                WHERE estado = TRUE
                ORDER BY nombre
                """
            ).fetchall()
    except psycopg.Error as exc:
        raise HTTPException(
            status_code=503,
            detail="No fue posible consultar los tipos de desastre.",
        ) from exc

@app.get("/desastres")
def listar_desastres():
    try:
        with get_connection() as conn:
            return conn.execute(
                """
                SELECT
                    d.id_desastre,
                    d.codigo_externo,
                    d.nombre,
                    d.descripcion,
                    d.fecha_inicio,
                    d.fecha_fin,
                    d.latitud,
                    d.longitud,
                    d.estado,
                    d.fecha_registro,
                    td.id_tipo_desastre,
                    td.nombre AS tipo_desastre,
                    m.id_municipio,
                    m.nombre AS municipio,
                    dep.id_departamento,
                    dep.nombre AS departamento
                FROM desastres AS d
                JOIN tipos_desastre AS td
                    ON td.id_tipo_desastre = d.id_tipo_desastre
                JOIN municipios AS m
                    ON m.id_municipio = d.id_municipio
                JOIN departamentos AS dep
                    ON dep.id_departamento = m.id_departamento
                ORDER BY d.fecha_inicio DESC, d.id_desastre DESC
                """
            ).fetchall()
    except psycopg.Error as exc:
        raise HTTPException(
            status_code=503,
            detail="No fue posible consultar los desastres.",
        ) from exc


@app.get("/desastres/{id_desastre}")
def obtener_desastre(id_desastre: int):
    if id_desastre < 1:
        raise HTTPException(
            status_code=422,
            detail="El identificador debe ser positivo.",
        )

    try:
        with get_connection() as conn:
            row = conn.execute(
                """
                SELECT
                    d.id_desastre,
                    d.codigo_externo,
                    d.nombre,
                    d.descripcion,
                    d.fecha_inicio,
                    d.fecha_fin,
                    d.latitud,
                    d.longitud,
                    d.estado,
                    d.fecha_registro,
                    td.id_tipo_desastre,
                    td.nombre AS tipo_desastre,
                    m.id_municipio,
                    m.nombre AS municipio,
                    dep.id_departamento,
                    dep.nombre AS departamento
                FROM desastres AS d
                JOIN tipos_desastre AS td
                    ON td.id_tipo_desastre = d.id_tipo_desastre
                JOIN municipios AS m
                    ON m.id_municipio = d.id_municipio
                JOIN departamentos AS dep
                    ON dep.id_departamento = m.id_departamento
                WHERE d.id_desastre = %s
                """,
                (id_desastre,),
            ).fetchone()

        if row is None:
            raise HTTPException(
                status_code=404,
                detail="No se encontró el desastre solicitado.",
            )

        return row
    except psycopg.Error as exc:
        raise HTTPException(
            status_code=503,
            detail="No fue posible consultar el desastre.",
        ) from exc


@app.post("/desastres", status_code=201)
def crear_desastre(datos: DisasterCreate):
    try:
        with get_connection() as conn:
            with conn.transaction():
                tipo = conn.execute(
                    """
                    SELECT 1
                    FROM tipos_desastre
                    WHERE id_tipo_desastre = %s AND estado = TRUE
                    """,
                    (datos.id_tipo_desastre,),
                ).fetchone()

                if tipo is None:
                    raise HTTPException(
                        status_code=422,
                        detail="El tipo de desastre no existe o está inactivo.",
                    )

                municipio = conn.execute(
                    """
                    SELECT 1
                    FROM municipios
                    WHERE id_municipio = %s
                    """,
                    (datos.id_municipio,),
                ).fetchone()

                if municipio is None:
                    raise HTTPException(
                        status_code=422,
                        detail="El municipio indicado no existe.",
                    )

                row = conn.execute(
                    """
                    INSERT INTO desastres (
                        id_tipo_desastre,
                        id_municipio,
                        codigo_externo,
                        nombre,
                        descripcion,
                        fecha_inicio,
                        fecha_fin,
                        latitud,
                        longitud,
                        estado
                    )
                    VALUES (
                        %(id_tipo_desastre)s,
                        %(id_municipio)s,
                        %(codigo_externo)s,
                        %(nombre)s,
                        %(descripcion)s,
                        %(fecha_inicio)s,
                        %(fecha_fin)s,
                        %(latitud)s,
                        %(longitud)s,
                        %(estado)s
                    )
                    RETURNING
                        id_desastre,
                        id_tipo_desastre,
                        id_municipio,
                        codigo_externo,
                        nombre,
                        descripcion,
                        fecha_inicio,
                        fecha_fin,
                        latitud,
                        longitud,
                        estado,
                        fecha_registro
                    """,
                    datos.model_dump(),
                ).fetchone()

        return row

    except HTTPException:
        raise
    except psycopg.Error as exc:
        raise HTTPException(
            status_code=503,
            detail="No fue posible registrar el desastre.",
        ) from exc

