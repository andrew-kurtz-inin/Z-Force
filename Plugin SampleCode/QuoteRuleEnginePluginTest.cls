/*    Copyright (c) 2014 Zuora, Inc.
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

@isTest(SeeAllData=True)
private class QuoteRulesEnginePluginTest{

    static testmethod void QuoteRulesEnginePluginTest() {
    
    zqu__ZProduct__c testProd = makeProduct();
    zqu__ProductRatePlan__c testPRP = makeProductRatePlan(testProd.Id, 'testRatePlan');    
    zqu__ProductRatePlanCharge__c testPC = makeProductRatePlanCharge(testPRP.Id, 'recurring', 'Flat-Fee');
    
    Account acc = makeAccount();    
    Contact con = makeContact(acc);    
    Opportunity opp = makeOpportunity(acc);
    zqu__Quote__c newQuote = makeQuote(opp);
    zqu__QuoteCharge__c newQC = makeQuoteCharge(newQuote, testPC);
    
    update newQuote;
    
    List<zqu.ZQuoteRulesEngine.ChangeLog> logs = new List<zqu.ZQuoteRulesEngine.ChangeLog>(); 
    zqu.ZQuoteRulesEngine.ChangeLog cL = new zqu.ZQuoteRulesEngine.ChangeLog();
    
    cL.description = 'test123';
    logs.add(cL);
    
    List<String> ratePlanIds = new List<String>{testPRP.Id};
    List<zqu.ZChargeGroup> zcgs = new List<zqu.ZChargeGroup>();
    
    zcgs.add(zqu.zQuoteUtil.getChargeGroup(newQuote.Id, testPRP.Id));
    
    for(zqu.zChargeGroup zcg : zcgs)
    {
        for(zqu.zCharge zc : zcg.zCharges)
        {
            zc.chargeobject = newQC;  
             System.Debug('zc' + zc);
             System.Debug('zc.chargeobject: ' + zc.chargeobject);  
            zc.chargeobject.put('BillingFrequency__c', 'Month');
            zc.chargeobject.put('CustomDiscount__c', 10);
        }
    }        
        System.Debug('Charges: ' + zcgs);
        System.Debug('Logs:' + logs);
        
        QuoteRulesEnginePluginController.runpricerules(zcgs,logs);   
        QuoteRulesEnginePluginController.runValidationRules(newQuote,zcgs,logs);
        QuoteRulesEnginePluginController.runProductRules(newQuote,ratePlanIds,logs);
    }
    
    static testmethod void QuoteRulesEnginePluginTestAmendment() {
    
    zqu__ZProduct__c testProd = makeProduct();
    zqu__ProductRatePlan__c testPRP = makeProductRatePlan(testProd.Id, 'testRatePlan');
    zqu__ProductRatePlanCharge__c testPC = makeProductRatePlanCharge(testPRP.Id, 'recurring', 'Flat-Fee');
    Account acc = makeAccount();
    Contact con = makeContact(acc);
    Opportunity opp = makeOpportunity(acc);
    zqu__Quote__c newQuote = makeAmendmentQuote(opp);
    zqu__QuoteAmendment__c newQuoteAmendment = makeQuoteAmendment(newQuote); 
    zqu__QuoteRatePlan__c newQRP = makeQuoteRatePlan(newQuote , testPRP, newQuoteAmendment );
    zqu__QuoteRatePlanCharge__c newQC = makeQuoteRatePlanCharge(newQuote, testPC, newQRP);
    
    update newQuote;
    
    System.Debug('newQuote: ' + newQuote);
    System.Debug('newQC: ' + newQC);
    
    List<zqu.ZQuoteRulesEngine.ChangeLog> logs = new List<zqu.ZQuoteRulesEngine.ChangeLog>();
    zqu.ZQuoteRulesEngine.ChangeLog cL = new zqu.ZQuoteRulesEngine.ChangeLog();
    
    cL.description = 'tester123';
    logs.add(cL);
    
    List<String> ratePlanIds = new List<String>{testPRP.Id};
    List<zqu.ZChargeGroup> zcgs = new List<zqu.ZChargeGroup>();
    
    zcgs.add(zqu.zQuoteUtil.getChargeGroup(newQuote.Id, testPRP.Id));
    
    for(zqu.zChargeGroup zcg : zcgs)
    {
        for(zqu.zCharge zc : zcg.zCharges)
        {
            zc.chargeobject = newQC;  
             System.Debug('zc' + zc);
             System.Debug('zc.chargeobject: ' + zc.chargeobject);  
			 
            zc.chargeobject.put('BillingFrequency__c', 'Month');
            zc.chargeobject.put('CustomDiscount__c', 10);
        }
    }
        System.Debug('Charges: ' + zcgs);
        System.Debug('Logs:' + logs);
        
        QuoteRulesEnginePluginController.runpricerules(zcgs,logs);
        QuoteRulesEnginePluginController.runValidationRules(newQuote,zcgs,logs);
        QuoteRulesEnginePluginController.runProductRules(newQuote,ratePlanIds,logs);
    }
    
     /**
   * Insert a test account in the db
   */
  public static Account makeAccount() {

    Account testAcc = new Account();

    testAcc.Name = 'my test account';
    testAcc.BillingState = 'CA';
    testAcc.ShippingState = 'CA';

    insert testAcc;
    return testAcc;
  }
  /**
   * Insert a test contact associated with an account in the db
   */
  public static Contact makeContact(Account testAcc) {

    Contact testContact = new Contact();

    testContact.FirstName = 'firstname';
    testContact.LastName = 'lastname';
    testContact.Email = 'email@mail.me';

    testContact.AccountId = testAcc.Id;

    insert testContact;
    return testContact;
  }
  /**
   * Insert a test opportunity associated with an account
   */
  public static Opportunity makeOpportunity(Account testAcc) {

    Opportunity testOpp = new Opportunity();

    testOpp.Name = 'my test opportunity';
    testOpp.StageName = 'Opportunity Identified';
    testOpp.ForecastCategoryName = 'Closed';
    testOpp.CloseDate = System.today();

    testOpp.AccountId = testAcc.Id;

    insert testOpp;
    return testOpp;
  }
  /**
   * Insert a test quote based on an opportunity in the db
   */
  public static zqu__Quote__c makeQuote(Opportunity testOpp) {

    zqu__Quote__c testQuote = new zqu__Quote__c();

    testQuote.Name = 'my test quote';

    testQuote.zqu__Opportunity__c = testOpp.Id;
    testQuote.zqu__Currency__c = 'USD';
    testQuote.zqu__Hidden_Subscription_Name__c = 'Boo';
    testQuote.zqu__Status__c = 'New';
    testQuote.zqu__SubscriptionTermStartDate__c = Date.today();
    testQuote.zqu__InitialTerm__c = 12;
    testQuote.zqu__SubscriptionTermEndDate__c = Date.today().addMonths(12);

    insert testQuote;
    return testQuote;
  }
  
  /**
   * Insert a amendment test quote based on an opportunity in the db
   */
  public static zqu__Quote__c makeAmendmentQuote(Opportunity testOpp) {

    zqu__Quote__c testAmendmentQuote = new zqu__Quote__c();

    testAmendmentQuote.Name = 'my test quote';

    testAmendmentQuote.zqu__Opportunity__c = testOpp.Id;
    testAmendmentQuote.zqu__Currency__c = 'USD';
    testAmendmentQuote.zqu__Hidden_Subscription_Name__c = 'Boo';
    testAmendmentQuote.zqu__Status__c = 'New';
    testAmendmentQuote.zqu__SubscriptionType__c = 'Amend Subscription';
    testAmendmentQuote.zqu__SubscriptionTermStartDate__c = Date.today();
    testAmendmentQuote.zqu__InitialTerm__c = 12;
    testAmendmentQuote.zqu__SubscriptionTermEndDate__c = Date.today().addMonths(12);

    insert testAmendmentQuote;
    return testAmendmentQuote;
  }
  
  /**
   * Insert a test quote based on an opportunity in the db
   */
  public static zqu__QuoteCharge__c makeQuoteCharge(zqu__Quote__c testQuote, zqu__ProductRatePlanCharge__c testPRPC) {

    zqu__QuoteCharge__c testQuoteCharge = new zqu__QuoteCharge__c();

    testQuoteCharge.Name = 'my test quote charge';
    testQuoteCharge.zqu__Quote__c = testQuote.Id;
    testQuoteCharge.zqu__ProductRatePlanCharge__c = testPRPC.Id; 

    insert testQuoteCharge;
    return testQuoteCharge;
  }
  
   /**
   * Insert a test quote amendment based on an opportunity in the db
   */
  public static zqu__QuoteAmendment__c makeQuoteAmendment(zqu__Quote__c testQuote) {

    zqu__QuoteAmendment__c testQuoteAmendment = new zqu__QuoteAmendment__c();

    testQuoteAmendment.Name = 'my test quote amendment';
    testQuoteAmendment.zqu__Quote__c = testQuote.Id;
    insert testQuoteAmendment;
    return testQuoteAmendment;
  }
  
  /**
   * Insert a test quote rate plan based on an opportunity in the db
   */
  public static zqu__QuoteRatePlan__c makeQuoteRatePlan(zqu__Quote__c testQuote, zqu__ProductRatePlan__c testPRP, zqu__QuoteAmendment__c testAmendment) {

    zqu__QuoteRatePlan__c testQuoteRatePlan = new zqu__QuoteRatePlan__c();

    testQuoteRatePlan.Name = 'my test quote rate plan';
    testQuoteRatePlan.zqu__QuoteAmendment__c = testAmendment.Id;
   

    insert testQuoteRatePlan;
    return testQuoteRatePlan;
  }
  
  /**
   * Insert a test quote based on an opportunity in the db
   */
  public static zqu__QuoteRatePlanCharge__c makeQuoteRatePlanCharge(zqu__Quote__c testQuote, zqu__ProductRatePlanCharge__c testPRP, zqu__QuoteRatePlan__c testQRP) {

    zqu__QuoteRatePlanCharge__c testQuoteRatePlanCharge = new zqu__QuoteRatePlanCharge__c();

    testQuoteRatePlanCharge.Name = 'my test quote rate plan charge';
    testQuoteRatePlanCharge.zqu__QuoteRatePlan__c = testQRP.Id;
    //testQuoteRatePlanCharge.zqu__ProductRatePlanChargeZuoraId__c = testPRPC.Id; 

    insert testQuoteRatePlanCharge;
    return testQuoteRatePlanCharge;
  }
    
    public static zqu__ZProduct__c makeProduct()
      {
    zqu__ZProduct__c testProduct = new zqu__ZProduct__c();
    testProduct.Name = 'testing';
    testProduct.zqu__SKU__c = 'testSKU';
    testProduct.zqu__ZuoraId__c = '12';
    testProduct.zqu__EffectiveStartDate__c = date.newinstance(2000, 1, 1);
    testProduct.zqu__EffectiveEndDate__c = date.newinstance(2050, 1, 1);
    testProduct.zqu__Deleted__c = false;
    
    insert testProduct;
    return testProduct;
      }

  private static integer ratePlanId = 154657;
    
    public static zqu__ProductRatePlan__c makeProductRatePlan(String zproduct, String name)
    {
    zqu__ProductRatePlan__c testrp = new zqu__ProductRatePlan__c();
    testrp.name = 'test rp';
    testrp.zqu__ZProduct__c = zproduct;
    testrp.zqu__ZuoraId__c = String.valueOf(ratePlanId);
    ratePlanId++;
    testrp.zqu__Deleted__c = false;
    //set custom fields 

    //Needed for pricing queries
    testrp.zqu__EffectiveStartDate__c = Date.newInstance(2010, 1, 1);
    testrp.zqu__EffectiveEndDate__c = Date.newInstance(2020, 1, 1);
   
    insert testrp;
    return testrp;
    }
    
    private static integer ratePlanChargeId = 125481;
    
    public static zqu__ProductRatePlanCharge__c makeProductRatePlanCharge(String prp, String type, String model)
    {
    zqu__ProductRatePlanCharge__c testprpc = new zqu__ProductRatePlanCharge__c();
    testprpc.zqu__ProductRatePlan__c = prp;
    testprpc.name=type+model+ratePlanChargeId;
    testprpc.zqu__ZuoraId__c = String.valueOf(ratePlanChargeId);
    ratePlanChargeId++;
    testprpc.zqu__UOM__c = 'test UOM';
    testprpc.zqu__Type__c = type;
    testprpc.zqu__RecurringPeriod__c = 'Month';
    testprpc.zqu__PrepaymentPeriods__c = 1;
    testprpc.zqu__Model__c = model;
    testprpc.zqu__MinQuantity__c = 0;
    testprpc.zqu__MaxQuantity__c = 1000;
    testprpc.zqu__ListPrice__c = 5;
    testprpc.zqu__Description__c = 'Test charge';
    testprpc.zqu__DefaultQuantity__c = 5;
    testprpc.zqu__Discount_Apply_Type__c = 0;
    testprpc.zqu__Discount_Level__c = 'RatePlan';
    testprpc.zqu__Upto_How_Many_Periods__c = 0;
    testprpc.zqu__Deleted__c = false;

    insert testprpc;
    return testprpc;
  }
}