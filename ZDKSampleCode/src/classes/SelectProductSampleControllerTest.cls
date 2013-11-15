@isTest
private class SelectProductSampleControllerTest {

  @isTest
  private static void testConstructor() {
    // Create quote record
    zqu__Quote__c quote = new zqu__Quote__c();
    insert quote;
    
    // Set quote id
    ApexPages.currentPage().getParameters().put('id', quote.Id);
    
    // Set quote type
    ApexPages.currentPage().getParameters().put('quoteType', 'Subscription');
    
    // Detail mode
    ApexPages.currentPage().getParameters().put('mode', 'detail');
    
    SelectProductSampleController controller = new SelectProductSampleController();
    
    System.assert(controller.theOptions.quoteId == quote.Id, 'The quote id is not correct, it is : ' + controller.theOptions.quoteId);
    System.assert(controller.theOptions.quoteType == 'Subscription', 'The quote type is not correct, it is : ' + controller.theOptions.quoteType);
    System.assert(controller.theOptions.mode == 'Detail', 'The select product component is not in Detail mode, it is : ' + controller.theOptions.mode);
  }
  
}