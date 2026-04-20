# LSC Mobile Metadata Cache Generator

Generate the Life Sciences Cloud (LSC) Mobile metadata cache programmatically using Anonymous Apex, without the Admin Console UI.

## How It Works

Salesforce does not allow DML operations and HTTP callouts in the same execution context. This is solved with a `@future(callout=true)` method:

1. DML creates parent and child `LifeSciMobileMetadataRecord` records
2. The `@future` method runs in a separate transaction and calls the Connect API

### Files

| File | Purpose |
|------|---------|
| `generate_metadata_cache.apex` | Anonymous Apex — run on-demand from CLI |
| `Demo_MetadataGeneratorSchedulable.cls` | Schedulable class — contains all the generation logic |
| `Demo_MetadataGeneratorCallout.cls` | `@future(callout=true)` — handles the Connect API call |

## Prerequisites

- Salesforce CLI (`sf`) authenticated to your target org
- Life Sciences Cloud installed in the org
- Permission to create `LifeSciMobileMetadataRecord` records
- Org's My Domain URL added to **Remote Site Settings**

## Setup

### 1. Deploy the Apex Classes

```bash
sf project deploy start --source-dir classes --target-org <your-org-alias>
```

### 2. Run It

`generate_metadata_cache.apex` calls `Demo_MetadataGeneratorSchedulable.execute(null)` directly.

With default profiles (`Field Sales Representative` + `Key Account Manager`):

```bash
sf apex run --file generate_metadata_cache.apex --target-org <your-org-alias>
```

Or run inline with custom profiles:

```bash
sf apex run --target-org <your-org-alias> -f <(echo "new Demo_MetadataGeneratorSchedulable(new List<String>{'Field Sales Representative', 'Key Account Manager', 'Field Medical'}).execute(null);")
```

Or paste this into **Developer Console > Debug > Open Execute Anonymous Window**:

```apex
new Demo_MetadataGeneratorSchedulable().execute(null);
```

To specify custom profiles in Developer Console:

```apex
new Demo_MetadataGeneratorSchedulable(new List<String>{
    'Field Sales Representative',
    'Key Account Manager',
    'Field Medical'
}).execute(null);
```

When run from Anonymous Apex, `UserInfo.getSessionId()` is available and the callout authenticates with the current user's session.

## Monitor Progress

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
| `List has no rows for assignment to SObject` | Profile name doesn't exist | Query `SELECT Name FROM Profile` to find the correct name |
| `Unauthorized endpoint` | Remote Site Setting missing | Add your org's My Domain URL to Remote Site Settings |

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
