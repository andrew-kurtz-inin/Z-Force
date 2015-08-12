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

global class z_AddRemovePlugin implements zqu.SelectProductComponentOptions.IAddRemoveRatePlanPlugin{

	public final String debugStr = 'z_AddRemovePlugin: ';

	public z_AddRemovePlugin(){
		System.debug(debugStr+'Starting z_AddRemovePlugin');
	}

	public void onAdd(String quoteId, List<String> addedRatePlans){
		final String funcStr = debugStr + 'onAdd: ';
		System.debug(funcStr+'Starting Add: '+addedRatePlans);

		//throw new AddRemoveException('Test Error - onAdd'); 
		validateQuoteOnSave(quoteId, false, addedRatePlans);
	}

	public void onRemove(String quoteId, List<String> removedRatePlans){
		final String funcStr = debugStr + 'onRemove: ';
		System.debug(funcStr+'Starting Remove: '+removedRatePlans);

		//throw new AddRemoveException('Test Error - onRemove');
	}

	public void validateQuoteOnSave(String quoteId, Boolean isRemove, List<String> ratePlanIds) {
		final String funcStr = debugStr + 'validateQuoteOnSave: ';
		System.debug(funcStr+'Starting validateQuoteOnSave, quoteId: '+quoteId+', isRemove: '+isRemove+', ratePlanIds: '+ratePlanIds);

		isRemove = (isRemove != null) ? isRemove : false;

		if (String.isNotBlank(quoteId)) {
			List<zqu.zChargeGroup> chargeGroups = zqu.zQuoteUtil.getChargeGroups(quoteId);

         	Integer additionalBasePlans = 0;
         	Integer additionalVolumePlans = 0;

		z_RulesEnginePlugin rulesPlugin = new z_RulesEnginePlugin();
		rulesPlugin.buildProductCategoryMap(chargeGroups);

         	if (!isRemove && ratePlanIds != null && ratePlanIds.size() > 0) {
	            System.debug(funcStr+'Query for Product Rate Plans: '+ratePlanIds);

	            List<zqu__ProductRatePlan__c> newPrps = [SELECT Id, Name, zqu__ZProduct__r.Product_Category__c FROM zqu__ProductRatePlan__c WHERE Id IN :ratePlanIds];
	            System.debug(funcStr+'Retrieved '+newPRps.size()+' Product Rate Plans: '+newPRps);

	            for (zqu__ProductRatePlan__c newPrp : newPrps) {
	               	if (newPrp.zqu__ZProduct__r.Product_Category__c == rulesPlugin.baseCategoryText) {
	                  	additionalBasePlans++;
	                  	System.debug(funcStr+'Adding additional base plan');
	               	} else if (newPrp.zqu__ZProduct__r.Product_Category__c == rulesPlugin.volumeCategoryText) {
	                  	additionalVolumePlans++;
	                  	System.debug(funcStr+'Adding additional volume plan');
	               	}
	            }
         	}
 
         	System.debug(funcStr+'Adding '+additionalBasePlans+' additional base plans to existing '+rulesPlugin.basePlans);
         	rulesPlugin.basePlans += additionalBasePlans;

         	System.debug(funcStr+'Adding '+additionalVolumePlans+' additional volume plans to existing '+rulesPlugin.volumePlans);
        	rulesPlugin.volumePlans += additionalVolumePlans;

        	//Checks if this remove action will empty the Quote
        	Boolean emptyQuote = (isRemove && rulesPlugin.totalPlans == 0) ? true : false;

        	if (!emptyQuote) {
        		if (rulesPlugin.notEnoughBasePlans) { 
        			System.debug(funcStr+'Quote has no Base Plans. Throw error');
        			throw new AddRemoveException('Cannot save Quote without one active Base Plan');
        		} else if (rulesPlugin.tooManyBasePlans) {
        			System.debug(funcStr+'Quote has more base plans than allowed');
        			throw new AddRemoveException('Quote can only contain '+rulesPlugin.basePlansRequired+' Base Plan');
        		} else if (rulesPlugin.notEnoughVolumePlans) {
        			System.debug(funcStr+'Quote has no Volume Plans. Throw error');
        			throw new AddRemoveException('Cannot save Quote without one active Volume Plan');
        		} else if (rulesPlugin.tooManyVolumePlans) {
        			System.debug(funcStr+'Quote has '+rulesPlugin.volumePlans+' ,more volume plans than allowed: '+rulesPlugin.volumePlansAllowed+'. Throw error');
        			throw new AddRemoveException('Quote can only contain at most '+rulesPlugin.volumePlansAllowed+' Volume Plan');
        		} else {
        			System.debug(funcStr+'Quote passed validation');
        		}
        	} else {
        		System.debug(funcStr+'Quote will become empty, passes validation');
        	}
		}
	}

	public class AddRemoveException extends Exception {}
}