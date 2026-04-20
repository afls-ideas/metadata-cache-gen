# LSC Mobile Metadata Cache Generator

Generate the Life Sciences Cloud (LSC) Mobile metadata cache programmatically using Anonymous Apex or a scheduled job, without the Admin Console UI.

## How It Works

Salesforce does not allow DML operations and HTTP callouts in the same execution context. This is solved with a `@future(callout=true)` method:

1. DML creates parent and child `LifeSciMobileMetadataRecord` records
2. The `@future` method runs in a separate transaction and calls the Connect API

### Files

| File | Purpose |
|------|---------|
| `generate_metadata_cache.apex` | Anonymous Apex — run on-demand from CLI |
| `Demo_MetadataGeneratorSchedulable.cls` | Schedulable class — run on a cron schedule |
| `Demo_MetadataGeneratorCallout.cls` | `@future(callout=true)` — handles the Connect API call |

## Prerequisites

- Salesforce CLI (`sf`) authenticated to your target org
- Life Sciences Cloud installed in the org
- Permission to create `LifeSciMobileMetadataRecord` records
- Org's My Domain URL added to **Remote Site Settings**

## Setup

### Deploy the Apex Classes

```bash
sf project deploy start --source-dir classes --target-org <your-org-alias>
```

## Option 1: Run On-Demand (Anonymous Apex)

`generate_metadata_cache.apex` calls `Demo_MetadataGeneratorSchedulable.execute(null)` directly, reusing the same logic as the scheduled job.

With default profiles:

```bash
sf apex run --file generate_metadata_cache.apex --target-org <your-org-alias>
```

Or run inline with custom profiles:

```bash
sf apex run --target-org <your-org-alias> -f <(echo "new Demo_MetadataGeneratorSchedulable(new List<String>{'Field Sales Representative', 'Key Account Manager', 'Field Medical'}).execute(null);")
```

When run from Anonymous Apex, `UserInfo.getSessionId()` is available and the callout authenticates with the current user's session.

## Option 2: Schedule It (Schedulable)

The Schedulable class requires a **Named Credential** called `SelfOrg` because `UserInfo.getSessionId()` returns `null` in all async contexts (Schedulable, Batch, Queueable).

### Create the Named Credential

1. **Setup > Named Credentials > New Named Credential**
2. Configure:
   - **Label:** `SelfOrg`
   - **Name:** `SelfOrg`
   - **URL:** Your org's My Domain URL (e.g., `https://yourorg.my.salesforce.com`)
   - **Identity Type:** Named Principal
   - **Authentication Protocol:** OAuth 2.0
   - **Authentication Provider:** Create a Connected App with `full` and `api` scopes, then reference it here
   - **Scope:** `full api`

### Schedule the Job

With default profiles (`Field Sales Representative` + `Key Account Manager`):

```apex
System.schedule('Metadata Cache Gen', '0 0 2 ? * SUN', new Demo_MetadataGeneratorSchedulable());
```

With custom profiles:

```apex
System.schedule('Metadata Cache Gen', '0 0 2 ? * SUN',
    new Demo_MetadataGeneratorSchedulable(new List<String>{
        'Field Sales Representative',
        'Key Account Manager',
        'Field Medical'
    })
);
```

The cron expression `0 0 2 ? * SUN` runs every Sunday at 2:00 AM. Adjust as needed.

### Unschedule

```apex
for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Metadata Cache Gen']) {
    System.abortJob(ct.Id);
}
```

## Monitor Progress

```sql
SELECT Id, Name, Status, IntegrationStatus, IntegrationErrorCode, IntegrationErrorMessage
FROM LifeSciMobileMetadataRecord
ORDER BY CreatedDate DESC
LIMIT 10
```

- **Success:** `Status = 'Active'` and `IntegrationStatus = 'Ok'`
- **Failed:** Check `IntegrationErrorCode` and `IntegrationErrorMessage`

## Authentication Summary

| Execution Context | Auth Method | Named Credential Required? |
|-------------------|-------------|---------------------------|
| Anonymous Apex | `UserInfo.getSessionId()` | No |
| Schedulable / Batch / Queueable | Named Credential (`SelfOrg`) | Yes |

The `Demo_MetadataGeneratorCallout` class automatically detects the context: if a session ID is available, it uses it directly; otherwise, it falls back to `callout:SelfOrg`.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `List has no rows for assignment to SObject` | Profile name doesn't exist | Query `SELECT Name FROM Profile` to find the correct name |
| `Unauthorized endpoint` | Remote Site Setting missing | Add your org's My Domain URL to Remote Site Settings |
| Response `401` | Session ID is null in async context | Set up the `SelfOrg` Named Credential |
| `Could not find named credential: SelfOrg` | Named Credential not configured | Follow the Named Credential setup above |

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
