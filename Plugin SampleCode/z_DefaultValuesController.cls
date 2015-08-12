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
 
global class z_DefaultValuesController extends zqu.CreateQuoteController.PopulateDefaultFieldValuePlugin{
    global override void populateDefaultFieldValue (SObject record, zqu.PropertyComponentController.ParentController pcc)
    {   
    	String funcStr = 'z_DefaultValuesController: populateDefaultFieldValue: '; 
    	System.debug(funcStr+'Starting default values');
        if(!Test.isRunningTest()) {
        	super.populateDefaultFieldValue(record, pcc);    
        }
        System.debug(funcStr+'pcc: '+pcc);
        zqu__Quote__c quote = (zqu__Quote__c) record;
        
        if(quote.Id != null) 
        {
            quote = [
                Select Id, zqu__SubscriptionType__c, zqu__ExistSubscriptionID__c
                FROM zqu__Quote__c
                WHERE Id =: quote.Id
            ];
        }
                
        if(quote.zqu__SubscriptionType__c == 'Amend Subscription' || quote.zqu__SubscriptionType__c == 'Renew Subscription')
        {
            List<Zuora__SubscriptionProductCharge__c> zSubscriptionProductCharges = [
                SELECT Id, Zuora__BillingPeriod__c 
                FROM Zuora__SubscriptionProductCharge__c
                WHERE Zuora__Subscription__r.Zuora__External_Id__c =: quote.zqu__ExistSubscriptionID__c
            ];
            
            String currentFrequency = null;
            for(Zuora__SubscriptionProductCharge__c zSubscriptionCharge : zSubscriptionProductCharges)
            {
                if(currentFrequency == 'No Match')
                    break;
            
                String tempFrequency = zSubscriptionCharge.Zuora__BillingPeriod__c;
                if(currentFrequency == null)    currentFrequency = zSubscriptionCharge.Zuora__BillingPeriod__c;
                else if(currentFrequency == tempFrequency)  continue;
                else
                {
                    currentFrequency = 'No Match';
                    break;
                }
            }
            
            if(currentFrequency != 'No Match')
            {
                if(currentFrequency == 'Month')
                    record.put('Frequency__c', 'Monthly');
                else if(currentFrequency == 'Quarter')
                    record.put('Frequency__c', 'Quarterly');
                else 
                    record.put('Frequency__c', currentFrequency);
            }
        }
    }
}