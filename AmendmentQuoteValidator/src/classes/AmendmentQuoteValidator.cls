/**
 * Custom code implementation to validate an amendment quote.
 * 
 * This class handles the following validation on the quote before it is send to Z-Billing: 
 * 1. Check if the underlying subscription has been amended. If so, check if the Amendment is a renewal-type amendment.
 * 2. If the above conditions are met, and the user agrees to amend on the latest version of the subscription, update the quote's subscription ID
 *    with the latest subscription version, and the quote's start date.
 *
*/
public with sharing class AmendmentQuoteValidator {
	public zqu__Quote__c quote { get; set; }
	static final String AMENDMENT_QUOTE = 'Amend Subscription';
	
	public Boolean isZuoraSubscriptionRenewed { get; set; }
	
	private String currentSubscriptionId; 
	private Zuora.zApi zApiInstance; 
	private Zuora.zObject latestSubscription;
	private PageReference quoteSubmitPageRef; 
	
	public AmendmentQuoteValidator(ApexPages.StandardController stdController) {
		String quoteId = stdController.getId(); 
		List<Zqu__Quote__c> quotes = [SELECT id, zqu__ExistSubscriptionID__c, zqu__SubscriptionType__c FROM zqu__Quote__c WHERE id = :quoteId limit 1]; 
		if ( quotes.size() > 0 ) {
		  this.quote = quotes.get(0);
	    quoteSubmitPageRef = Page.zqu__ZQAmendmentPreview;
	    quoteSubmitPageRef.getParameters().put('id', this.quote.Id);
	    quoteSubmitPageRef.getParameters().put('scontrolCaching', '1');
		}
		else {
      ApexPages.Message message = new ApexPages.Message( ApexPages.Severity.ERROR, 'An error occurred: Cannot load Quote.' );
      ApexPages.addMessage( message );
		}
		
		this.isZuoraSubscriptionRenewed = false;
	}
	
	public PageReference onload() {
		try {
			if (this.quote != null) {
        zApiInstance = new Zuora.zApi();
			  if ( !Test.isRunningTest() ) {
					zApiInstance.zlogin(); 
			  }
				
		    String amendedSubscriptionId = this.quote.zqu__ExistSubscriptionId__c;
		    String quoteType = this.quote.zqu__SubscriptionType__c;
		    
		    if (AMENDMENT_QUOTE == quoteType) {
		      validateLatestSubscription(amendedSubscriptionId);  
		    }
	      if ( this.isZuoraSubscriptionRenewed == false ) {
	        return this.quoteSubmitPageRef;
	      }
			}
		}
		catch(Exception e) {
      ApexPages.Message message = new ApexPages.Message( ApexPages.Severity.ERROR, 'An error occurred: ' + e.getMessage() );
      ApexPages.addMessage( message );
		}
    
    return null;
	}
	
	public PageReference updateQuote() {
		try {
	    DateTime termStartDate = (DateTime)latestSubscription.getValue('TermStartDate');
	    String latestSubscriptionId = (String)latestSubscription.getValue('Id');
	    System.debug('ZuoraDebug## termStartDate = ' + termStartDate + ', latestSubscriptionId = ' + latestSubscriptionId);
	    this.quote.zqu__StartDate__c = termStartDate.date();
	    this.quote.zqu__ExistSubscriptionId__c = latestSubscriptionId;
	    upsert quote; 
		}
		catch(Exception e) {
      ApexPages.Message message = new ApexPages.Message( ApexPages.Severity.ERROR, 'An error occurred while updating the quote: ' + e.getMessage() );
      ApexPages.addMessage( message );
      return null;
		}
		return this.quoteSubmitPageRef;
	}
	
	public PageReference cancel() {
		PageReference pageRef = new PageReference('/' + this.quote.Id);
		return pageRef;
	}
	
  public void validateLatestSubscription(String subscriptionId) {
    List < Zuora.zObject > zobjs = new List < Zuora.zObject > ();
    Zuora.zObject subscription; 
    Zuora.zObject amendment;
    
    String zoqlSubName = 'Select Name, Version, Status from Subscription where Id = \'' + subscriptionId + '\'';
    
    if ( !Test.isRunningTest() ) {
      zobjs = this.zApiInstance.zquery(zoqlSubName);
    }
    else {
    	zobjs = createMockSubscription();
    }
    
	  if (zobjs.size() == 1) { 
	    subscription = zobjs[0];
	  }
    String subName = (String)subscription.getValue('Name');
    String status = (String)subscription.getValue('Status');
    Integer currentVersion = (Integer)subscription.getValue('Version');
    
    System.debug('ZuoraDebug## subName = ' + subName + ', status = ' + status + ', currentVersion = ' + currentVersion);
    
    List<String> subscriptionIdList = new List<String>();
    
    if ( 'Expired' == status ) {
    	// The subscription has already been amended
	    String zoqlGetSubscriptions = 'Select Id, Version, TermStartDate from Subscription where Name = \'' + subName + '\'';
	    if ( !Test.isRunningTest() ) {
	      zobjs = this.zApiInstance.zquery(zoqlGetSubscriptions);
	    }
	    else {
	    	zobjs = createMockSubscriptions();
	    }
	    Integer maxVersion = 1;
	    if ( zobjs.size() > 0 ) {
	      for ( Zuora.zObject sub : zobjs ) {
	        Integer version = (Integer)sub.getValue('Version');
	        if ( version > maxVersion ) {
	        	latestSubscription = sub;
	        	maxVersion = version;
	        }
	        if ( version >= currentVersion ) {
	          subscriptionIdList.add((String)sub.getValue('Id'));	
	        }
	      }
	    }
	    
	    // Now check from the current subscription version to the latest version, whether the amendments are all of Renewal Type.
	    String zoqlAmendments = 'Select Id, Type from Amendment where '; 
	    for ( String subId : subscriptionIdList ) {
	    	zoqlAmendments += 'SubscriptionId = \'' + subscriptionId + '\' or ';
	    }
	    System.debug('ZuoraDebug## zoqlAmendment = ' + zoqlAmendments);
	    zoqlAmendments = zoqlAmendments.substring(0, zoqlAmendments.length() - 3);
	    
	    if ( !Test.isRunningTest() ) {
        zobjs = this.zApiInstance.zquery(zoqlAmendments);
	    }
	    else {
	    	zobjs = createMockAmendments();
	    }
      boolean allRenewals = true;
      for ( Zuora.zObject zobj : zobjs ) {
      	String type = (String)zobj.getValue('Type');
      	if ( type != 'Renewal') {
      		allRenewals = false;
		      System.debug('ZuoraDebug## There has been non-renewal type of amendment since the current version of the subscription.  Redirecting to ZuoraQuoteSubmit...');
      		break;
      	}
      }
      
      this.isZuorasubscriptionRenewed = allRenewals; 
    }
    else {
    	System.debug('ZuoraDebug## The current subscription is the latest version.  Redirecting to ZuoraQuoteSubmit...');
    	this.isZuorasubscriptionRenewed = false;
    }
  }
  
  private List<Zuora.zObject> createMockSubscription() {
	  List<Zuora.zObject> zobjs = new List<Zuora.zObject>();
	  Zuora.zObject zobj = new Zuora.zObject('Subscription');
	  zobj.setValue('Name', 'S-000001');
	  zobj.setValue('Status', 'Expired');
	  zobj.setValue('Version', 1);
	  zobjs.add(zobj);
	  return zobjs;
  }
  
  private List<Zuora.zObject> createMockSubscriptions() {
    List<Zuora.zObject> zobjs = new List<Zuora.zObject>();
    Zuora.zObject mockZobj = new Zuora.zObject('Subscription');
    mockZobj.setValue('Id', '8a8ae4ac3966b02501396c250f3a0371');
    mockZobj.setValue('Name', 'S-000001');
    mockZobj.setValue('Version', 2);
    mockZobj.setValue('TermStartDate', DateTime.now());
    zobjs.add(mockZobj);
    mockZobj = new Zuora.zObject('Subscription');
    mockZobj.setValue('Id', '8a8ae4ac3966b02501396c250f3a0372');
    mockZobj.setValue('Name', 'S-000001');
    mockZobj.setValue('Version', 1);
    mockZobj.setValue('TermStartDate', DateTime.now());
    zobjs.add(mockZobj);
    return zobjs;
  }
  
  private List<Zuora.zObject> createMockAmendments() {
    List<Zuora.zObject> zobjs = new List<Zuora.zObject>();
    Zuora.zObject mockZobj = new Zuora.zObject('Amendment');
    mockZobj.setValue('Id', '8a8ae4ac3966b02501396c250f3a0373');
    mockZobj.setValue('Type', 'Renewal'); 
    zobjs.add(mockZobj);
    return zobjs;
  }
  
  @isTest(SeeAllData=true)
  private static void testValidate() {
  	Account acct = new Account(Name = 'Test account');
  	insert acct;
  	Opportunity oppty = new Opportunity(Name = 'Test Opportunity');
  	oppty.AccountId = acct.Id;
  	oppty.StageName = 'Proposed';
  	oppty.CloseDate = DateTime.now().date();
  	insert oppty;
  	
  	zqu__Quote__c quote = new zqu__Quote__c(Name = 'Q0000001', zqu__Opportunity__c = oppty.Id);
  	quote.zqu__ExistSubscriptionId__c = '8a8ae4ac3966b02501396c250f3a0376';
  	quote.zqu__SubscriptionType__c = AMENDMENT_QUOTE;
  	insert quote;
  	
  	ApexPages.StandardController stdController = new ApexPages.StandardController(quote);
  	AmendmentQuoteValidator validator = new AmendmentQuoteValidator(stdController);
  	validator.onload();
  	System.assert(validator.isZuoraSubscriptionRenewed);
  	validator.updateQuote();
  	
  	PageReference pageRef = validator.cancel();
  	
    quote = new zqu__Quote__c(Name = 'Q0000002', zqu__Opportunity__c = oppty.Id);
    quote.zqu__ExistSubscriptionId__c = '8a8ae4ac3966b02501396c250f3a0376';
    quote.zqu__SubscriptionType__c = 'New Subscription Quote';
    insert quote;
    
    stdController = new ApexPages.StandardController(quote);
    validator = new AmendmentQuoteValidator(stdController);
    validator.onload();
    System.assert(!validator.isZuoraSubscriptionRenewed);
    
    stdController = new ApexPages.StandardController(new zqu__Quote__c());
    validator = new AmendmentQuoteValidator(stdController);
    System.assert(ApexPages.getMessages().size() > 0);
    System.assert(!validator.isZuoraSubscriptionRenewed);
  }
}