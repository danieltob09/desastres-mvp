
import { useCallback, useEffect, useState } from 'react'
import './App.css'

const API_URL = 'http://127.0.0.1:8000'

const INITIAL_FORM = {
  id_tipo_desastre: '',
  id_municipio: '',
  codigo_externo: '',
  nombre: '',
  descripcion: '',
  fecha_inicio: new Date().toISOString().slice(0, 10),
  fecha_fin: '',
  latitud: '',
  longitud: '',
  estado: 'registrado',
}

async function requestJson(url, options = {}) {
  const response = await fetch(url, {
    ...options,
    headers: {
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...options.headers,
    },
  })

  const data = await response.json().catch(() => null)

  if (!response.ok) {
    const detail = data?.detail
    const message = Array.isArray(detail)
      ? detail.map((item) => item.msg).join(' ')
      : typeof detail === 'string'
        ? detail
        : `Error HTTP ${response.status}`

    throw new Error(message)
  }

  return data
}

function App() {
  const [types, setTypes] = useState([])
  const [municipalities, setMunicipalities] = useState([])
  const [disasters, setDisasters] = useState([])
  const [form, setForm] = useState(INITIAL_FORM)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  const loadData = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const [typeData, municipalityData, disasterData] = await Promise.all([
        requestJson(`${API_URL}/catalogos/tipos-desastre`),
        requestJson(`${API_URL}/catalogos/municipios`),
        requestJson(`${API_URL}/desastres`),
      ])

      if (!Array.isArray(typeData) || !Array.isArray(municipalityData)) {
        throw new Error('La API devolvio un catalogo con formato inesperado.')
      }

      const records = Array.isArray(disasterData)
        ? disasterData
        : disasterData?.value

      if (!Array.isArray(records)) {
        throw new Error('La respuesta del listado no contiene una lista de registros.')
      }

      setTypes(typeData)
      setMunicipalities(municipalityData)
      setDisasters(records)
    } catch (err) {
      setError(err.message || 'No fue posible cargar los datos.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadData()
  }, [loadData])

  function handleChange(event) {
    const { name, value } = event.target
    setForm((previous) => ({ ...previous, [name]: value }))
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setError('')
    setNotice('')

    if (!form.id_tipo_desastre || !form.id_municipio) {
      setError('Selecciona el tipo de desastre y el municipio.')
      return
    }

    if (form.fecha_fin && form.fecha_fin < form.fecha_inicio) {
      setError('La fecha final no puede ser anterior a la fecha inicial.')
      return
    }

    const payload = {
      id_tipo_desastre: Number(form.id_tipo_desastre),
      id_municipio: Number(form.id_municipio),
      codigo_externo: form.codigo_externo.trim() || null,
      nombre: form.nombre.trim(),
      descripcion: form.descripcion.trim() || null,
      fecha_inicio: form.fecha_inicio,
      fecha_fin: form.fecha_fin || null,
      latitud: form.latitud === '' ? null : Number(form.latitud),
      longitud: form.longitud === '' ? null : Number(form.longitud),
      estado: form.estado,
    }

    setSaving(true)

    try {
      const created = await requestJson(`${API_URL}/desastres`, {
        method: 'POST',
        body: JSON.stringify(payload),
      })

      setNotice(`Registro creado correctamente. ID: ${created.id_desastre}`)
      setForm({ ...INITIAL_FORM, fecha_inicio: form.fecha_inicio })

      await loadData()
    } catch (err) {
      setError(err.message || 'No fue posible registrar el desastre.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <main className="dashboard">
      <header className="dashboard-header">
        <div>
          <p className="eyebrow">SISTEMA DE INFORMACION</p>
          <h1>Analisis de desastres</h1>
          <p className="subtitle">
            Registro y consulta de eventos asociados a comunidades.
          </p>
        </div>

        <div className={`connection ${loading ? 'is-loading' : error ? 'has-error' : 'is-ready'}`}>
          <span className="status-dot" />
          {loading ? 'Consultando API' : error ? 'Revisar servicio' : 'API disponible'}
        </div>
      </header>

      {error && (
        <div className="alert alert-error" role="alert">
          <strong>No se pudo completar la operacion.</strong>
          <p>{error}</p>
        </div>
      )}

      {notice && (
        <div className="alert alert-success" role="status">
          {notice}
        </div>
      )}

      <section className="panel">
        <div className="panel-heading">
          <div>
            <p className="section-kicker">NUEVO REGISTRO</p>
            <h2>Registrar desastre</h2>
            <p>Completa los datos del evento que deseas documentar.</p>
          </div>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-grid">
            <label>
              Nombre del evento *
              <input
                name="nombre"
                value={form.nombre}
                onChange={handleChange}
                minLength={3}
                maxLength={200}
                placeholder="Ej. Inundacion en zona rural"
                required
              />
            </label>

            <label>
              Tipo de desastre *
              <select
                name="id_tipo_desastre"
                value={form.id_tipo_desastre}
                onChange={handleChange}
                required
              >
                <option value="">Selecciona un tipo</option>
                {types.map((item) => (
                  <option key={item.id_tipo_desastre} value={item.id_tipo_desastre}>
                    {item.nombre}
                  </option>
                ))}
              </select>
            </label>

            <label className="field-wide">
              Municipio *
              <select
                name="id_municipio"
                value={form.id_municipio}
                onChange={handleChange}
                required
              >
                <option value="">Selecciona un municipio</option>
                {municipalities.map((item) => (
                  <option key={item.id_municipio} value={item.id_municipio}>
                    {item.municipio} — {item.departamento}
                  </option>
                ))}
              </select>
              <small>{municipalities.length} municipios disponibles</small>
            </label>

            <label>
              Fecha de inicio *
              <input
                type="date"
                name="fecha_inicio"
                value={form.fecha_inicio}
                onChange={handleChange}
                required
              />
            </label>

            <label>
              Fecha final
              <input
                type="date"
                name="fecha_fin"
                value={form.fecha_fin}
                onChange={handleChange}
                min={form.fecha_inicio || undefined}
              />
            </label>

            <label>
              Codigo externo
              <input
                name="codigo_externo"
                value={form.codigo_externo}
                onChange={handleChange}
                maxLength={100}
                placeholder="Opcional"
              />
            </label>

            <label>
              Estado
              <select name="estado" value={form.estado} onChange={handleChange}>
                <option value="registrado">Registrado</option>
                <option value="activo">Activo</option>
                <option value="finalizado">Finalizado</option>
              </select>
            </label>

            <label>
              Latitud
              <input
                type="number"
                name="latitud"
                value={form.latitud}
                onChange={handleChange}
                min="-90"
                max="90"
                step="any"
                placeholder="Opcional"
              />
            </label>

            <label>
              Longitud
              <input
                type="number"
                name="longitud"
                value={form.longitud}
                onChange={handleChange}
                min="-180"
                max="180"
                step="any"
                placeholder="Opcional"
              />
            </label>

            <label className="field-wide">
              Descripcion
              <textarea
                name="descripcion"
                value={form.descripcion}
                onChange={handleChange}
                rows={3}
                placeholder="Informacion documentada sobre el evento"
              />
            </label>
          </div>

          <div className="form-actions">
            <p className="form-hint">* Campos obligatorios</p>
            <button
              className="primary-button"
              type="submit"
              disabled={loading || saving || types.length === 0 || municipalities.length === 0}
            >
              {saving ? 'Guardando...' : 'Registrar desastre'}
            </button>
          </div>
        </form>
      </section>

      <section className="panel">
        <div className="panel-heading list-heading">
          <div>
            <p className="section-kicker">CONSULTA</p>
            <h2>Eventos registrados</h2>
            <p>Informacion recuperada desde la API.</p>
          </div>

          <div className="list-tools">
            <span className="count">{disasters.length} registros</span>
            <button type="button" onClick={loadData} disabled={loading}>
              {loading ? 'Actualizando...' : 'Actualizar'}
            </button>
          </div>
        </div>

        {loading && <p className="empty-state">Cargando informacion...</p>}

        {!loading && disasters.length === 0 && (
          <p className="empty-state">No hay eventos registrados.</p>
        )}

        {!loading && disasters.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Evento</th>
                  <th>Tipo</th>
                  <th>Ubicacion</th>
                  <th>Fecha inicio</th>
                  <th>Estado</th>
                </tr>
              </thead>
              <tbody>
                {disasters.map((item) => (
                  <tr key={item.id_desastre}>
                    <td>#{item.id_desastre}</td>
                    <td>
                      <strong>{item.nombre}</strong>
                      {item.codigo_externo && (
                        <small className="table-secondary">{item.codigo_externo}</small>
                      )}
                    </td>
                    <td>{item.tipo_desastre || `Tipo ${item.id_tipo_desastre}`}</td>
                    <td>
                      {item.municipio || `Municipio ${item.id_municipio}`}
                      {item.departamento && (
                        <small className="table-secondary">{item.departamento}</small>
                      )}
                    </td>
                    <td>{item.fecha_inicio}</td>
                    <td>
                      <span className={`state state-${item.estado}`}>
                        {item.estado}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <footer className="dashboard-footer">
        Plataforma de visualizacion y analisis de desastres
      </footer>
    </main>
  )
}

export default App
