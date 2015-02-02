@isTest
private class RulesEngineSampleControllerTest {

  @isTest
  private static void testValidationRules() {
    
    // Set up testing data
    final zqu__ZProduct__c testProduct = zqu.ZQTestDataSetup.prepareProductCatalog();
    final List<zqu__ProductRatePlan__c> ratePlans = [select Id, Name from zqu__ProductRatePlan__c where zqu__ZProduct__r.Id = :testProduct.Id];
    final zqu__Quote__c quote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(true);
    
    // Get all rate plan ids
    List<String> ratePlanIdList = new List<String>();
    for(zqu__ProductRatePlan__c ratePlan : ratePlans){
      ratePlanIdList.add(ratePlan.Id);
    }
    
    // Get all charge groups from rate plan ids
    List<zqu.ZChargeGroup> chargeGroups = zqu.zQuoteUtil.getChargeGroups(quote.Id, ratePlanIdList);
    
    // Boolen value returned by validation rule
    Boolean validationResult;
    
    // Change logs used to store change details
    List<zqu.ZQuoteRulesEngine.ChangeLog> logs = new List<zqu.ZQuoteRulesEngine.ChangeLog>();
    
    // Test charge group list, used for being passed to the plugin
    List<zqu.ZChargeGroup> testChargeGroups = new List<zqu.ZChargeGroup>();
    
    RulesEngineSampleController rulesEngineController = new RulesEngineSampleController();
    
    // Test Validation Rule : Case 2
    validationResult = rulesEngineController.runValidationRules(quote, testChargeGroups, logs);
    System.assert(validationResult == false, 'Validation rule is passed!');
    System.assert(logs.get(0).description.contains('The following rate plan must be added'), 'The change log is not correct, it is : ' + logs.get(0).description);
    
    // Test Validation Rule : Case 3
    logs.clear();
    testChargeGroups.clear();
    testChargeGroups.add(chargeGroups.get(0));
    quote.zqu__StartDate__c = Date.today();
    validationResult = rulesEngineController.runValidationRules(quote, testChargeGroups, logs);
    System.assert(validationResult == false, 'Validation rule is passed!');
    System.assert(logs.get(0).description.equals('Quote start date cannot be today.'), 'The change log is not correct, it is : ' + logs.get(0).description);
    
    // Test Validation Rule : Case 1
    logs.clear();
    testChargeGroups.clear();
    testChargeGroups.add(chargeGroups.get(0));
    testChargeGroups.add(chargeGroups.get(1));
    testChargeGroups.add(chargeGroups.get(2));
    validationResult = rulesEngineController.runValidationRules(quote, testChargeGroups, logs);
    System.assert(validationResult == false, 'Validation rule is passed!');
    System.assert(logs.get(0).description.contains('The following rate plans cannot be added together'), 'The change log is not correct, it is : ' + logs.get(0).description);
  }
  
  @isTest
  private static void testPriceRules() {
    
    // Set up testing data
    final zqu__ZProduct__c testProduct = zqu.ZQTestDataSetup.prepareProductCatalog();
    
    // Get one rate plan belongs to the product
    // Rate plan name : 'Plan for Per Unit charges'
    // Rate plan charge : 1. 'Per Unit Pricing','One-Time'
    //                    2. 'Per Unit Pricing','Recurring'
    //                    3. 'Per Unit Pricing','Usage'
    final zqu__ProductRatePlan__c ratePlan = [select Id, Name from zqu__ProductRatePlan__c where zqu__ZProduct__r.Id = :testProduct.Id AND Name = 'Plan for Per Unit charges' limit 1];
    
    final zqu__Quote__c quote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(true);
    
    // Get charge group from rate plan id
    zqu.ZChargeGroup chargeGroup = zqu.zQuoteUtil.getChargeGroup(quote.Id, ratePlan.Id);
    
    // Change logs used to store change details
    List<zqu.ZQuoteRulesEngine.ChangeLog> logs = new List<zqu.ZQuoteRulesEngine.ChangeLog>();
    
    RulesEngineSampleController rulesEngineController = new RulesEngineSampleController();
    
    rulesEngineController.runPriceRules(new List<zqu.ZChargeGroup>{chargeGroup}, logs);
    
    // Test Effective Price has been modified by Price Rules
    for(zqu.ZCharge zc : chargeGroup.zcharges){
      System.assert(zc.EFFECTIVE_PRICE == '30.00', 'The effective price is not correct, it is : ' + zc.EFFECTIVE_PRICE);
    }
  }
  
  @isTest
  private static void testProductRules() {
    
    // Set up testing data
    final zqu__Quote__c quote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(true);
    
    // Get all rate plan ids
    List<String> ratePlanIds = new List<String>();
    
    // Change logs used to store change details
    List<zqu.ZQuoteRulesEngine.ChangeLog> logs = new List<zqu.ZQuoteRulesEngine.ChangeLog>();
    
    // Test charge group list, used for being passed to the plugin
    List<zqu.ZChargeGroup> testChargeGroups = new List<zqu.ZChargeGroup>();
    
    RulesEngineSampleController rulesEngineController = new RulesEngineSampleController();
    
    // Test Product Rules : Case 1, Case 2
    Map<String, List<String>> productRulesReturnValues = rulesEngineController.runProductRules(quote, ratePlanIds, logs);
    System.assert(productRulesReturnValues.get(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_DISABLED).get(0) == 'ratePlanAId', 'Rate Plan A is not added');
    System.assert(productRulesReturnValues.get(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_ENABLED).get(0) == 'ratePlanBId', 'Rate Plan B is not added');
    
    // Test Product Rules : Case 3
    ratePlanIds.add('ratePlanCId');
    productRulesReturnValues = rulesEngineController.runProductRules(quote, ratePlanIds, logs);
    System.assert(productRulesReturnValues.get(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_REMOVED_ENABLED).get(0) == 'ratePlanCId', 'Rate Plan C is not removed');
    
  }
}