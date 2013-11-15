public with sharing class CustomQuoteWizardStep extends zqu.BaseQuoteWizardController {


  //Visualforce select options
  public List < SelectOption > getBusinessChannelOptions() {
    return new List < SelectOption > {
      new SelectOption('B2B', 'B2B'),
      new SelectOption('B2C', 'B2C')
    };
  }

  public List < SelectOption > getStateOptions() {
    return new List < SelectOption > {
      new SelectOption('CA', 'CA'),
      new SelectOption('GA', 'GA'),
      new SelectOption('NY', 'NY'),
      new SelectOption('TX', 'TX'),
      new SelectOption('WA', 'WA')
    };
  }

  //User selected values
  public String selectedBusinessChannel {
    get {
      if(selectedBusinessChannel == null) selectedBusinessChannel = 'B2B';
      return selectedBusinessChannel;
    }
    set;
  }

  public String selectedState {
    get{
      if(selectedState == null) selectedState = 'CA';
      return selectedState;
    }
    set;
  }

  // Constructor
  public CustomQuoteWizardStep(ApexPages.StandardController stdcon) {
    super(stdcon);
  }

  // Called before navigating to the previous page (assuming billingAccountId is a required URL parameter for the previous page)
  public override Map < String, String > processBackAction() {
    return new Map < String, String > {
      'billingAccountId' => thisQuote.zqu__ZuoraAccountId__c,
      'id' => thisQuote.Id
    };
  }

  // Called before navigating to the next page 
  public override Map < String, String > processNextAction() {
    //Pass user-selected guided selling parameters to next URL of next page
    return new Map < String, String > {
      'businessChannel' => selectedBusinessChannel,
      'id' => thisQuote.Id,
      'state' => selectedState
    };
  }

  //If the user clicks cancel, return to the opportunity detail page
  public override String processCancelAction() {
    return '/' + thisQuote.zqu__Opportunity__c;
  }

}