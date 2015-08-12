/*    Copyright (c) 2015 Zuora, Inc.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a copy of 
 *   this software and associated documentation files (the "Software"), to use copy, 
 *   modify, merge, publish the Software and to distribute, and sublicense copies of 
 *   the Software, provided no fee is charged for the Software.  In addition the
 *   rights specified above are conditioned upon the following:
 *
 *   The above copyright notice and this permission notice shall be included in all
 *   copies or substantial portions of the Software.
 *
 *   Zuora, Inc. or any other trademarks of Zuora, Inc.  may not be used to endorse
 *   or promote products derived from this Software without specific prior written
 *   permission from Zuora, Inc.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
 *   ZUORA, INC. BE LIABLE FOR ANY DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES
 *   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *   ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  

 *   IN THE EVENT YOU ARE AN EXISTING ZUORA CUSTOMER, USE OF THIS SOFTWARE IS GOVERNED

 *   BY THIS AGREEMENT AND NOT YOUR MASTER SUBSCRIPTION AGREEMENT WITH ZUORA.
 */

@isTest(SeeAllData=true)
public class z_AddRemovePluginTest { 
	
	public static final String baseProductName = 'Test Base Product';
	public static final String volumeProductName = 'Test Volume Product';
	public static final String otherProductName = 'Test Other Product';

	private static final String baseProductId = '12345678901234567890123456789011';
	private static final String volumeProductId = '12345678901234567890123456789012';
	private static final String otherProductId = '12345678901234567890123456789013';

	public static final String baseRateplanId = '23456789012345678901234567890121';
	public static final String volumeRateplanId = '23456789012345678901234567890122';
	public static final String otherRateplanId = '23456789012345678901234567890123';

	private static final String chargeId1 = '34567890123456789012345678901231';
	private static final String chargeId2 = '34567890123456789012345678901232';
	private static final String chargeId3 = '34567890123456789012345678901233';
	private static final String tierId1 = '45678901234567890123456789012341';
	private static final String tierId2 = '45678901234567890123456789012342';
	private static final String tierId3 = '45678901234567890123456789012343';
	private static final String uomId1 = '56789012345678901234567890123451';
	private static final String uomId2 = '56789012345678901234567890123452';
	private static final String uomId3 = '56789012345678901234567890123453';

	@isTest static void testAddBase() {
		zqu__Quote__c quote = createTestQuote(null, null, null, null, true);
		z_CreateCatalogResult baseCatalogResult = createCatalog(true, false, baseProductId, baseRateplanId, chargeId1, tierId1, uomId1);

		z_AddRemovePlugin plugin = new z_AddRemovePlugin();

		Boolean success = false;

		try {
			plugin.onAdd(quote.Id, new List<Id>{baseCatalogResult.sProductRatePlanId});
			success = true;
		} catch (z_AddRemovePlugin.AddRemoveException ex) {
			System.assert(true, 'z_AddRemovePlugin.AddRemoveException did not occur when only adding base plan');
		}

		System.assert(success == false, 'z_AddRemovePlugin.AddRemoveException did not occur when only adding base plan');
	}

	@isTest static void testAddBaseVolume() {
		zqu__Quote__c quote = createTestQuote(null, null, null, null, true);
		z_CreateCatalogResult baseCatalogResult = createCatalog(true, false, baseProductId, baseRateplanId, chargeId1, tierId1, uomId1);
		z_CreateCatalogResult volumeCatalogResult = createCatalog(false, true, volumeProductId, volumeRateplanId, chargeId2, tierId2, uomId2);

		z_AddRemovePlugin plugin = new z_AddRemovePlugin();

		Boolean success = false;

		try {
			plugin.onAdd(quote.Id, new List<Id>{baseCatalogResult.sProductRatePlanId, volumeCatalogResult.sProductRatePlanId});
			success = true;
		} catch (z_AddRemovePlugin.AddRemoveException ex) {
			System.assert(false, 'z_AddRemovePlugin.AddRemoveException occurred during onAdd of 1 base plan and 1 volume plan');
		}

		System.assert(success, 'z_AddRemovePlugin.AddRemoveException occurred during onAdd of 1 base plan and 1 volume plan');
	}

	@isTest static void testAddVolume() {
		zqu__Quote__c quote = createTestQuote(null, null, null, null, true);
		z_CreateCatalogResult volumeCatalogResult = createCatalog(false, true, volumeProductId, volumeRateplanId, chargeId2, tierId2, uomId2);

		z_AddRemovePlugin plugin = new z_AddRemovePlugin();

		Boolean success = false;

		try {
			plugin.onAdd(quote.Id, new List<Id>{volumeCatalogResult.sProductRatePlanId});
			success = true;
		} catch (z_AddRemovePlugin.AddRemoveException ex) {
			System.assert(true, 'z_AddRemovePlugin.AddRemoveException did not occur when only adding volume plan');
		}

		System.assert(success == false, 'z_AddRemovePlugin.AddRemoveException did not occur when only adding volume plan');
	}

	@isTest static void testEmptyRemove() { 
		zqu__Quote__c quote = createTestQuote(null, null, null, null, true);
		z_CreateCatalogResult baseCatalogResult = createCatalog(true, false, baseProductId, baseRateplanId, chargeId1, tierId1, uomId1);

		z_AddRemovePlugin plugin = new z_AddRemovePlugin(); 
 
		Boolean success = false;

		List<zqu.zChargeGroup> chargeGroups = zqu.zQuoteUtil.getChargeGroups(quote.Id, new List<Id>{baseCatalogResult.sProductRatePlanId});
		List<zqu.zChargeGroup> addedGroups = zqu.zQuoteUtil.addChargeGroups(chargeGroups);

		try {
			plugin.onRemove(quote.Id, new List<Id>{baseCatalogResult.sProductRatePlanId});
			success = true;
		} catch (z_AddRemovePlugin.AddRemoveException ex) {
			System.assert(false, 'z_AddRemovePlugin.AddRemoveException occurred when clearing out Quote');
		}

		System.assert(success, 'z_AddRemovePlugin.AddRemoveException occurred when clearing out Quote');
	}

	/************ Helper Methods /************/


	//Create a test Quote
	public static zqu__Quote__c createTestQuote(Account acc, Opportunity opp, Contact billTo, Contact soldTo, Boolean doInsert) {
		zqu__Quote__c quote = new zqu__Quote__c();
		quote.Name = 'Test Quote';
		quote.zqu__SubscriptionType__c = 'New Subscription';
		quote.zqu__StartDate__c = System.today();
		quote.zqu__ValidUntil__c = System.today();
		quote.zqu__Subscription_Term_Type__c = 'Termed';
		quote.zqu__InitialTerm__c = 12;
		quote.zqu__RenewalTerm__c = 12;
		quote.zqu__Account__c = (acc != null) ? acc.Id : null;
		quote.zqu__Opportunity__c = (opp != null) ? opp.Id : null;
		quote.zqu__BillToContact__c = (billTo != null) ? billTo.Id : null;
		quote.zqu__SoldToContact__c = (soldTo != null) ? soldTo.Id : null;
		quote.zqu__Currency__c = 'USD';
	
		if (doInsert) {
			insert quote;
		}
	
		return quote;
	}
			
	private static z_CreateCatalogResult createCatalog(Boolean isBase, Boolean isVolume, String productId, String rateplanId, String chargeId, String tierId, String uomId) {
		zqu__ZUnitOfMeasure__c uom = createUOM(true, uomId);
		zqu__ZProduct__c prod = createProduct(true, isBase, isVolume, productId);
		zqu__ProductRatePlan__c rateplan = createProductRatePlan(prod, true, rateplanId);
		zqu__ProductRatePlanCharge__c charge = createProductCharge(rateplan, uom, true, chargeId);
		zqu__ProductRatePlanChargeTier__c tier = createProductTier(charge, true, tierId);	
	
		z_CreateCatalogResult result = new z_CreateCatalogResult();
		result.sProductId = prod.Id;
		result.sProductRatePlanId = rateplan.Id;
		result.sProductRatePlanChargeId = charge.Id;	
	
		return result;
	}
	
	private static zqu__ZUnitOfMeasure__c createUOM(Boolean doInsert, String uomId) {
		zqu__ZUnitOfMeasure__c uom = new zqu__ZUnitOfMeasure__c();
		uom.Name = 'Each';
		uom.zqu__Active__c = true;
		uom.zqu__Uom_precision__c = 0;
		uom.zqu__Uom_rounding_mode__c = 'Up';
		uom.zqu__ZuoraId__c = uomId;
	
		if (doInsert) {
			insert uom;
		}
		return uom;
	}
	
	private static zqu__ZProduct__c createProduct(Boolean doInsert, Boolean isBase, Boolean isVolume, String productId) {
		zqu__ZProduct__c prod = new zqu__ZProduct__c();
		prod.Name = (isBase) ? baseProductName : (isVolume) ? volumeProductName : otherProductName;
		prod.zqu__Description__c = 'Test Description';
		prod.zqu__Deleted__c = false;
		prod.zqu__ZuoraId__c = productId;
		prod.zqu__EffectiveStartDate__c = System.today().addYears(-1);
		prod.zqu__EffectiveEndDate__c = System.today().addYears(1);
		prod.zqu__SKU__c = 'Test SKU';
		prod.Product_Category__c = (isBase) ? 'Base Product' : (isVolume) ? 'Volume Upgrade' : null;
		System.debug('Creating product of category: '+prod.Product_Category__c);
	
		if (doInsert) {
			insert prod;
		}
		return prod;
	}
	
	private static zqu__ProductRatePlan__c createProductRatePlan(zqu__ZProduct__c prod, Boolean doInsert, String rateplanId) {
		zqu__ProductRatePlan__c rateplan = new zqu__ProductRatePlan__c();
		rateplan.Name = 'Test ZOrder Rate Plan';
		rateplan.zqu__Deleted__c = false;
		rateplan.zqu__EffectiveStartDate__c = System.today().addYears(-1);
		rateplan.zqu__EffectiveEndDate__c = System.today().addYears(1);
		rateplan.zqu__ZProduct__c = prod.Id;
		rateplan.zqu__ZuoraId__c = rateplanId;
	
		if (doInsert) {
			insert rateplan;
		}
		return rateplan;
	}
	
	private static zqu__ProductRatePlanCharge__c createProductCharge(zqu__ProductRatePlan__c rateplan, zqu__ZUnitOfMeasure__c uom, Boolean doInsert, String chargeId) {
		zqu__ProductRatePlanCharge__c charge = new zqu__ProductRatePlanCharge__c();
		charge.Name = 'Test ZOrder Rate Plan Charge';
		charge.zqu__DefaultQuantity__c = 1;
		charge.zqu__Deleted__c = false;
		charge.zqu__ListPrice__c = 10;
		charge.zqu__Model__c = 'Per Unit Pricing';
		charge.zqu__ProductRatePlan__c = rateplan.Id;
		charge.zqu__RecurringPeriod__c = 'Month';
		charge.zqu__Type__c = 'Recurring';
		charge.zqu__ZUnitOfMeasure__c = uom.Id;
		charge.zqu__UOM__c = uom.Name;
		charge.zqu__ZUom_Id__c = uom.zqu__ZuoraId__c;
		charge.zqu__ZuoraId__c = chargeId;
	
		if (doInsert) {
			insert charge;
		}
		return charge;
	}
	
	private static zqu__ProductRatePlanChargeTier__c createProductTier(zqu__ProductRatePlanCharge__c charge, Boolean doInsert, String tierId) {
		zqu__ProductRatePlanChargeTier__c tier = new zqu__ProductRatePlanChargeTier__c();
		tier.Name = '1';
		tier.zqu__Currency__c = 'USD';
		tier.zqu__Deleted__c = false;
		tier.zqu__EndingUnit__c = 0;
		tier.zqu__IsOveragePrice__c = false;
		tier.zqu__Price__c = 10;
		tier.zqu__PriceFormat__c = 'Per Unit';
		tier.zqu__ProductRatePlanCharge__c = charge.Id;
		tier.zqu__StartingUnit__c = 0;
		tier.zqu__Tier__c = 1;
		tier.zqu__ZuoraId__c = tierId;
	
		if (doInsert) {
			insert tier;
		}
		return tier;
	}
	
	private class z_CreateCatalogResult {
		public Id sProductId {get;set;}
		public Id sProductRatePlanId {get;set;}
		public Id sProductRatePlanChargeId {get;set;}
	}
	
}