global class RulesEngineSampleController implements zqu.ZQuoteRulesEngine.QuoteRulesEnginePlugin {
  public Boolean runValidationRules(zqu__Quote__c quote, List<zqu.ZChargeGroup> zcgs, List<zqu.ZQuoteRulesEngine.ChangeLog> logs){
 
    // Validate rate plans only after quote has been created.
    if(quote.Id != null){
      Set<String> ratePlanIds = new Set<String>();
      Map<String, String> ratePlanNameMap = new Map<String, String>();
      
      // Get 3 rate plans randomly in the sample code
      String ratePlanA = zcgs.size()>1 ? zcgs.get(1).productRatePlanId : '';
      String ratePlanB = zcgs.size()>2 ? zcgs.get(2).productRatePlanId : '';
      String ratePlanC = zcgs.size()>0 ? zcgs.get(0).productRatePlanId : '';
       
      for(zqu.ZChargeGroup zcg : zcgs){
        ratePlanIds.add(zcg.productRatePlanId);
        ratePlanNameMap.put(zcg.productRatePlanId, zcg.ratePlanName);
      }
       
      // Case1 : Rate plan A and B cannot be added together
      if(ratePlanIds.contains(ratePlanA) && ratePlanIds.contains(ratePlanB)){
        zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
        log.description = 'The following rate plans cannot be added together : ' + ratePlanNameMap.get(ratePlanA) + ',' + ratePlanNameMap.get(ratePlanB);
        logs.add(log);
        return false;
      }
      
      // Case2 : Rate plan C must be added to the quote, cannot remove it
      if(!ratePlanIds.contains(ratePlanC)){
        zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
        log.description = 'The following rate plan must be added : ' + ratePlanC;
        logs.add(log);
        return false;
      }
    }
     
    // Validate quote itself
    // Case3 : Quote start date cannot be today
    if(quote.zqu__StartDate__c == Date.today()){
      zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
      log.description = 'Quote start date cannot be today.';
      logs.add(log);
      return false;
    }
     
    return true;
  }
   
  public void runPriceRules(List<zqu.ZChargeGroup> zcgs, List<zqu.ZQuoteRulesEngine.ChangeLog> logs){
     
    for(zqu.ZChargeGroup zcg : zcgs){
      List<SObject> chargeObjectList = new List<SObject>();
      List<zqu.zCharge> zChargeList = new List<zqu.zCharge>();
      for(zqu.zCharge zc : zcg.zCharges){
         
        // Create ChargeProxy__c object instance from zCharge
        ChargeProxy__c cp = new ChargeProxy__c();
        
        // Initial basic fields
        cp.Name = zc.NAME;
        cp.ChargeId__c = zc.Id;
        cp.ChargeGroupId__c = zcg.groupID;
        cp.ChargeType__c = zc.CHARGE_TYPE;
        cp.Model__c = zc.MODEL;
        cp.ListPrice__c = zc.LIST_PRICE;
        cp.ListTotal__c = zc.LIST_TOTAL;
        
        // Initial price fields
        cp.Quantity__c = zc.isQuantityEditable ? Decimal.valueOf(zc.QUANTITY) : null;
        cp.EffectivePrice__c = zc.isEffectivePriceEditable ? Decimal.valueOf(zc.EFFECTIVE_PRICE) : null;
        cp.Discount__c = zc.isDiscountEditable ? Decimal.valueOf(zc.DISCOUNT) : null;
        cp.Total__c = zc.isTotalEditable ? Decimal.valueOf(zc.TOTAL) : null;
        cp.IncludedUnits__c = zc.IsIncludedUnitsEditable ? Decimal.valueOf(zc.INCLUDED_UNITS) : null;
        cp.IsQuantityEditable__c = zc.isQuantityEditable;
        cp.IsEffectivePriceEditable__c = zc.isEffectivePriceEditable;
        cp.IsDiscountEditable__c = zc.isDiscountEditable;
        cp.IsTotalEditable__c = zc.isTotalEditable;
        cp.IsIncludedUnitsEditable__c = zc.IsIncludedUnitsEditable;
        
        // Initial lookup fields
        cp.Product__c = zcg.productId;
        cp.ProductRatePlan__c = zcg.productRatePlanId;
        cp.ProductRatePlanCharge__c = zc.PRODUCT_RATE_PLAN_CHARGE_SFDC_ID;
        cp.Quote__c = zcg.quote.Id;
        cp.Opportunity__c = zcg.quote.zqu__Opportunity__c;
        cp.Account__c = zcg.quote.zqu__Account__c;
        
        chargeObjectList.add(cp);
        zChargeList.add(zc);
      }
       
      /*** Run rules engine logic here using chargeObjectList - start  ***/
       
      // Put all changed field names into map : Map<charge.ProductRatePlanCharge__c, List<ChangedFieldNames>>
      Map<String, List<String>> changedFieldMap = new Map<String, List<String>>();
       
      for(Integer index=0; index<chargeObjectList.size(); index++){
        SObject charge = chargeObjectList.get(index);
        zqu.zCharge zc = zChargeList.get(index);
         
        // Case 1 : Change Discount
        if(Boolean.valueOf(charge.get('IsDiscountEditable__c'))){
          // Modify discount field
          charge.put('Discount__c', 50);
          zqu.zQuoteUtil.recalculatePriceFields(zc, charge, zqu.ZQuoteRulesEngine.PRICE_FIELD_DISCOUNT, '');
           
          // Store changed field name
          String productRatePlanChargeId = String.valueOf(charge.get('ProductRatePlanCharge__c'));
          if(changedFieldMap.get(productRatePlanChargeId) == null){
            changedFieldMap.put(productRatePlanChargeId, new List<String>());
          }
          changedFieldMap.get(productRatePlanChargeId).add(zqu.ZQuoteRulesEngine.PRICE_FIELD_DISCOUNT);
           
          // Add log
          zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
          log.description = String.valueOf(charge.get('Name')) + ' : ' + zqu.ZQuoteRulesEngine.PRICE_FIELD_DISCOUNT + ' is changed to 50';
          logs.add(log);
        }
         
        // Case 2 : Change Effective Price
        if(Boolean.valueOf(charge.get('IsEffectivePriceEditable__c'))){
          // Modify effective price
          charge.put('EffectivePrice__c', 30);
          zqu.zQuoteUtil.recalculatePriceFields(zc, charge, zqu.ZQuoteRulesEngine.PRICE_FIELD_EFFECTIVE_PRICE, '');
           
          // Store changed field name
          String productRatePlanChargeId = String.valueOf(charge.get('ProductRatePlanCharge__c'));
          if(changedFieldMap.get(productRatePlanChargeId) == null){
            changedFieldMap.put(productRatePlanChargeId, new List<String>());
          }
          changedFieldMap.get(productRatePlanChargeId).add(zqu.ZQuoteRulesEngine.PRICE_FIELD_EFFECTIVE_PRICE);
           
          // Add log
          zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
          log.description = String.valueOf(charge.get('Name')) + ' : ' + zqu.ZQuoteRulesEngine.PRICE_FIELD_EFFECTIVE_PRICE + ' is changed to 30';
          logs.add(log);
        }
        
        /*
        // Case 3 : Change Custom Field
        charge.put('Custom_Text_Field__c', 'Test text field value');
        // Store changed field name
        String productRatePlanChargeId = String.valueOf(charge.get('ProductRatePlanCharge__c'));
        if(changedFieldMap.get(productRatePlanChargeId) == null){
          changedFieldMap.put(productRatePlanChargeId, new List<String>());
        }
        changedFieldMap.get(productRatePlanChargeId).add('Custom_Text_Field__c');
        
        // Add log
        zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
        log.description = String.valueOf(charge.get('Name')) + ' : ' + 'Custom_Text_Field__c is changed to \'Test text field value\'';
        logs.add(log);
        */
      }
      
      /*** Run rules engine logic here using chargeObjectList - complete  ***/
       
      // Update zChargeGroup from charge object list
      zqu.zQuoteUtil.updateZChargeGroupFromSObject(zcg, chargeObjectList, changedFieldMap, '');
    }
     
  }
   
  public Map<String, List<String>> runProductRules(zqu__Quote__c quote, List<String> ratePlanIds, List<zqu.ZQuoteRulesEngine.ChangeLog> logs){
 
    Map<String, List<String>> relatedRatePlanIdMap = new Map<String, List<String>>();
    relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_ENABLED, new List<String>());
    relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_DISABLED, new List<String>());
    relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_REMOVED_ENABLED, new List<String>());
    
    String ratePlanA = 'ratePlanAId';
    String ratePlanB = 'ratePlanBId';
    String ratePlanC = 'ratePlanCId';
    
    Set<String> existingRatePlans = new Set<String>();
    if(ratePlanIds != null){
      existingRatePlans.addAll(ratePlanIds);
    }
     
    // Case 1 : If rate plan A is required and has not been added to quote, add it to ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_DISABLED, the rate plan A will be added to quote automatically and cannot be removed
    if(!existingRatePlans.contains(ratePlanA)){
      relatedRatePlanIdMap.get(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_DISABLED).add(ratePlanA);
    }
     
    // Case 2 : If add rate plan B to ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_ENABLED, the rate plan B will be added to quote automatically and can be removed
    relatedRatePlanIdMap.get(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_ENABLED).add(ratePlanB);
     
    // Case 3 : If rate plan C has been added to quote, add it to ZQuoteRulesEngine.PRODUCT_RULE_TYPE_REMOVED_ENABLED, the rate plan C will be removed from quote automatically
    if(existingRatePlans.contains(ratePlanC)){
      relatedRatePlanIdMap.get(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_REMOVED_ENABLED).add(ratePlanC);
    }
    return relatedRatePlanIdMap;
  }
   
}