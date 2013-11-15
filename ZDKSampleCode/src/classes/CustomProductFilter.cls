global class CustomProductFilter implements zqu.SelectProductComponentOptions.IFilterPlugin {
  String quoteId;
    
  public CustomProductFilter() {
    quoteId = ApexPages.currentPage().getParameters().get('id');
  }
    
  public String getProductSoqlFragment() {
    return '';
  }

  /**
   * Returns the Rateplan Filter SOQL Fragment that filters by billing frequency 
   */
  public String getRateplanSoqlFragment() {
    String soqlFragment = '';
    zqu__Quote__c[] quotes = [select id, BillingFrequency__c from zqu__quote__c where id = : quoteId];
    if (quotes != null && quotes.size() > 0) {
      String billingFrequency = quotes[0].BillingFrequency__c;
      if (!String.isBlank(billingFrequency)) {
        soqlFragment = ' BillingFrequency__c = \'' + billingFrequency + '\'';
      }
    }

    return soqlFragment;  
  }
}