// Generate LSC Mobile Metadata Cache — Anonymous Apex
// Requires: MetadataGeneratorCallout class deployed to the org

List<String> profileNames = new List<String>{
    'Field Sales Representative',
    'Key Account Manager'
};

LifeSciMobileMetadataRecord parent = new LifeSciMobileMetadataRecord(
    IntegrationStatus = 'New',
    Status = 'New'
);
insert parent;

Map<String, Id> profileMap = new Map<String, Id>();
for (Profile pf : [SELECT Id, Name FROM Profile WHERE Name IN :profileNames]) {
    profileMap.put(pf.Name, pf.Id);
}

for (String name : profileNames) {
    if (!profileMap.containsKey(name)) {
        System.debug('WARNING: Profile not found — ' + name);
    }
}

List<LifeSciMobileMetadataRecord> children = new List<LifeSciMobileMetadataRecord>();
for (String name : profileNames) {
    if (profileMap.containsKey(name)) {
        children.add(new LifeSciMobileMetadataRecord(
            ParentMobileMetadataRecId = parent.Id,
            ProfileId = profileMap.get(name),
            IntegrationStatus = 'New',
            Status = 'New'
        ));
    }
}
insert children;

parent.Status = 'ValidationCompleted';
update parent;

for (LifeSciMobileMetadataRecord child : children) {
    child.Status = 'ValidationCompleted';
}
update children;

System.debug('Parent Id: ' + parent.Id);
for (LifeSciMobileMetadataRecord child : children) {
    System.debug('Child Id: ' + child.Id);
}

MetadataGeneratorCallout.callMetadataEndpoint(parent.Id);

System.debug('Future callout enqueued for parent: ' + parent.Id);
