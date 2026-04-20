# LSC Mobile Metadata Cache Generator

Generate the Life Sciences Cloud (LSC) Mobile metadata cache programmatically using Anonymous Apex, without the Admin Console UI.

## Why Two Scripts?

Salesforce does not allow DML operations and HTTP callouts in the same execution context. The process is split into two steps:

1. **Step 1** — Create `LifeSciMobileMetadataRecord` parent and child records (DML)
2. **Step 2** — Call the Connect API to trigger metadata generation (callout)

A single-file version (`generate_metadata_cache.apex`) is included for reference, but it will fail with `System.CalloutException: You have uncommitted work pending` if run as-is.

## Prerequisites

- Salesforce CLI (`sf`) authenticated to your target org
- The org must have Life Sciences Cloud installed
- Your user must have permission to create `LifeSciMobileMetadataRecord` records
- The org's My Domain URL must be added to **Remote Site Settings** (or use a Named Credential)

## Usage

### Step 1: Create Records

Edit `step1_create_records.apex` to set the correct profile name for your org:

```apex
Profile pf = [SELECT Id FROM Profile WHERE Name = 'Field Sales Representative' LIMIT 1];
```

Common profile names: `Field Sales Representative`, `Medical Sales Representative`, `Key Account Manager`, `Field Medical`.

Run it:

```bash
sf apex run --file step1_create_records.apex --target-org <your-org-alias>
```

Copy the `PARENT_ID` from the debug output.

### Step 2: Trigger Generation

Edit `step2_trigger_generation.apex` and replace `<REPLACE_WITH_PARENT_ID>` with the parent ID from step 1:

```apex
String parentId = '<REPLACE_WITH_PARENT_ID>';
```

Run it:

```bash
sf apex run --file step2_trigger_generation.apex --target-org <your-org-alias>
```

A `202` response with `"Task enqueued for metadata cache generation."` means success.

### Monitor Progress

```sql
SELECT Id, Name, Status, IntegrationStatus, IntegrationErrorCode, IntegrationErrorMessage
FROM LifeSciMobileMetadataRecord
ORDER BY CreatedDate DESC
LIMIT 10
```

- **Success:** `Status = 'Active'` and `IntegrationStatus = 'Ok'`
- **Failed:** Check `IntegrationErrorCode` and `IntegrationErrorMessage`

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `List has no rows for assignment to SObject` | Profile name doesn't exist in the org | Query `SELECT Name FROM Profile` to find the correct name |
| `You have uncommitted work pending` | DML and callout in the same context | Use the two-step approach |
| `Unauthorized endpoint` | Remote Site Setting missing | Add your org's My Domain URL to Remote Site Settings |
| `UserInfo.getSessionId()` returns null | Running in async context (`@future`, batch, etc.) | Use synchronous Anonymous Apex instead |

## API Reference

**Connect API Endpoint:**
```
POST /services/data/v66.0/connect/life-sciences/commercial/metadata/actions/generate
```

**Request Body:**
```json
{
  "parentMetadataRecordId": "<18-char-record-id>",
  "apiVersion": "66.0",
  "prefix": "lsc4ce"
}
```
