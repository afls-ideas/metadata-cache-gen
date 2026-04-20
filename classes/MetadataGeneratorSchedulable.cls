public class MetadataGeneratorSchedulable implements Schedulable {
    private List<String> profileNames;

    public MetadataGeneratorSchedulable(List<String> profileNames) {
        this.profileNames = profileNames;
    }

    public MetadataGeneratorSchedulable() {
        this(new List<String>{
            'Field Sales Representative',
            'Key Account Manager'
        });
    }

    public void execute(SchedulableContext sc) {
        LifeSciMobileMetadataRecord parent = new LifeSciMobileMetadataRecord(
            IntegrationStatus = 'New',
            Status = 'New'
        );
        insert parent;

        Map<String, Id> profileMap = new Map<String, Id>();
        for (Profile pf : [SELECT Id, Name FROM Profile WHERE Name IN :profileNames]) {
            profileMap.put(pf.Name, pf.Id);
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
            } else {
                System.debug('WARNING: Profile not found — ' + name);
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

        MetadataGeneratorCallout.callMetadataEndpoint(parent.Id);
    }
}
