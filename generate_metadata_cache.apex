// Generate LSC Mobile Metadata Cache — run on-demand
// Requires: MetadataGeneratorSchedulable + MetadataGeneratorCallout deployed to the org

new MetadataGeneratorSchedulable().execute(null);
