public with sharing class CustomTiersSample { // Sample
  public Boolean success {
    get;
    set;
  }

  public String quoteId {
    get;
    set;
  }

  public PageReference setCustomTiers() {
    success = false;
		String quoteId = quoteId;
		List<zqu.zChargeGroup> chargeGroups = zqu.zQuoteUtil.getChargeGroups(quoteId);
		List<zqu.zChargeGroup> chargeGroupsToUpdate = new List<zqu.zChargeGroup>();
		List<zqu__QuoteCharge_Tier__c> customTiers = new List<zqu__QuoteCharge_Tier__c>();
		//Get the first charge group which should at least contain one Recurring Volume Pricing Charge.
    
    for (zqu.zChargeGroup chargeGroup: chargeGroups) {
    	System.debug('Charge Group Type: ' + chargeGroup.groupType);
      System.debug('***** CHARGE GROUP ' + chargeGroup.groupID + ' HAS ' + chargeGroup.zCharges.size() + ' CHARGES *****');
      
			for ( zqu.zCharge charge : chargeGroup.zCharges ) {
			  if( charge.CHARGE_TYPE == 'Recurring' && charge.MODEL == 'Volume Pricing' ) {
			    System.debug( 'Set custom tiers for charge:'+ charge.Id);
			 
			    //Specific custom tiers for current volume pricing charge
			    charge.hasCustomTiers = true;
			 
			    //Get the default tiers from Product Catalog
			    List<zqu__QuoteCharge_Tier__c> tiers = charge.chargeTiersObjects;
			 
			    //Update last tier through giving it 50% discount
			    tiers.get( tiers.size() - 1 ).zqu__Effective_Price__c = tiers.get( tiers.size() - 1 ).zqu__Price__c * 0.5;
			 
			    //Please note the discount should be '50', not '0.5'
			    tiers.get( tiers.size() - 1 ).zqu__Discount__c = 50;
			 
			    //Reset the 'EndingUnit__c' for last tier
			    if( tiers.get( tiers.size() - 1 ).zqu__EndingUnit__c == null )
			    	tiers.get( tiers.size() - 1 ).zqu__EndingUnit__c = tiers.get( tiers.size() - 1 ).zqu__StartingUnit__c + 10;
			 
			    zqu__QuoteCharge_Tier__c tier = new zqu__QuoteCharge_Tier__c();
			    tier.name = String.valueOf( tiers.size() + 1 );
			    tier.zqu__Tier__c = tiers.size() + 1;
			 
			    //Please set 'StartingUnit__c' correctly based on UOM precision.
			    tier.zqu__StartingUnit__c = tiers.get( tiers.size() - 1 ).zqu__EndingUnit__c + 1;
			    tier.zqu__EndingUnit__c = null;
			    tier.zqu__Effective_Price__c = 5;
			    tier.zqu__Price__c = 10;
			    //Please note the discount should be '50', not '0.5'
			    tier.zqu__Discount__c = 50;
			    tier.zqu__PriceFormat__c = 'Per Unit';
			 
			    //Add a new tier into the default tiers
			    tiers.add( tier );
			 
			    //We should make sure we pass all tiers for current charge.
			    charge.populateCustomChargeTiers( tiers );
			  }
			}
    }
    
		// Persist the updates together with custom tiers
		chargeGroupsToUpdate = zqu.zQuoteUtil.updateChargeGroups(chargeGroups);
		
		success = true;

    return null;
  }
}