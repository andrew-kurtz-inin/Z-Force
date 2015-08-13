global class QuoteRulesEnginePluginController implements zqu.ZQuoteRulesEngine.QuoteRulesEnginePlugin {

  public static Boolean runValidationRules(zqu__Quote__c quote, List < zqu.ZChargeGroup > zcgs, List < zqu.ZQuoteRulesEngine.ChangeLog > logs) {
    return true;
  }

  public static void runPriceRules(List < zqu.ZChargeGroup > zcgs, List < zqu.ZQuoteRulesEngine.ChangeLog > logs) {

    //Loops through all ChargeGroups on the Quote
    for (zqu.ZChargeGroup zcg: zcgs) {

      if (zcg.groupType == zqu.zChargeGroup.TYPE_PRODUCT_NEW || zcg.groupType == zqu.zChargeGroup.TYPE_SUBSCRIPTION_ADDED || zcg.groupType == zqu.zChargeGroup.TYPE_AMENDMENT_NEWPRODUCT || zcg.groupType == zqu.zChargeGroup.TYPE_RENEWAL_NEWPRODUCT) {

        List < SObject > chargeObjectList = new List < SObject > ();
        List < zqu.zCharge > zChargeList = new List < zqu.zCharge > ();


        //Loops through each Charge in the ChargeGroup
        for (zqu.zCharge zc1: zcg.zCharges) {
          System.Debug('zc1: ' + zc1);
          SObject qc = new zqu__QuoteCharge__c();

          qc.put('zqu__RatePlanCharge_ZuoraID__c', zc1.Id);
          qc.put('zqu__ProductRatePlanCharge__c', zc1.PRODUCT_RATE_PLAN_CHARGE_SFDC_ID);
          System.Debug('CF: ' + zc1.chargeobject);

          //Grab custom field values set by the user on product selector
          qc.put('CustomField1__c', (string) zc1.chargeobject.get('CustomField1__c'));

          //If a value is entered in Custom Field
          if (qc.get('CustomField1__c') != null && qc.get('CustomField1__c') != '') {
			//Logic
          }
 
          SObject objectOnZCharge = (SObject) zc1.ChargeObject;
          chargeObjectList.add(qc);
          zChargeList.add(zc1);
        }

        /*** Run rules engine logic here using chargeObjectList - start  ***/

        // Put all changed field names into map : Map<charge.ProductRatePlanCharge__c, List<ChangedFieldNames>>
        Map < String, List < String >> changedFieldMap = new Map < String, List < String >> ();

        for (Integer index = 0; index < chargeObjectList.size(); index++) {
          SObject charge = chargeObjectList.get(index);
          zqu.zCharge zc = zChargeList.get(index);

          String productRatePlanChargeId = String.valueOf(charge.get('zqu__ProductRatePlanCharge__c'));
          if (changedFieldMap.get(productRatePlanChargeId) == null) {
            changedFieldMap.put(productRatePlanChargeId, new List < String > ());
          }

          //Add all fields that will be set
          changedFieldMap.get(productRatePlanChargeId).add('zqu__EffectivePrice__c');
          changedFieldMap.get(productRatePlanChargeId).add('zqu__Period__c');

        }

        System.Debug('zcg: ' + zcg);
        System.Debug('chargeObjectList: ' + chargeObjectList);
        System.Debug('changedFieldMap: ' + changedFieldMap);
        /*** Run rules engine logic here using chargeObjectList - complete  ***/

        // Update zChargeGroup from charge object list
        if (!Test.isRunningTest()) {
          zqu.zQuoteUtil.updateZChargeGroupFromSObject(zcg, chargeObjectList, changedFieldMap, '');
        }

      }
    }

  }

  public static Map < String, List < String >> runProductRules(zqu__Quote__c quote, List < String > ratePlanIds, List < zqu.ZQuoteRulesEngine.ChangeLog > logs) {

    Map < String, List < String >> relatedRatePlanIdMap = new Map < String, List < String >> ();
    relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_ENABLED, new List < String > ());
    relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_DISABLED, new List < String > ());
    relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_REMOVED_ENABLED, new List < String > ());


    Set < String > existingRatePlans = new Set < String > ();
    if (ratePlanIds != null) {
      existingRatePlans.addAll(ratePlanIds);
    }

    // Change log
    zqu.ZQuoteRulesEngine.ChangeLog log;

    return relatedRatePlanIdMap;
  }
}