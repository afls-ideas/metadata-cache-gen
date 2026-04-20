public class Demo_MetadataGeneratorCallout {
    private static final String API_PATH = '/services/data/v66.0/connect/life-sciences/commercial/metadata/actions/generate';

    @future(callout=true)
    public static void callMetadataEndpoint(Id parentId) {
        String sessionId = UserInfo.getSessionId();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{"parentMetadataRecordId":"' + parentId + '","apiVersion":"66.0","prefix":"lsc4ce"}');

        if (String.isNotBlank(sessionId)) {
            String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();
            req.setEndpoint(baseUrl + API_PATH);
            req.setHeader('Authorization', 'Bearer ' + sessionId);
        } else {
            req.setEndpoint('callout:SelfOrg' + API_PATH);
        }

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Response Status: ' + res.getStatusCode());
        System.debug('Response Body: ' + res.getBody());
    }
}
