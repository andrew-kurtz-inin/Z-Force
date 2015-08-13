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

global class z_RulesEnginePlugin implements zqu.ZQuoteRulesEngine.QuoteRulesEnginePlugin {

	private final String debugStr = 'z_RulesEnginePlugin: ';

	public final String baseCategoryText = 'Base Product';
	public final String volumeCategoryText = 'Volume Upgrade';
	public final String addonCategoryText = 'Add-On Product';

	public final Integer basePlansRequired = 1;
	public final Integer volumePlansAllowed = 1;

	public String tooManyBaseMessage = 'Quote can only contain '+basePlansRequired+' Base Plan';
	public String tooManyVolumeMessage = 'Quote can only contain at most '+volumePlansAllowed+' Volume Plan';

	public Integer basePlans {get;set;}
	public Integer volumePlans {get;set;}
	public Integer totalPlans {get;set;}

	public Boolean tooManyBasePlans { 
		get {
			if (basePlans > basePlansRequired) {
				return true;
			} else {
				return false;
			} 
		}
	}

	public Boolean tooManyVolumePlans { 
		get {
			if (volumePlans > volumePlansAllowed) {
				return true;
			} else {
				return false;
			}
		}
	}

	public Boolean notEnoughBasePlans {
		get {
			if (basePlans < basePlansRequired) {
				return true;
			} else {
				return false;
			}
		}
	}

	public Boolean notEnoughVolumePlans {
		get {
			if (volumePlans < volumePlansAllowed) {
				return true;
			} else {
				return false;
			}
		} 
	}

	public Map<String,String> prodNameCategoryMap {get;set;}

	public z_RulesEnginePlugin() {
		basePlans = 0;
		volumePlans = 0;
		totalPlans = 0;
		prodNameCategoryMap = new Map<String,String>();
	}

	public void buildProductCategoryMap(List<zqu..ZChargeGroup> zcgs) {
		final String funcStr = debugStr + 'buildProductCategoryMap: ';
		System.debug(funcStr+'Starting buildProductCategoryMap');

		basePlans = 0;
		volumePlans = 0;
		totalPlans = 0;
		prodNameCategoryMap = new Map<String,String>();

		Set<String> productNames = new Set<String>();
		
		if (zcgs != null) { 
			for (zqu.zChargeGroup zcg : zcgs) {
				if (String.isNotBlank(zcg.productName)) {
					System.debug(funcStr+'Adding productName '+zcg.productName);
					productNames.add(zcg.productName);
				} else {
					System.debug(funcStr+'ZChargeGroup productname blank');
				}
			}

			if (productNames.size() > 0) {
				List<zqu__ZProduct__c> products = [SELECT Id, Product_Category__c, Name FROM zqu__ZProduct__c WHERE Name IN :productNames AND zqu__Deleted__c = false];

				for (zqu__ZProduct__c prod : products) {
					System.debug(funcStr+'Putting Product '+prod.Name+' with Category '+prod.Product_Category__c);
					prodNameCategoryMap.put(prod.Name, prod.Product_Category__c);
				}

				System.debug(funcStr+'Product Name Category Map: '+prodNameCategoryMap);
				
				for (zqu.zChargeGroup zcg : zcgs) {
					if (String.isNotBlank(zcg.productName)) {
						if (zcg.groupType != zqu.zChargeGroup.TYPE_AMENDMENT_REMOVEPRODUCT && zcg.groupType != zqu.zChargeGroup.TYPE_RENEWAL_REMOVEPRODUCT) {	
							String category = prodNameCategoryMap.get(zcg.productName);

							System.debug(funcStr+zcg.productName+' : '+zcg.rateplanName+' - Group Type: '+zcg.groupType);

							if (category == baseCategoryText) {
								basePlans++;
								System.debug(funcStr+'Product '+zcg.productName+', Adding to basePlans: '+basePlans);
							} else if (category == volumeCategoryText) {
								volumePlans++;
								System.debug(funcStr+'Product '+zcg.productName+', Adding to volumePlans: '+volumePlans);
							}

							totalPlans++;
						} else {
							System.debug(funcStr+'ZChargeGroup is removed. Will not factor in category totals');
						}
					} else {
						System.debug(funcStr+'ZChargeGroup productname blank');
					}
				}
			} else {
				System.debug(funcStr+'Failed to find any Product Names. Continuing.');
			}
		} else {
			System.debug(funcStr+'Passed in charge groups are null');
		}
	}

	public Boolean runValidationRules(zqu__Quote__c quote, List<zqu.ZChargeGroup> zcgs, List<zqu.ZQuoteRulesEngine.ChangeLog> logs) {
		final String funcStr = debugStr + 'runValidationRules: ';
		System.debug(funcStr+'Starting runValidationRules');

		if (zcgs != null) {
			System.debug(funcStr+'MZ: zcgs not empty: '+zcgs.size());

			for (zqu.ZChargeGroup chargeGroup : zcgs) {
				System.debug(funcStr+'MZ: '+chargeGroup.productName+' - '+chargeGroup.rateplanName);
				System.debug(funcStr+'MZ: groupType: '+chargeGroup.groupType);
			}
		} else {
			System.debug(funcStr+'MZ: zcgs empty');
		}

		buildProductCategoryMap(zcgs);	 

		System.debug(funcStr+'Base Plans: '+basePlans+', Base Plans Required: '+basePlansRequired+', Volume Plans: '+volumePlans+' Volume Plans Allowed: '+volumePlansAllowed);

		//if (tooManyBasePlans) {  
		//	System.debug(funcStr+'Quote has more base plans than allowed');
		//	zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
		//	log.description = tooManyBaseMessage;
		//	logs.add(log);
		//	return false;
		//} else if (tooManyVolumePlans) {
		//	System.debug(funcStr+'Quote has '+volumePlans+' ,more volume plans than allowed: '+volumePlansAllowed+'. Throw error');
		//	zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
		//	log.description = tooManyVolumeMessage;
		//	logs.add(log);
		//	return false;
		//} else {
		//	System.debug(funcStr+'Quote passed base and volume plan validation');
		//}

		//Check for allowed records
		return validateAllowedRecords(quote, zcgs, logs);
	}

	public Boolean validateAllowedRecords(zqu__Quote__c quote, List<zqu.ZChargeGroup> zcgs, List<zqu.ZQuoteRulesEngine.ChangeLog> logs) {
		final String funcStr = debugStr + 'validateAllowedRecords: ';
		System.debug(funcStr+'Starting validateAllowedRecords');

		Boolean isSuccess = true;

		Set<String> addonFeaturesCodesOnQuote = new Set<String>();
		Set<String> nonAddonFeaturesCodesOnQuote = new Set<String>();

		List<Zuora_Allowed_Features__c> allowedFeatures = [
			SELECT Name
			FROM Zuora_Allowed_Features__c      	
	  	];

		if (zcgs != null && zcgs.size() > 0) {
			for (zqu.ZChargeGroup chargeGroup : zcgs) {
				if (chargeGroup.quoteProductFeatures != null) {
					String category = prodNameCategoryMap.get(chargeGroup.productName);
					Boolean isAddon = (category == addonCategoryText) ? true : false;

					for (zqu__QuoteProductFeature__c quoteFeature : chargeGroup.quoteProductFeatures) {
						String featureCode = quoteFeature.zqu__ZFeature__r.zqu__Code__c;

						if (String.isNotBlank(featureCode)) {
							if (!isAddon) {
								System.debug(funcStr+'Not an addon product. Adding to nonAddonFeaturesCodesOnQuote');
								nonAddonFeaturesCodesOnQuote.add(featureCode);
							} else if (isAddon && !addonFeaturesCodesOnQuote.contains(featureCode)) {
								System.debug(funcStr+'Addon Product, but no other addon product has current feature');
								addonFeaturesCodesOnQuote.add(featureCode);
							} else {
								System.debug(funcStr+'Quote Feature Code '+featureCode+' on Addon Product '+chargeGroup.productName+' already on Quote in another Addon Product');
								zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
								log.description = 'Addon Product "'+chargeGroup.productName+' : '+chargeGroup.rateplanName+'" contains feature already on Subscription. Cannot add.';
								logs.add(log);
								return false;
							}
						} else {
							System.debug(funcStr+'Feature code blank');
						}
					}
				} else {
					System.debug(funcStr+'Quote Product Features on Charge Group null. Continuing');
				}
			}

			//Check if any addon product feature code is replicated in base product
			for (zqu.ZChargeGroup chargeGroup : zcgs) {
				String category = prodNameCategoryMap.get(chargeGroup.productName);
				Boolean isAddon = (category == addonCategoryText) ? true : false;

				if (!isAddon || chargeGroup.quoteProductFeatures == null) {
					//Only need to check addon product features
					continue;
				} else {
					for (zqu__QuoteProductFeature__c quoteFeature : chargeGroup.quoteProductFeatures) {
						String featureCode = quoteFeature.zqu__ZFeature__r.zqu__Code__c;

						if (String.isNotBlank(featureCode)) {

							//Check if feature is allowed
							Boolean allowedFeatureByPass = false;

							for(Zuora_Allowed_Features__c allowedFeature : allowedFeatures)
							{
								if(allowedFeature.Name == featureCode) {
									allowedFeatureByPass = true;
									break;
								}
							}

							if (allowedFeatureByPass) {
								System.debug(funcStr+'Allowing feature bypass');
								continue;
							}

							if (nonAddonFeaturesCodesOnQuote.contains(featureCode)) {
								System.debug(funcStr+'Quote Feature Code '+featureCode+' on Addon Product '+chargeGroup.productName+' already on Quote in another Non-Addon Product');
								zqu.ZQuoteRulesEngine.ChangeLog log = new zqu.ZQuoteRulesEngine.ChangeLog();
								log.description = 'Addon Product "'+chargeGroup.productName+' : '+chargeGroup.rateplanName+'" contains feature already on Subscription. Cannot add.';
								logs.add(log);
								return false;
							} else {
								System.debug(funcStr+'Addon Feature not contained on Quote in other Products');
							}
						} else {
							System.debug(funcStr+'Feature code blank');
						}
					}
				}
			}

		} else {
			System.debug(funcStr+'Charge groups null or empty. Passes validation');
		}

		return isSuccess;
	}

	public Map<String, List<String>> runProductRules(zqu__Quote__c quote, List<String> ratePlanIds, List<zqu.ZQuoteRulesEngine.ChangeLog> logs){
		final String funcStr = debugStr + 'runProductRules: ';

		Map<String, List<String>> relatedRatePlanIdMap = new Map<String, List<String>>();
		relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_ENABLED, new List<String>());
		relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_ADDED_DISABLED, new List<String>());
		relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_REMOVED_ENABLED, new List<String>());
		relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_RECOMMENDED, new List<String>());
		relatedRatePlanIdMap.put(zqu.ZQuoteRulesEngine.PRODUCT_RULE_TYPE_SELECTED, new List<String>());

		return relatedRatePlanIdMap;
	}

	public void runPriceRules(List<zqu.ZChargeGroup> zcgs, List<zqu.ZQuoteRulesEngine.ChangeLog> logs){
		final String funcStr = debugStr + 'runPriceRules: ';
	}

	public static void appendSuccess(String message) {
	  	appendMessage(ApexPages.Severity.INFO, message);
	}

	public static void appendMessage(ApexPages.Severity severity, String message) {
	  	System.Debug('appendMessage: '+message+', severity: '+severity);
	  	ApexPages.addMessage(new ApexPages.Message(severity, message));
	}
	
}