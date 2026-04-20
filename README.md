# LSC Mobile Metadata Cache Generator

Generate the Life Sciences Cloud (LSC) Mobile metadata cache programmatically using Anonymous Apex, without the Admin Console UI.

## How It Works

Salesforce does not allow DML operations and HTTP callouts in the same execution context. This is solved with a `@future(callout=true)` method:

1. **`generate_metadata_cache.apex`** (Anonymous Apex) — Creates parent and child `LifeSciMobileMetadataRecord` records, then calls the `@future` method
2. **`MetadataGeneratorCallout.cls`** (Apex Class) — Contains the `@future(callout=true)` method that calls the Connect API to trigger generation

The anonymous Apex does the DML, then hands off the parent ID to the `@future` method which runs in a separate transaction and makes the callout.

## Prerequisites

- Salesforce CLI (`sf`) authenticated to your target org
- Life Sciences Cloud installed in the org
- Permission to create `LifeSciMobileMetadataRecord` records
- Org's My Domain URL added to **Remote Site Settings**

## Setup

### 1. Deploy the Apex Class

```bash
sf project deploy start --source-dir classes --target-org <your-org-alias>
```

### 2. Set the Profile Name

Edit `generate_metadata_cache.apex` and set the profile name for your org:

```apex
Profile pf = [SELECT Id FROM Profile WHERE Name = 'Field Sales Representative' LIMIT 1];
```

Common profile names: `Field Sales Representative`, `Medical Sales Representative`, `Key Account Manager`, `Field Medical`.

### 3. Run It

```bash
sf apex run --file generate_metadata_cache.apex --target-org <your-org-alias>
```

The debug output will show the parent and child record IDs, and confirm the future callout was enqueued.

## Monitor Progress

```sql
SELECT Id, Name, Status, IntegrationStatus, IntegrationErrorCode, IntegrationErrorMessage
FROM LifeSciMobileMetadataRecord
ORDER BY CreatedDate DESC
LIMIT 10
```

- **Success:** `Status = 'Active'` and `IntegrationStatus = 'Ok'`
- **Failed:** Check `IntegrationErrorCode` and `IntegrationErrorMessage`

## Important Note on `@future` and Session ID

`UserInfo.getSessionId()` returns `null` in most async contexts (Batch, Queueable, Schedulable). However, `@future` methods called from **Anonymous Apex** do retain the session ID from the calling context. This is why this approach works — the anonymous Apex session is propagated to the `@future` method.

If you call `MetadataGeneratorCallout.callMetadataEndpoint()` from a Schedulable or Batch class, the session ID will be `null` and the callout will fail with an authorization error.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `List has no rows for assignment to SObject` | Profile name doesn't exist | Query `SELECT Name FROM Profile` to find the correct name |
| `Unauthorized endpoint` | Remote Site Setting missing | Add your org's My Domain URL to Remote Site Settings |
| Response `401` | Session ID is null (async context) | Run from Anonymous Apex, not from Schedulable/Batch |

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
