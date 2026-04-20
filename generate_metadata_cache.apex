// Generate LSC Mobile Metadata Cache — Single-step Anonymous Apex
// Requires: MetadataGeneratorCallout class deployed to the org

LifeSciMobileMetadataRecord parent = new LifeSciMobileMetadataRecord(
    IntegrationStatus = 'New',
    Status = 'New'
);
insert parent;

Profile pf = [SELECT Id FROM Profile WHERE Name = 'Field Sales Representative' LIMIT 1];

LifeSciMobileMetadataRecord child = new LifeSciMobileMetadataRecord(
    ParentMobileMetadataRecId = parent.Id,
    ProfileId = pf.Id,
    IntegrationStatus = 'New',
    Status = 'New'
);
insert child;

parent.Status = 'ValidationCompleted';
update parent;

child.Status = 'ValidationCompleted';
update child;

System.debug('Parent Id: ' + parent.Id);
System.debug('Child Id: ' + child.Id);

MetadataGeneratorCallout.callMetadataEndpoint(parent.Id);

System.debug('Future callout enqueued for parent: ' + parent.Id);
