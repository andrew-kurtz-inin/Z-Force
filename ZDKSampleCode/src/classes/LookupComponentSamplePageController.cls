public with sharing class LookupComponentSamplePageController {

  public zqu.LookupComponentOptions optionsForLookup {
    get;
    set;
  }

  public LookupComponentSamplePageController() {
    optionsForLookup = new zqu.LookupComponentOptions();
    optionsForLookup.objectName = 'Contact';
    optionsForLookup.Id = 'LookupField';

    // Get opportunity, used for querying the related contacts
    List < Opportunity > opportunitys = [Select Id, Name From Opportunity limit 1];
    if (opportunitys == null || opportunitys.size() == 0) {
      // Insert Opportunity record
      Opportunity opp = new Opportunity();
      opp.Name = 'test opportunity';
      opp.StageName = 'Prospecting';
      opp.CloseDate = Date.today();
      insert opp;
      opportunitys = new List < Opportunity > ();
      opportunitys.add(opp);
    }

    optionsForLookup.contextParameters = new Map < String, String > {
      'objectId' => opportunitys.get(0).Id
    };
    optionsForLookup.isEditMode = true;
    optionsForLookup.lookupComponentControllerName = 'LookupComponentSampleController';
    optionsForLookup.recordTypeId = Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId();
    optionsForLookup.popupWindowTitle = 'Sample Lookup';

    // Add parameter 'customQuery=true' to enable custom query
    // Set your own custom query to optionsForLookup.soqlFragment
    String customQueryEnabled = ApexPages.currentPage().getParameters().get('customQuery');
    if (customQueryEnabled == 'true')
      optionsForLookup.soqlFragment = ' Department = \'Finance\'';
  }

  /*
    Handle the save logic in your save method as below
    public PageReference save(){
      // Get the selected lookup field value from optionsForLookup.targetId
    }
  */

}