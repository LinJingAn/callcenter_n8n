# Quick Fix for Webhook Error

## The Issue
Error: "Unused Respond to Webhook node found in the workflow"

This happens when the webhook is set to `responseMode: "responseNode"` but the Respond node isn't in the execution flow.

## Quick Fix (Easiest - Recommended)

**In n8n UI:**

1. Open your workflow
2. Click on **"Retell Webhook"** node
3. In the node settings, find **"Response Mode"** dropdown
4. Change from **"Respond to Webhook Node"** to **"Last Node"** (or remove the setting entirely)
5. **Delete the "Respond OK" node** (it's no longer needed)
6. Save workflow

The webhook will now respond automatically with a success status, and you don't need the Respond node anymore.

## Alternative Fix (If you want to keep custom response)

If you want to keep the custom response message:

1. Click on **"Retell Webhook"** node
2. Keep **"Response Mode"** as **"Respond to Webhook Node"**
3. In the workflow canvas:
   - **Disconnect "Respond OK" from "Retell Webhook"** (remove the parallel connection)
   - **Connect "DB - Update CRM Sync" → "Respond OK"** (connect at the end)
4. Save workflow

**Note:** This means the webhook will only respond AFTER all processing is complete (slower).

---

## Which Fix to Use?

- **Use Quick Fix** if you just need the webhook to acknowledge receipt
- **Use Alternative Fix** if you need a custom response message after processing

For most webhooks, the Quick Fix (auto-respond) is better because it responds immediately.
