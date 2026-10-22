BEGIN;

CREATE TABLE roles (
    id_rol INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    estado BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE usuarios (
    id_usuario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_rol INTEGER NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
 
    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol)
);
CREATE TABLE departamentos (
    id_departamento INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_dane VARCHAR(2) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL
);
CREATE TABLE municipios (
    id_municipio INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_departamento INTEGER NOT NULL,
    codigo_dane VARCHAR(5) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    latitud NUMERIC(10,7),
    longitud NUMERIC(10,7),
 
    CONSTRAINT fk_municipios_departamentos
        FOREIGN KEY (id_departamento)
        REFERENCES departamentos(id_departamento),
 
    CONSTRAINT chk_municipios_latitud
        CHECK (latitud BETWEEN -90 AND 90),
 
    CONSTRAINT chk_municipios_longitud
        CHECK (longitud BETWEEN -180 AND 180)
);
CREATE TABLE tipos_desastre (
    id_tipo_desastre INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    estado BOOLEAN NOT NULL DEFAULT TRUE
);
 
CREATE TABLE fuentes_informacion (
    id_fuente INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    entidad VARCHAR(150),
    url TEXT,
    descripcion TEXT,
    fecha_consulta DATE,
    estado BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE desastres (
    id_desastre INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_desastre INTEGER NOT NULL,
    id_municipio INTEGER NOT NULL,
    codigo_externo VARCHAR(100),
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    latitud NUMERIC(10,7),
    longitud NUMERIC(10,7),
    estado VARCHAR(30) NOT NULL DEFAULT 'registrado',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 
    CONSTRAINT fk_desastres_tipos
        FOREIGN KEY (id_tipo_desastre)
        REFERENCES tipos_desastre(id_tipo_desastre),
 
    CONSTRAINT fk_desastres_municipios
        FOREIGN KEY (id_municipio)
        REFERENCES municipios(id_municipio),
 
    CONSTRAINT chk_desastres_fechas
        CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
 
    CONSTRAINT chk_desastres_latitud
        CHECK (latitud BETWEEN -90 AND 90),
 
    CONSTRAINT chk_desastres_longitud
        CHECK (longitud BETWEEN -180 AND 180),
 
    CONSTRAINT chk_desastres_estado
        CHECK (estado IN ('registrado', 'activo', 'finalizado'))
);
CREATE TABLE desastres_fuentes (
    id_desastre_fuente INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_desastre INTEGER NOT NULL,
    id_fuente INTEGER NOT NULL,
    referencia TEXT,
 
    CONSTRAINT fk_desastres_fuentes_desastre
        FOREIGN KEY (id_desastre)
        REFERENCES desastres(id_desastre)
        ON DELETE CASCADE,
 
    CONSTRAINT fk_desastres_fuentes_fuente
        FOREIGN KEY (id_fuente)
        REFERENCES fuentes_informacion(id_fuente),
 
    CONSTRAINT uq_desastres_fuentes
        UNIQUE (id_desastre, id_fuente)
);
CREATE TABLE comunidades (
    id_comunidad INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_municipio INTEGER NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    direccion VARCHAR(200),
    latitud NUMERIC(10,7),
    longitud NUMERIC(10,7),
    poblacion_estimada INTEGER,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
 
    CONSTRAINT fk_comunidades_municipios
        FOREIGN KEY (id_municipio)
        REFERENCES municipios(id_municipio),
 
    CONSTRAINT chk_comunidades_poblacion
        CHECK (poblacion_estimada >= 0),
 
    CONSTRAINT chk_comunidades_latitud
        CHECK (latitud BETWEEN -90 AND 90),
 
    CONSTRAINT chk_comunidades_longitud
        CHECK (longitud BETWEEN -180 AND 180)
);
 
CREATE TABLE afectaciones (
    id_afectacion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_desastre INTEGER NOT NULL,
    id_comunidad INTEGER NOT NULL,
    personas_afectadas INTEGER NOT NULL DEFAULT 0,
    familias_afectadas INTEGER NOT NULL DEFAULT 0,
    personas_fallecidas INTEGER NOT NULL DEFAULT 0,
    personas_heridas INTEGER NOT NULL DEFAULT 0,
    personas_desaparecidas INTEGER NOT NULL DEFAULT 0,
    viviendas_afectadas INTEGER NOT NULL DEFAULT 0,
    perdidas_economicas NUMERIC(18,2),
    descripcion TEXT,
    fecha_reporte DATE NOT NULL,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 
    CONSTRAINT fk_afectaciones_desastres
        FOREIGN KEY (id_desastre)
        REFERENCES desastres(id_desastre),
 
    CONSTRAINT fk_afectaciones_comunidades
        FOREIGN KEY (id_comunidad)
        REFERENCES comunidades(id_comunidad),
 
    CONSTRAINT chk_afectaciones_personas
        CHECK (
            personas_afectadas >= 0 AND
            familias_afectadas >= 0 AND
            personas_fallecidas >= 0 AND
            personas_heridas >= 0 AND
            personas_desaparecidas >= 0 AND
            viviendas_afectadas >= 0
        ),
 
    CONSTRAINT chk_afectaciones_perdidas
        CHECK (perdidas_economicas >= 0),
 
    CONSTRAINT uq_afectaciones
        UNIQUE (id_desastre, id_comunidad, fecha_reporte)
);
CREATE TABLE categorias_necesidad (
    id_categoria INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    estado BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE necesidades (
    id_necesidad INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_afectacion INTEGER NOT NULL,
    id_categoria INTEGER NOT NULL,
    descripcion TEXT NOT NULL,
    cantidad_requerida NUMERIC(12,2),
    unidad_medida VARCHAR(50),
    prioridad VARCHAR(20) NOT NULL DEFAULT 'media',
    estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 
    CONSTRAINT fk_necesidades_afectaciones
        FOREIGN KEY (id_afectacion)
        REFERENCES afectaciones(id_afectacion),
 
    CONSTRAINT fk_necesidades_categorias
        FOREIGN KEY (id_categoria)
        REFERENCES categorias_necesidad(id_categoria),
 
    CONSTRAINT chk_necesidades_cantidad
        CHECK (cantidad_requerida > 0),
 
    CONSTRAINT chk_necesidades_prioridad
        CHECK (prioridad IN ('baja', 'media', 'alta', 'critica')),
 
    CONSTRAINT chk_necesidades_estado
        CHECK (estado IN ('pendiente', 'parcial', 'atendida'))
);
CREATE TABLE organizaciones (
    id_organizacion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    correo VARCHAR(150),
    telefono VARCHAR(20),
    descripcion TEXT,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
 
    CONSTRAINT chk_organizaciones_tipo
        CHECK (
            tipo IN (
                'gubernamental',
                'humanitaria',
                'privada',
                'comunitaria',
                'otra'
            )
        )
);
 
CREATE TABLE recursos (
    id_recurso INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_categoria INTEGER NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    unidad_medida VARCHAR(50) NOT NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
 
    CONSTRAINT fk_recursos_categorias
        FOREIGN KEY (id_categoria)
        REFERENCES categorias_necesidad(id_categoria)
);
CREATE TABLE ayudas (
    id_ayuda INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_afectacion INTEGER NOT NULL,
    id_organizacion INTEGER NOT NULL,
    id_recurso INTEGER NOT NULL,
    cantidad NUMERIC(12,2) NOT NULL,
    fecha_entrega DATE NOT NULL,
    descripcion TEXT,
    estado VARCHAR(30) NOT NULL DEFAULT 'registrada',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 
    CONSTRAINT fk_ayudas_afectaciones
        FOREIGN KEY (id_afectacion)
        REFERENCES afectaciones(id_afectacion),
 
    CONSTRAINT fk_ayudas_organizaciones
        FOREIGN KEY (id_organizacion)
        REFERENCES organizaciones(id_organizacion),
 
    CONSTRAINT fk_ayudas_recursos
        FOREIGN KEY (id_recurso)
        REFERENCES recursos(id_recurso),
 
    CONSTRAINT chk_ayudas_cantidad
        CHECK (cantidad > 0),
 
    CONSTRAINT chk_ayudas_estado
        CHECK (estado IN ('registrada', 'entregada', 'verificada'))
);
CREATE TABLE ayudas_necesidades (
    id_ayuda_necesidad INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_ayuda INTEGER NOT NULL,
    id_necesidad INTEGER NOT NULL,
    cantidad_asignada NUMERIC(12,2) NOT NULL,
 
    CONSTRAINT fk_ayudas_necesidades_ayuda
        FOREIGN KEY (id_ayuda)
        REFERENCES ayudas(id_ayuda),
 
    CONSTRAINT fk_ayudas_necesidades_necesidad
        FOREIGN KEY (id_necesidad)
        REFERENCES necesidades(id_necesidad),
 
    CONSTRAINT chk_ayudas_necesidades_cantidad
        CHECK (cantidad_asignada > 0),
 
    CONSTRAINT uq_ayudas_necesidades
        UNIQUE (id_ayuda, id_necesidad)
);
CREATE TABLE cargas_datos (
    id_carga INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario INTEGER NOT NULL,
    id_fuente INTEGER,
    nombre_archivo VARCHAR(255) NOT NULL,
    registros_procesados INTEGER NOT NULL DEFAULT 0,
    registros_validos INTEGER NOT NULL DEFAULT 0,
    registros_rechazados INTEGER NOT NULL DEFAULT 0,
    fecha_carga TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
    observaciones TEXT,
 
    CONSTRAINT fk_cargas_usuarios
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),
 
    CONSTRAINT fk_cargas_fuentes
        FOREIGN KEY (id_fuente)
        REFERENCES fuentes_informacion(id_fuente),
 
    CONSTRAINT chk_cargas_cantidades
        CHECK (
            registros_procesados >= 0 AND
            registros_validos >= 0 AND
            registros_rechazados >= 0 AND
            registros_validos + registros_rechazados
<= registros_procesados
        ),
 
    CONSTRAINT chk_cargas_estado
        CHECK (
            estado IN (
                'pendiente',
                'procesando',
                'finalizada',
                'error'
            )
        )
);
CREATE INDEX idx_usuarios_rol
ON usuarios(id_rol);
 
CREATE INDEX idx_municipios_departamento
ON municipios(id_departamento);
 
CREATE INDEX idx_desastres_tipo
ON desastres(id_tipo_desastre);
 
CREATE INDEX idx_desastres_municipio
ON desastres(id_municipio);
 
CREATE INDEX idx_desastres_fecha
ON desastres(fecha_inicio);
 
CREATE INDEX idx_desastres_estado
ON desastres(estado);
 
CREATE INDEX idx_desastres_ubicacion
ON desastres(latitud, longitud);
 
CREATE INDEX idx_comunidades_municipio
ON comunidades(id_municipio);
 
CREATE INDEX idx_afectaciones_desastre
ON afectaciones(id_desastre);
 
CREATE INDEX idx_afectaciones_comunidad
ON afectaciones(id_comunidad);
 
CREATE INDEX idx_afectaciones_fecha
ON afectaciones(fecha_reporte);
 
CREATE INDEX idx_necesidades_afectacion
ON necesidades(id_afectacion);
 
CREATE INDEX idx_necesidades_categoria
ON necesidades(id_categoria);
 
CREATE INDEX idx_necesidades_prioridad
ON necesidades(prioridad);
 
CREATE INDEX idx_recursos_categoria
ON recursos(id_categoria);
 
CREATE INDEX idx_ayudas_afectacion
ON ayudas(id_afectacion);
 
CREATE INDEX idx_ayudas_organizacion
ON ayudas(id_organizacion);
 
CREATE INDEX idx_ayudas_recurso
ON ayudas(id_recurso);
 
CREATE INDEX idx_ayudas_fecha
ON ayudas(fecha_entrega);
 
INSERT INTO roles (nombre, descripcion)
VALUES
('administrador', 'Gestiona la informacion y los usuarios'),
('investigador', 'Consulta y analiza informacion'),
('usuario', 'Consulta informacion publica');

INSERT INTO tipos_desastre (nombre, descripcion)
VALUES
('terremoto', 'Movimiento sismico de la corteza terrestre'),
('inundacion', 'Acumulacion o desbordamiento de agua'),
('deslizamiento', 'Movimiento de tierra o materiales'),
('incendio forestal', 'Incendio en zonas de vegetacion'),
('erupcion volcanica', 'Actividad eruptiva de un volcan'),
('sequía', 'Periodo prolongado de escasez de precipitaciones'),
('vendaval', 'Evento meteorologico con vientos intensos'),
('avenida torrencial', 'Flujo rapido de agua y materiales'),
('tsunami', 'Serie de olas generadas por perturbaciones'),
('otro', 'Otros eventos naturales');

 
INSERT INTO categorias_necesidad (nombre, descripcion)
VALUES
('alimentacion', 'Alimentos y suministros alimentarios'),
('agua potable', 'Agua apta para consumo humano'),
('salud', 'Atencion medica y medicamentos'),
('vivienda', 'Refugios y alojamiento temporal'),
('vestimenta', 'Ropa y elementos personales'),
('higiene', 'Productos de higiene personal'),
('transporte', 'Movilizacion de personas y recursos'),
('educacion', 'Recursos para continuidad educativa'),
('infraestructura', 'Reparacion y recuperacion de infraestructura'),
('otro', 'Otras necesidades humanitarias');
 

INSERT INTO fuentes_informacion
(nombre, entidad, url, descripcion)
VALUES
(
    'EM-DAT',
    'Centre for Research on the Epidemiology of Disasters',
    'https://www.emdat.be/',
    'Base de datos internacional de desastres'
),
(
    'Datos Abiertos Colombia',
    'Gobierno de Colombia',
    'https://www.datos.gov.co/',
    'Portal oficial de datos abiertos'
),
(
    'UNGRD',
    'Unidad Nacional para la Gestion del Riesgo de Desastres',
    'https://www.gestiondelriesgo.gov.co/',
    'Informacion institucional sobre gestion del riesgo'
);

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

COMMIT;