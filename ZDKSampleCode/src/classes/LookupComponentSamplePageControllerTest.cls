@isTest
private class LookupComponentSamplePageControllerTest {

  @isTest
  private static void testConstructor() {
    
    ApexPages.currentPage().getParameters().put('customQuery', 'true');
    LookupComponentSamplePageController controller = new LookupComponentSamplePageController();
    
    zqu.LookupComponentOptions lookupOptions = controller.optionsForLookup;
    System.assert(lookupOptions.objectName == 'Contact', 'The objectName is not correct, it is : ' + lookupOptions.objectName);
    System.assert(lookupOptions.Id == 'LookupField', 'The Id is not correct, it is : ' + lookupOptions.Id);
    System.assert(lookupOptions.isEditMode == true, 'The isEditMode is not correct, it is : ' + lookupOptions.isEditMode);
    System.assert(lookupOptions.lookupComponentControllerName == 'LookupComponentSampleController', 'The lookupComponentControllerName is not correct, it is : ' + lookupOptions.lookupComponentControllerName);
    System.assert(lookupOptions.objectName == 'Contact', 'The objectName is not correct, it is : ' + lookupOptions.objectName);
    System.assert(lookupOptions.popupWindowTitle == 'Sample Lookup', 'The popupWindowTitle is not correct, it is : ' + lookupOptions.popupWindowTitle);
    System.assert(lookupOptions.soqlFragment == ' Department = \'Finance\'', 'The soqlFragment is not correct, it is : ' + lookupOptions.soqlFragment);
    
  }
  
}