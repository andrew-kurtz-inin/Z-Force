public with sharing class PropertyComponentSampleController extends zqu.PropertyComponentController.ParentController {

  ApexPages.StandardController controller;
  public zqu__Quote__c quote {
    get;
    set;
  }
  public zqu.PropertyComponentOptions theOptions {
    get;
    set;
  }
  public Opportunity opp {
    get;
    set;
  }

  public PropertyComponentSampleController(ApexPages.StandardController stdController) {
    System.debug('PropertyComponentSampleController(stdCtrl) executed!');
    this.controller = stdController;

    this.quote = (zqu__Quote__c) this.controller.getRecord();

    // Get one available opportunity
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

    setOpportunity(opportunitys.get(0).Id);

    // Initialize property component options
    theOptions = new zqu.PropertyComponentOptions();
    theOptions.objectName = 'Quote__c';
    theOptions.objectId = this.quote.Id != null ? this.quote.Id : null;
    theOptions.viewType = zqu.ViewConfigurationManager.VIEW_CONFIGURATION_VIEW_TYPE_CREATE;
    theOptions.propertyPageTitle = 'Property Component Sample';
    theOptions.isEditMode = true;

    // Set to detail mode
    String mode = ApexPages.currentPage().getParameters().get('mode');
    if (this.quote.Id != null && mode == 'detail')
      theOptions.isEditMode = false;

    theOptions.renderButtonBar = theOptions.isEditMode;
    theOptions.parentController = this;
    theOptions.instanceName = 'sampleProperty';

    Schema.SObjectType objectType = zqu__Quote__c.sObjectType;
    Map < String, Schema.RecordTypeInfo > recordTypeInfoMap = objectType.getDescribe().getRecordTypeInfosByName();
    theOptions.recordTypeId = recordTypeInfoMap.get('Default').getRecordTypeId();

    theOptions.customRenderingFields.add('Custom_Picklist_Field__c');
    theOptions.customRenderingFields.add('Custom_Text_Field__c');

    theOptions.readonlyFields.add('zqu__Opportunity__c');

    theOptions.populateValuePlugin = 'PropertyComponentSampleController.PopulateDefaultFieldValuePlugin';
    theOptions.relatedObjectPlugin = 'PropertyComponentSampleController.PopulateRelatedObjectFieldPlugin';

    if (this.opp != null) {
      // Set up options for Bill To Contact lookup field
      zqu.LookupComponentOptions optionsForBillTo = new zqu.LookupComponentOptions();
      optionsForBillTo.objectName = 'Contact';
      optionsForBillTo.Id = 'BillToContact';
      optionsForBillTo.contextParameters = new Map < String, String > {
        'objectId' => this.opp.Id
      };
      optionsForBillTo.isEditMode = theOptions.isEditMode;
      optionsForBillTo.isRequired = true;
      optionsForBillTo.lookupComponentControllerName = 'LookupComponentSampleController';
      optionsForBillTo.recordTypeId = Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId();
      optionsForBillTo.popupWindowTitle = 'Bill to Contact Lookup';

      // Set up options for Sold To Contact lookup field
      zqu.LookupComponentOptions optionsForSoldTo = new zqu.LookupComponentOptions();
      optionsForSoldTo.objectName = 'Contact';
      optionsForSoldTo.Id = 'SoldToContact';
      optionsForSoldTo.contextParameters = new Map < String, String > {
        'objectId' => this.opp.Id
      };
      optionsForSoldTo.isEditMode = theOptions.isEditMode;
      optionsForSoldTo.isRequired = true;
      optionsForSoldTo.lookupComponentControllerName = 'ContactLookupComponentController';
      optionsForSoldTo.recordTypeId = Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId();
      optionsForSoldTo.popupWindowTitle = 'Sold to Contact Lookup';

      theOptions.lookupFields = new Map < String, zqu.LookupComponentOptions > {
        'zqu__BillToContact__c' => optionsForBillTo,
          'zqu__SoldToContact__c' => optionsForSoldTo
      };
    }
  }

  public String selectedCustomPicklistValue {
    get;
    set;
  }

  // Set field default value
  public class PopulateDefaultFieldValuePlugin implements IPopulateValuePlugin {
    public void populateDefaultFieldValue(SObject record, zqu.PropertyComponentController.ParentController pcc) {

      // Get PropertyComponentSampleController instance
      PropertyComponentSampleController parentController = (PropertyComponentSampleController) pcc;
      Opportunity opportunity = parentController.opp;

      // Set default field values when create new quote
      if (parentController.quote.Id == null && opportunity != null) {

        // Set default opportunity
        record.put('zqu__Opportunity__c', opportunity.Id);

      }

      // For edit / detail mode, make sure the quote is get from record of property component
      if (parentController.quote.Id != null) {
        parentController.quote = (zqu__Quote__c) record;
      }
    }
  }

  public class PopulateRelatedObjectFieldPlugin implements IRelatedObjectPlugin {
    public Map < String, SObject > getRelatedObject(zqu.PropertyComponentController.ParentController pcc) {

      // Get PropertyComponentSampleController instance
      PropertyComponentSampleController parentController = (PropertyComponentSampleController) pcc;

      Map < String, SObject > relatedObjectMap = new Map < String, SObject > ();

      // Set value for related object field : Opportunity__r.AccountId
      relatedObjectMap.put('Opportunity__r', parentController.opp);

      return relatedObjectMap;

    }
  }

  public void onChangeCustomPicklist() {
    System.debug('selected picklist value : ' + selectedCustomPicklistValue);
    this.quote.Custom_Picklist_Field__c = selectedCustomPicklistValue;
    this.quote.Custom_Text_Field__c = selectedCustomPicklistValue;
  }

  public void setOpportunity(Id oppId) {

    String opp_query;
    if (UserInfo.isMultiCurrencyOrganization()) {
      opp_query = 'SELECT Id, Name,CurrencyISOCode, Account.Id, Account.Name FROM Opportunity WHERE Id = \'' + oppId + '\'';
    }
    else {
      opp_query = 'SELECT Id, Name, Account.Id, Account.Name FROM Opportunity WHERE Id = \'' + oppId + '\'';
    }

    this.opp = Database.query(opp_query);


  }

}