@isTest
private class PropertyComponentSampleControllerTest {

  @isTest
  private static void testConstructor() {
    // Create quote record but not insert
    zqu__Quote__c quote = new zqu__Quote__c();
    
    // Create quote standard controller
    ApexPages.StandardController stdController = new ApexPages.StandardController(quote);
    
    PropertyComponentSampleController controller = new PropertyComponentSampleController(stdController);
    
    System.assert(controller.opp != null, 'The opportunity is null.');
    System.assert(controller.theOptions.isEditMode == true, 'The property sample is not in Edit mode.');
    
    
    // Detail mode
    ApexPages.currentPage().getParameters().put('mode', 'detail');
    
    // Insert the quote record
    insert quote;
    
    stdController = new ApexPages.StandardController(quote);
    controller = new PropertyComponentSampleController(stdController);
    
    System.assert(controller.theOptions.isEditMode == false, 'The property sample is not in Detail mode.');
    
  }
  
}