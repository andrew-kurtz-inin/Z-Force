public with sharing class CustomProductSelectorController {

  public zqu.SelectProductComponentOptions theOptions {
    get;
    set;
  }

  public CustomProductSelectorController(ApexPages.StandardController controller) {
    theOptions = new zqu.SelectProductComponentOptions();
    theOptions.filterPlugin = new CustomProductFilter();
  }
}