@
isTest
private class CustomProductSelectorControllerTest {

  @
  isTest
  static void testConstructor() {
    Account newAccount = new Account(name = 'test');
    Opportunity newOpp = new Opportunity(name = 'test', Account = newAccount);
    zqu__Quote__c newQuote = new zqu__Quote__c(zqu__opportunity__c = newOpp.Id, name = 'newQuoteTest');
    newQuote.BillingFrequency__c = 'Monthly';
    insert newQuote;
    System.debug('tina new quote inserted, id = ' + newQuote.Id);
    System.Test.setCurrentPage(Page.CustomSelectProducts);
    ApexPages.currentPage().getParameters().put('id', newQuote.Id);
    ApexPages.StandardController stdCon = new ApexPages.StandardController(newQuote);
    CustomProductSelectorController con = new CustomProductSelectorController(stdCon);
    zqu.SelectProductComponentOptions options = con.theOptions;
    System.assert(options.filterPlugin != null && (options.filterPlugin instanceof CustomProductFilter));

    System.assertEquals('', options.productSoqlFragment);
    System.assertEquals(' BillingFrequency__c = \'' + newQuote.BillingFrequency__c + '\'', options.rateplanSoqlFragment);
  }
}