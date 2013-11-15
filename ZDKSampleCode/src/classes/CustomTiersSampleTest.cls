@isTest(SeeAllData=false)
private class CustomTiersSampleTest {
  
  static Map < Id, zqu__ProductRatePlan__c > rateplanMap = null;
  
  private static ID createNewSubscriptionQuote(){
    final zqu__ZProduct__c testProduct = zqu.ZQTestDataSetup.prepareProductCatalog();
    rateplanMap = new Map < Id, zqu__ProductRatePlan__c > ([select Id from zqu__ProductRatePlan__c where zqu__ProductRatePlan__c.zqu__ZProduct__r.Id = :testProduct.Id]);
    final List < zqu__ProductRatePlan__c > rateplanList = rateplanMap.values();
    System.debug('zqu__ProductRatePlan__c size: ' + rateplanList.size());
    final zqu__Quote__c newSubscriptionQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(true);
    List<zqu__Quote__c> quotes = [select Id from zqu__Quote__c];
    System.debug('Current quote size: ' + quotes.size());
    return  newSubscriptionQuote.ID;
  }
  
  private static void customTiersForNewSubscription(String chargeType, String model){
    ID theQuoteId = createNewSubscriptionQuote();
    System.debug('Current quote Id: ' + theQuoteId);
    
    List < Id > ratePlanIds = new List< Id >(ratePlanMap.keySet());
    List<zqu.zChargeGroup> chargeGroups = zqu.zQuoteUtil.getChargeGroups(theQuoteId, ratePlanIds);
    zqu.zQuoteUtil.addChargeGroups(chargeGroups);
    
    CustomTiersSample customTiersSample = new CustomTiersSample();
    customTiersSample.quoteId = theQuoteId;
    customTiersSample.setCustomTiers();
    
    List<zqu.zChargeGroup> updatedChargeGroups = zqu.zQuoteUtil.getChargeGroups(theQuoteId);
    for (zqu.zChargeGroup chargeGroup: updatedChargeGroups) {
			for ( zqu.zCharge charge : chargeGroup.zCharges ) {
			    System.debug('Charge Name: ' + charge.Name + ' with custom tiers:' + charge.chargeTiersObjects);
			    if( charge.CHARGE_TYPE == 'Recurring' && charge.MODEL == 'Volume Pricing' ) {
			        System.assertEquals( true,charge.hasCustomTiers,'This charge should has custom tier:' + charge.Name );
			        List<zqu__QuoteCharge_Tier__c> customTiers = charge.chargeTiersObjects;
			        System.debug('Recurring Custom Tiers:' + customTiers);
			        System.assertEquals( 5,customTiers.size(),'We should have total 5 tiers and last tier was added by custom tier' );
			        for(zqu__QuoteCharge_Tier__c tier : customTiers){
			            if( tier.zqu__Tier__c  == 5 ){
			                //We add a new tier.
			                System.debug('New tier added');
			                System.assertEquals( 5.0000000 ,tier.zqu__Effective_Price__c);
			                System.assertEquals( 10.0000000 ,tier.zqu__Price__c);
			                System.assertEquals( 50.00 ,tier.zqu__Discount__c);
			            }
			            if( tier.zqu__Tier__c  == 4 ){
			            	System.debug('Old tier updated');
			              System.assertEquals( 50.00 ,tier.zqu__Discount__c,'We update discount to 50 for last tier');
			            }                       
			        }
			    }
			}
    }
  }

  @isTest
  private static void testRecurringVolumePricingForNS() {
    customTiersForNewSubscription('Recurring','Volume Pricing');
  }
}