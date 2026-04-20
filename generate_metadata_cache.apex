// Generate LSC Mobile Metadata Cache — Anonymous Apex
// Creates parent + child records, then calls Connect API to trigger generation

// Step 1: Create parent record
LifeSciMobileMetadataRecord parent = new LifeSciMobileMetadataRecord(
    IntegrationStatus = 'New',
    Status = 'New'
);
insert parent;

// Step 2: Look up profile
Profile pf = [SELECT Id FROM Profile WHERE Name = 'Field Sales Representative' LIMIT 1];

// Step 3: Create child record linked to parent + profile
LifeSciMobileMetadataRecord child = new LifeSciMobileMetadataRecord(
    ParentMobileMetadataRecId = parent.Id,
    ProfileId = pf.Id,
    IntegrationStatus = 'New',
    Status = 'New'
);
insert child;

// Step 4: Update statuses to ValidationCompleted
parent.Status = 'ValidationCompleted';
update parent;

child.Status = 'ValidationCompleted';
update child;

System.debug('Parent Id: ' + parent.Id);
System.debug('Child Id: ' + child.Id);

// Step 5: Call Connect API to trigger metadata generation
HttpRequest req = new HttpRequest();
String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
req.setEndpoint(baseUrl + '/services/data/v66.0/connect/life-sciences/commercial/metadata/actions/generate');
req.setMethod('POST');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');
req.setBody('{"parentMetadataRecordId":"' + parent.Id + '","apiVersion":"64.0","prefix":"lsc4ce"}');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Response Status: ' + res.getStatusCode());
System.debug('Response Body: ' + res.getBody());
