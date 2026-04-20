// Step 1: Create LifeSciMobileMetadataRecord parent + child records

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

System.debug('PARENT_ID=' + parent.Id);
System.debug('CHILD_ID=' + child.Id);
