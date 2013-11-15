public with sharing class SelectProductSampleController {
 
  public zqu.SelectProductComponentOptions theOptions        { get; set; }
 
  public SelectProductSampleController(){
 
    theOptions = new zqu.SelectProductComponentOptions();
    theOptions.title = 'Sample Code';
    theOptions.subTitle = 'Choose Product and Charges';
    
    // By default, the select product component is in edit mode
    // You can set it to detail mode from url
    // Append parameter 'mode=detail' from url if you want to use detail mode
    String mode = ApexPages.currentPage().getParameters().get('mode');
    if(mode == zqu.SelectProductComponentOptions.MODE_DETAIL || mode == zqu.SelectProductComponentOptions.MODE_EDIT)
      theOptions.mode = mode;
    
    // Set product / rate plan query additional condition if necessary, for example:
    /*
    theOptions.productSoqlFragment = 'Id in (\'a0BE0000005Be6HMAS\')';
    theOptions.ratePlanSoqlFragment = 'Name = \'Test rate plan\'';
    */
  }
}