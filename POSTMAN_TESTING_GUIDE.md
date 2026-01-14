# Postman Testing Guide - Call Center & WhatsApp Webhooks

This guide will help you test both webhook endpoints using Postman for your testing video.

---

## 📋 Prerequisites

1. **n8n Workflow Activated**: Make sure the workflow is activated in n8n
2. **Get Webhook URLs**: Copy the webhook URLs from n8n:
   - For Retell: Copy the webhook URL from the "Retell Webhook" node
   - For WhatsApp: Copy the webhook URL from the "WhatsApp Webhook" node
3. **Postman Installed**: Have Postman desktop app or web version ready

---

## 🔵 Testing Call Center Webhook (Retell)

### Endpoint Information

**Method:** `POST`  
**URL Format:** `https://your-n8n-instance.com/webhook/retell-webhook`  
**Headers:** `Content-Type: application/json`

### Test Case 1: Call Completed Event (Hot Lead)

This will trigger the full Call Center flow with a hot lead.

**Request Configuration:**
- Method: `POST`
- URL: Your Retell webhook URL from n8n
- Headers:
  ```
  Content-Type: application/json
  ```
- Body (raw JSON):

```json
{
  "event": "call.completed",
  "agent_id": "retell_agent_123",
  "call_id": "call_test_001",
  "timestamp": "2026-01-13T14:30:00Z",
  "call_status": "completed",
  "call_duration_seconds": 245,
  "recording_url": "https://retell.ai/recordings/test_call_001.mp3",
  "caller": {
    "name": "Juan Pérez",
    "phone": "+34600123456",
    "email": "juan.perez@example.com"
  },
  "conversation": {
    "language": "es",
    "transcript": "Hola, estoy interesado en comprar un departamento en el centro de Madrid. Mi presupuesto es de 200.000 euros y necesito algo urgente antes de final de mes.",
    "summary": "Cliente interesado en comprar departamento en centro de Madrid, presupuesto 200.000€, urgencia alta."
  },
  "extracted_data": {
    "intent": "compra",
    "property_type": "departamento",
    "zone": "Centro",
    "urgency": "alta",
    "lead_temperature": "caliente",
    "budget": 200000
  },
  "ai_metadata": {
    "model": "GPT-4.1-mini",
    "confidence_score": 0.92
  }
}
```

**Expected Response:**
```json
{
  "status": "received",
  "call_id": "call_test_001"
}
```

**What Should Happen:**
- Lead scored as HOT (score ≥ 60)
- Contact created/updated in GoHighLevel
- Note added in GoHighLevel
- Urgent task created in GoHighLevel
- Data saved in Supabase (if configured)

---

### Test Case 2: Call Completed Event (Warm Lead)

**Body:**

```json
{
  "event": "call.completed",
  "agent_id": "retell_agent_123",
  "call_id": "call_test_002",
  "timestamp": "2026-01-13T15:00:00Z",
  "call_status": "completed",
  "call_duration_seconds": 120,
  "recording_url": "https://retell.ai/recordings/test_call_002.mp3",
  "caller": {
    "name": "María González",
    "phone": "+34600555666",
    "email": "maria.gonzalez@example.com"
  },
  "conversation": {
    "language": "es",
    "transcript": "Estoy buscando un alquiler en zona norte, algo de 2 habitaciones.",
    "summary": "Cliente busca alquiler 2 habitaciones zona norte."
  },
  "extracted_data": {
    "intent": "alquiler",
    "property_type": "departamento",
    "zone": "Norte",
    "urgency": "media",
    "lead_temperature": "tibio",
    "budget": 1200
  },
  "ai_metadata": {
    "model": "GPT-4.1-mini",
    "confidence_score": 0.78
  }
}
```

**Expected Response:**
```json
{
  "status": "received",
  "call_id": "call_test_002"
}
```

**What Should Happen:**
- Lead scored as WARM (score ≥ 30)
- Contact created/updated in GoHighLevel
- Note added in GoHighLevel
- No urgent task (only for hot leads)

---

### Test Case 3: Call Started Event (Should Be Logged Only)

**Body:**

```json
{
  "event": "call.started",
  "agent_id": "retell_agent_123",
  "call_id": "call_test_003",
  "timestamp": "2026-01-13T16:00:00Z",
  "call_status": "in-progress"
}
```

**Expected Response:**
```json
{
  "status": "received",
  "call_id": "call_test_003"
}
```

**What Should Happen:**
- Event logged to console
- No processing (workflow only processes call.completed)

---

## 🟢 Testing WhatsApp Webhook (Evolution API)

### Endpoint Information

**Method:** `POST`  
**URL Format:** `https://your-n8n-instance.com/webhook/whatsapp-evolution`  
**Headers:** `Content-Type: application/json`

### Test Case 1: Text Message (Simple Query)

**Request Configuration:**
- Method: `POST`
- URL: Your WhatsApp webhook URL from n8n
- Headers:
  ```
  Content-Type: application/json
  ```
- Body (raw JSON):

```json
{
  "event": "messages.upsert",
  "instance": "test_instance",
  "data": {
    "key": {
      "remoteJid": "5491155551234@s.whatsapp.net",
      "fromMe": false,
      "id": "3A7585FF88FE90691914"
    },
    "pushName": "Carlos Martínez",
    "status": "SERVER_ACK",
    "message": {
      "conversation": "Hola, busco un departamento de 2 habitaciones para alquilar en Palermo"
    },
    "messageType": "conversation",
    "messageTimestamp": 1753982785,
    "instanceId": "29aabc1a-dad8-4fa3-bddb-7322056fca7f",
    "source": "ios"
  },
  "destination": "https://your-n8n.com/webhook/whatsapp-evolution",
  "date_time": "2026-01-13T14:26:25.512Z",
  "sender": "5491155551234@s.whatsapp.net",
  "server_url": "https://evolution-api.example.com",
  "apikey": "test-api-key-123",
  "instance": "test_instance"
}
```

**What Should Happen:**
- Message normalized
- Lead upserted in database
- Property search performed
- AI generates response
- Response sent back via Evolution API (if configured)

---

### Test Case 2: Extended Text Message

**Body:**

```json
{
  "event": "messages.upsert",
  "instance": "test_instance",
  "data": {
    "key": {
      "remoteJid": "5491166678899@s.whatsapp.net",
      "fromMe": false,
      "id": "4B8696GG99GF01703025"
    },
    "pushName": "Ana López",
    "status": "SERVER_ACK",
    "message": {
      "extendedTextMessage": {
        "text": "Hola, me llamo Ana López. Mi email es ana.lopez@example.com. Busco comprar una casa en Belgrano, presupuesto máximo 350.000 USD, con al menos 3 habitaciones."
      }
    },
    "messageType": "extendedTextMessage",
    "messageTimestamp": 1753983000,
    "instanceId": "29aabc1a-dad8-4fa3-bddb-7322056fca7f",
    "source": "android"
  },
  "destination": "https://your-n8n.com/webhook/whatsapp-evolution",
  "date_time": "2026-01-13T14:30:00.000Z",
  "sender": "5491166678899@s.whatsapp.net",
  "server_url": "https://evolution-api.example.com",
  "apikey": "test-api-key-123",
  "instance": "test_instance"
}
```

**What Should Happen:**
- Name and email extracted
- Lead updated with email
- Property search with filters (casa, Belgrano, 3+ habitaciones, ≤350k)
- AI response generated
- Lead synced to GoHighLevel (if new)

---

### Test Case 3: Audio Message (Will Need Base64 Audio)

**Body:**

```json
{
  "event": "messages.upsert",
  "instance": "test_instance",
  "data": {
    "key": {
      "remoteJid": "5491177789900@s.whatsapp.net",
      "fromMe": false,
      "id": "5C97A7HH00HG12814136"
    },
    "pushName": "Roberto Silva",
    "status": "SERVER_ACK",
    "message": {
      "audioMessage": {
        "mimetype": "audio/ogg; codecs=opus",
        "seconds": 10,
        "ptt": false
      }
    },
    "messageType": "audioMessage",
    "messageTimestamp": 1753983200,
    "instanceId": "29aabc1a-dad8-4fa3-bddb-7322056fca7f",
    "source": "ios"
  },
  "destination": "https://your-n8n.com/webhook/whatsapp-evolution",
  "date_time": "2026-01-13T14:33:20.000Z",
  "sender": "5491177789900@s.whatsapp.net",
  "server_url": "https://evolution-api.example.com",
  "apikey": "test-api-key-123",
  "instance": "test_instance"
}
```

**Note:** For audio messages, the workflow will try to fetch the audio file from Evolution API. In a real scenario, Evolution API would provide the actual audio data. For testing, this may fail if Evolution API is not configured, but you can still test the routing logic.

---

### Test Case 4: Image Message (Will Be Skipped)

**Body:**

```json
{
  "event": "messages.upsert",
  "instance": "test_instance",
  "data": {
    "key": {
      "remoteJid": "5491188890011@s.whatsapp.net",
      "fromMe": false,
      "id": "6D08B8II11IH13925247"
    },
    "pushName": "Laura Fernández",
    "status": "SERVER_ACK",
    "message": {
      "imageMessage": {
        "mimetype": "image/jpeg",
        "caption": "Esta es la zona que me interesa"
      }
    },
    "messageType": "imageMessage",
    "messageTimestamp": 1753983400,
    "instanceId": "29aabc1a-dad8-4fa3-bddb-7322056fca7f",
    "source": "android"
  },
  "destination": "https://your-n8n.com/webhook/whatsapp-evolution",
  "date_time": "2026-01-13T14:36:40.000Z",
  "sender": "5491188890011@s.whatsapp.net",
  "server_url": "https://evolution-api.example.com",
  "apikey": "test-api-key-123",
  "instance": "test_instance"
}
```

**What Should Happen:**
- Content type detected as "image"
- Routed to "Other Content (Log)" node
- Logged to console
- No further processing

---

## 📝 Step-by-Step Postman Setup

### Step 1: Create a New Collection

1. Open Postman
2. Click "New" → "Collection"
3. Name it "Call Center & WhatsApp Testing"

### Step 2: Add Call Center Requests

1. Right-click collection → "Add Request"
2. Name: "Call Center - Hot Lead"
3. Method: POST
4. URL: Paste your Retell webhook URL
5. Headers tab: Add `Content-Type: application/json`
6. Body tab: Select "raw" → "JSON"
7. Paste the Test Case 1 JSON from above
8. Click "Save"

Repeat for:
- "Call Center - Warm Lead" (Test Case 2)
- "Call Center - Call Started" (Test Case 3)

### Step 3: Add WhatsApp Requests

1. Right-click collection → "Add Request"
2. Name: "WhatsApp - Text Message"
3. Method: POST
4. URL: Paste your WhatsApp webhook URL
5. Headers tab: Add `Content-Type: application/json`
6. Body tab: Select "raw" → "JSON"
7. Paste the Test Case 1 JSON from above
8. Click "Save"

Repeat for:
- "WhatsApp - Extended Text"
- "WhatsApp - Audio Message"
- "WhatsApp - Image Message"

### Step 4: Testing

1. Make sure n8n workflow is **ACTIVATED**
2. In Postman, select a request
3. Click "Send"
4. Check response (should return status)
5. Check n8n execution log to see workflow execution
6. Check database (if configured) to verify data

---

## 🎥 Tips for Testing Video

1. **Start with Simple Tests**: Begin with Call Center - Hot Lead and WhatsApp - Text Message
2. **Show n8n Execution**: Have n8n execution log visible to show the workflow running
3. **Show Response**: Display Postman response showing successful webhook receipt
4. **Show Database (if configured)**: If credentials are set, show database records being created
5. **Test Different Scenarios**: Show hot vs warm lead routing, text vs audio processing
6. **Show Error Handling**: Test with invalid data to show how workflow handles errors

---

## ⚠️ Important Notes for Testing

1. **Credentials Not Required for Basic Testing**: The workflow will process the webhook even without credentials, but database operations will fail. You can still see the workflow execution in n8n.

2. **Expected Failures Without Credentials**:
   - PostgreSQL nodes will fail (credentials needed)
   - Redis nodes may fail (credentials needed)
   - OpenAI nodes will fail (credentials needed)
   - GoHighLevel nodes will fail (API key needed)

3. **What Will Work Without Credentials**:
   - Webhook receipt
   - Data normalization
   - Lead scoring calculation
   - Routing logic
   - Console logging

4. **For Full Testing**: Configure all credentials first, then test end-to-end.

---

## 📋 Quick Reference: Webhook URLs

**To get your webhook URLs:**

1. Open n8n workflow
2. Click on "Retell Webhook" node
3. Copy the webhook URL (looks like: `https://your-instance.com/webhook/retell-webhook`)
4. Repeat for "WhatsApp Webhook" node

**Alternative method:**
- Go to n8n Settings → Webhooks
- Find your webhook URLs there

---

Good luck with your testing video! 🎬
