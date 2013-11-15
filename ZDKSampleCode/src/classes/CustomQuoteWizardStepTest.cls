@isTest
public with sharing class CustomQuoteWizardStepTest {

  //Test constants
  private static final String TEST_BUSINESS_CHANNEL = 'B2C';
  private static final String TEST_STATE = 'GA';
  private static final String TEST_BILLING_ACCOUNT_ID = 'testBillingAccountId123';

  @isTest
  private static void testSelectOptions() {
    //Create and insert test quote
    zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(true);

    //Construct page controller
    CustomQuoteWizardStep cqws = new CustomQuoteWizardStep(new ApexPages.StandardController(testQuote));

    System.assertEquals(2, cqws.getBusinessChannelOptions().size());
    System.assertEquals(5, cqws.getStateOptions().size());
  }

  @isTest
  private static void testBackAction() {
    //Create and insert test quote with billing account id
    zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(false);
    testQuote.zqu__ZuoraAccountId__c = TEST_BILLING_ACCOUNT_ID;
    insert testQuote;

    //Construct page controller
    CustomQuoteWizardStep cqws = new CustomQuoteWizardStep(new ApexPages.StandardController(testQuote));

    //Call override method
    Map < String, String > urlParams = cqws.processBackAction();

    //Verify results
    System.assertNotEquals(null, urlParams);
    System.assertEquals(2, urlParams.size());
    System.assertEquals(testQuote.zqu__ZuoraAccountId__c, TEST_BILLING_ACCOUNT_ID);
    System.assertEquals(testQuote.Id, urlParams.get('id'));
  }

  @isTest
  private static void testNextAction() {
    //Create and insert test quote
    zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(true);

    //Construct page controller
    CustomQuoteWizardStep cqws = new CustomQuoteWizardStep(new ApexPages.StandardController(testQuote));

    //User selects values B2C and GA
    cqws.selectedBusinessChannel = TEST_BUSINESS_CHANNEL;
    cqws.selectedState = TEST_STATE;

    //Call override method
    Map < String, String > urlParams = cqws.processNextAction();

    //Verify results
    System.assertNotEquals(null, urlParams);
    System.assertEquals(3, urlParams.size());
    System.assertEquals(TEST_BUSINESS_CHANNEL, urlParams.get('businessChannel'));
    System.assertEquals(TEST_STATE, urlParams.get('state'));
    System.assertEquals(testQuote.Id, urlParams.get('id'));
  }

  @isTest
  private static void testCancelAction() {
    //Create and insert test quote
    zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(true);

    //Construct page controller
    CustomQuoteWizardStep cqws = new CustomQuoteWizardStep(new ApexPages.StandardController(testQuote));

    //Call override method
    String cancelUrl = cqws.processCancelAction();

    //Verify result
    System.assertEquals(cancelUrl, '/' + testQuote.zqu__Opportunity__c);
  }

}