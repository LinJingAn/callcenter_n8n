-- ============================================================
-- INMOBILIARIA AI SYSTEM - SUPABASE SCHEMA
-- Version: 2.0
-- Database: Supabase (PostgreSQL)
-- ============================================================

-- Enable UUID extension (Supabase has this by default)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. LEADS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS leads (
    id SERIAL PRIMARY KEY,
    
    -- Identification
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255),
    name VARCHAR(255),
    
    -- Source tracking
    source VARCHAR(50) NOT NULL DEFAULT 'unknown',
    first_channel VARCHAR(50),
    
    -- Lead scoring
    temperature VARCHAR(20) DEFAULT 'cold',
    score INTEGER DEFAULT 0,
    
    -- Property interests
    intent VARCHAR(50),
    property_types TEXT[],
    preferred_zones TEXT[],
    budget_min NUMERIC(15,2),
    budget_max NUMERIC(15,2),
    bedrooms_min INTEGER,
    
    -- Engagement
    total_interactions INTEGER DEFAULT 1,
    last_interaction_at TIMESTAMPTZ DEFAULT NOW(),
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- CRM sync
    crm_synced BOOLEAN DEFAULT FALSE,
    crm_id VARCHAR(255),
    crm_sync_at TIMESTAMPTZ,
    crm_sync_error TEXT,
    
    -- Metadata
    tags TEXT[],
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_leads_phone ON leads(phone);
CREATE INDEX IF NOT EXISTS idx_leads_email ON leads(email);
CREATE INDEX IF NOT EXISTS idx_leads_temperature ON leads(temperature);
CREATE INDEX IF NOT EXISTS idx_leads_crm_synced ON leads(crm_synced) WHERE crm_synced = FALSE;

-- ============================================================
-- 2. INTERACTIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS interactions (
    id SERIAL PRIMARY KEY,
    
    -- Lead reference
    lead_id INTEGER REFERENCES leads(id) ON DELETE SET NULL,
    phone VARCHAR(20) NOT NULL,
    
    -- Interaction details
    channel VARCHAR(50) NOT NULL,
    direction VARCHAR(20) NOT NULL DEFAULT 'inbound',
    
    -- Content
    message_content TEXT,
    ai_response TEXT,
    transcript TEXT,
    summary TEXT,
    recording_url TEXT,
    
    -- Call-specific
    call_duration_seconds INTEGER,
    call_status VARCHAR(50),
    
    -- Classification
    intent_detected VARCHAR(100),
    temperature_at_interaction VARCHAR(20),
    confidence_score NUMERIC(3,2),
    
    -- Extracted data
    extracted_data JSONB,
    
    -- Timestamps
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_interactions_lead ON interactions(lead_id);
CREATE INDEX IF NOT EXISTS idx_interactions_phone ON interactions(phone);
CREATE INDEX IF NOT EXISTS idx_interactions_channel ON interactions(channel);
CREATE INDEX IF NOT EXISTS idx_interactions_created ON interactions(created_at DESC);

-- ============================================================
-- 3. PROPERTIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS properties (
    id SERIAL PRIMARY KEY,
    
    -- External references
    crm_id VARCHAR(255) UNIQUE,
    external_url TEXT,
    
    -- Basic info
    titulo VARCHAR(500),
    descripcion TEXT,
    
    -- Classification
    operacion VARCHAR(50),
    tipo VARCHAR(100),
    
    -- Location
    pais VARCHAR(100) DEFAULT 'Argentina',
    provincia VARCHAR(100),
    ciudad VARCHAR(255),
    barrio VARCHAR(255),
    direccion TEXT,
    codigo_postal VARCHAR(20),
    latitud NUMERIC(10, 7),
    longitud NUMERIC(10, 7),
    
    -- Pricing
    precio NUMERIC(15, 2),
    moneda VARCHAR(10) DEFAULT 'USD',
    expensas NUMERIC(15, 2),
    
    -- Features
    dormitorios INTEGER,
    banos INTEGER,
    ambientes INTEGER,
    m2_cubiertos NUMERIC(10, 2),
    m2_totales NUMERIC(10, 2),
    cochera BOOLEAN DEFAULT FALSE,
    amenities TEXT[],
    
    -- Media
    imagen_principal TEXT,
    imagenes TEXT[],
    video_url TEXT,
    tour_virtual_url TEXT,
    
    -- Status
    estado VARCHAR(50) DEFAULT 'disponible',
    destacado BOOLEAN DEFAULT FALSE,
    
    -- Sync
    source VARCHAR(100),
    last_sync_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_properties_operacion ON properties(operacion);
CREATE INDEX IF NOT EXISTS idx_properties_tipo ON properties(tipo);
CREATE INDEX IF NOT EXISTS idx_properties_ciudad ON properties(ciudad);
CREATE INDEX IF NOT EXISTS idx_properties_barrio ON properties(barrio);
CREATE INDEX IF NOT EXISTS idx_properties_precio ON properties(precio);
CREATE INDEX IF NOT EXISTS idx_properties_estado ON properties(estado);
CREATE INDEX IF NOT EXISTS idx_properties_destacado ON properties(destacado) WHERE destacado = TRUE;

-- Full text search
CREATE INDEX IF NOT EXISTS idx_properties_fts ON properties 
    USING GIN (to_tsvector('spanish', 
        COALESCE(titulo, '') || ' ' || 
        COALESCE(descripcion, '') || ' ' || 
        COALESCE(barrio, '') || ' ' || 
        COALESCE(ciudad, '')
    ));

-- ============================================================
-- 4. HELPER FUNCTIONS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS trigger_leads_updated ON leads;
CREATE TRIGGER trigger_leads_updated
    BEFORE UPDATE ON leads
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trigger_properties_updated ON properties;
CREATE TRIGGER trigger_properties_updated
    BEFORE UPDATE ON properties
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 5. ROW LEVEL SECURITY (Optional - for Supabase)
-- ============================================================

-- Enable RLS (uncomment if using Supabase Auth)
-- ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE properties ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6. SAMPLE DATA (Optional - for testing)
-- ============================================================

-- Insert sample properties for testing
INSERT INTO properties (crm_id, titulo, operacion, tipo, ciudad, barrio, precio, moneda, dormitorios, banos, m2_cubiertos, estado, destacado)
VALUES 
    ('PROP001', 'Departamento moderno en Palermo', 'venta', 'departamento', 'Buenos Aires', 'Palermo', 185000, 'USD', 2, 1, 65, 'disponible', true),
    ('PROP002', 'Casa con jardín en Belgrano', 'venta', 'casa', 'Buenos Aires', 'Belgrano', 320000, 'USD', 4, 3, 180, 'disponible', true),
    ('PROP003', 'Monoambiente en Recoleta', 'alquiler', 'departamento', 'Buenos Aires', 'Recoleta', 800, 'USD', 1, 1, 35, 'disponible', false),
    ('PROP004', 'PH reciclado en Villa Crespo', 'venta', 'ph', 'Buenos Aires', 'Villa Crespo', 145000, 'USD', 3, 2, 95, 'disponible', false),
    ('PROP005', 'Oficina en Microcentro', 'alquiler', 'oficina', 'Buenos Aires', 'Microcentro', 1200, 'USD', 0, 1, 50, 'disponible', false)
ON CONFLICT (crm_id) DO NOTHING;

-- ============================================================
-- 7. VIEWS
-- ============================================================

-- Hot leads view
CREATE OR REPLACE VIEW v_hot_leads AS
SELECT 
    l.*,
    i.channel as last_channel,
    i.summary as last_summary,
    i.created_at as last_interaction_date
FROM leads l
LEFT JOIN LATERAL (
    SELECT channel, summary, created_at
    FROM interactions 
    WHERE lead_id = l.id 
    ORDER BY created_at DESC 
    LIMIT 1
) i ON TRUE
WHERE l.temperature = 'hot';

-- Pending CRM sync view
CREATE OR REPLACE VIEW v_pending_crm_sync AS
SELECT * FROM leads
WHERE crm_synced = FALSE
ORDER BY 
    CASE temperature 
        WHEN 'hot' THEN 1 
        WHEN 'warm' THEN 2 
        ELSE 3 
    END,
    last_interaction_at DESC;
