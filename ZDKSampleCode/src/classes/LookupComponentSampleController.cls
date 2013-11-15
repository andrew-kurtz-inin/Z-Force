public with sharing class LookupComponentSampleController extends zqu.LookupComponentController{
    
    public LookupComponentSampleController(){
      System.debug('ContactLookupComponentController() executed!');
    }
    
    // Override the getAutoCompleteBaseSoql() method to get base soql for auto complete
    public override String getAutoCompleteBaseSoql() {
      return 'Select Id, Name From Contact';
    }
    
    /*  
    // Override the getAdditionalCondition() method to construct query soql 'Where' clause
    public override String getAdditionalCondition() {
      String subClause = '';
      return subClause;
    }
    */
}