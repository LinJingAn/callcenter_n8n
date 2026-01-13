# Sistema Call Center IA + WhatsApp

## Arquitectura Final: 2 Workflows

```
┌─────────────────────────────────────────────────────────────────┐
│                        WORKFLOW 1                                │
│              CallCenter_Retell_GHL.json                         │
│                                                                  │
│  Retell Webhook → Event Router → Normalize → Score Lead         │
│       ↓                                                         │
│  DB Log Call → DB Upsert Lead → Prepare CRM Payload             │
│       ↓                                                         │
│  Route by Classification (Hot/Warm/Cold)                        │
│       ↓                                                         │
│  GHL Create Contact → GHL Add Note → [Hot: Create Task]         │
│       ↓                                                         │
│  DB Update CRM Sync                                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        WORKFLOW 2                                │
│                    AGENTEDEWSP.json                              │
│                                                                  │
│  Evolution Webhook → Filter → Normalize → Buffer (Redis)        │
│       ↓                                                         │
│  Debounce Check → [Wait 2s if needed]                           │
│       ↓                                                         │
│  Split Messages → Parse JSON → Route by Content Type            │
│       ↓                                                         │
│  [Audio: Get → Convert → Transcribe]  [Text: Direct]            │
│       ↓                                                         │
│  Merge → Sort → Aggregate → Prepare for Processing              │
│       ↓                                                         │
│  DB Upsert Lead → Build Context → Parse Filters                 │
│       ↓                                                         │
│  DB Search Properties → Build Property Context                  │
│       ↓                                                         │
│  AI Agent (GPT-4o-mini + Chat Memory)                           │
│       ↓                                                         │
│  DB Log Interaction → Send WhatsApp Response                    │
│       ↓                                                         │
│  [If new lead: GHL Create Contact → DB Update CRM]              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Archivos del Sistema

| Archivo | Descripción |
|---------|-------------|
| `CallCenter_Retell_GHL.json` | Workflow de Call Center (Retell → GHL) |
| `AGENTEDEWSP.json` | Workflow de WhatsApp (Evolution API → GHL) |
| `supabase_schema.sql` | Esquema de base de datos para Supabase |

---

## Credenciales Necesarias

### En n8n:

1. **Supabase Postgres**
   - Host: `db.xxxxx.supabase.co`
   - Port: `5432`
   - Database: `postgres`
   - User: `postgres`
   - Password: (desde Supabase dashboard)

2. **Redis**
   - Host, Port, Password

3. **OpenAI API**
   - API Key

### Variables de Entorno (n8n):

```
GHL_API_KEY=xxx
GHL_LOCATION_ID=xxx
```

---

## Lead Scoring

| Score | Temperatura | Acción en GHL |
|-------|-------------|---------------|
| ≥60 | 🔥 Hot | Contact + Note + Urgent Task |
| ≥30 | 🌡️ Warm | Contact + Note |
| <30 | ❄️ Cold | Contact + Note |

### Factores de Scoring:

- Intent (compra/alquiler): +15-25
- Urgencia alta: +25
- Email proporcionado: +10
- Presupuesto definido: +10
- Llamada >3 min: +15
- Confianza AI alta: +5

---

## Configuración

### 1. Supabase
1. Crear proyecto en Supabase
2. Ejecutar `supabase_schema.sql` en SQL Editor
3. Copiar credenciales de conexión

### 2. n8n
1. Importar `CallCenter_Retell_GHL.json`
2. Importar `AGENTEDEWSP.json`
3. Configurar credenciales:
   - Supabase Postgres
   - Redis
   - OpenAI
4. Agregar variables de entorno GHL
5. Activar workflows

### 3. Retell
- Configurar webhook: `https://tu-n8n/webhook/retell-webhook`

### 4. Evolution API
- Configurar webhook: `https://tu-n8n/webhook/whatsapp-evolution`
- Events: `messages.upsert`

---

## Nodos que Requieren Configuración

### CallCenter_Retell_GHL.json:
- `DB - Log Call` → Supabase Postgres credential
- `DB - Upsert Lead` → Supabase Postgres credential
- `DB - Update CRM Sync` → Supabase Postgres credential
- `GHL - Create/Update Contact (Hot/Warm/Cold)` → GHL_API_KEY env var
- `GHL - Add Note (Hot/Warm/Cold)` → GHL_API_KEY env var
- `GHL - Create Urgent Task (Hot)` → GHL_API_KEY env var

### AGENTEDEWSP.json:
- `Push to Buffer` → Redis credential
- `Get Buffer` → Redis credential
- `Clear Buffer` → Redis credential
- `Transcribe Audio` → OpenAI credential
- `OpenAI GPT-4o-mini` → OpenAI credential
- `Postgres Chat Memory` → Supabase Postgres credential
- `DB - Upsert Lead` → Supabase Postgres credential
- `DB - Search Properties` → Supabase Postgres credential
- `DB - Log Interaction` → Supabase Postgres credential
- `GHL - Create Contact` → GHL_API_KEY env var
- `DB - Update CRM ID` → Supabase Postgres credential

---

## Autor
Lin Jing An - Enero 2026
