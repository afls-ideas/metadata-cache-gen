public class MetadataGeneratorSchedulable implements Schedulable {
    private String profileName;

    public MetadataGeneratorSchedulable(String profileName) {
        this.profileName = profileName;
    }

    public MetadataGeneratorSchedulable() {
        this('Field Sales Representative');
    }

    public void execute(SchedulableContext sc) {
        LifeSciMobileMetadataRecord parent = new LifeSciMobileMetadataRecord(
            IntegrationStatus = 'New',
            Status = 'New'
        );
        insert parent;

        Profile pf = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

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
    }
}
