// Step 2: Call Connect API to trigger metadata generation
String parentId = '<REPLACE_WITH_PARENT_ID>';

HttpRequest req = new HttpRequest();
String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
req.setEndpoint(baseUrl + '/services/data/v66.0/connect/life-sciences/commercial/metadata/actions/generate');
req.setMethod('POST');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');
req.setBody('{"parentMetadataRecordId":"' + parentId + '","apiVersion":"64.0","prefix":"lsc4ce"}');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Response Status: ' + res.getStatusCode());
System.debug('Response Body: ' + res.getBody());
