@isTest
public class CustomQuotePreviewSampleTest {

  @isTest
  private static void testCustomQuotePreviewSample() {
    //Create and insert test quote
    zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(false);
    testQuote.zqu__ElectronicPaymentMethodId__c = 'pmid1234';
    //testQuote.zqu__ZuoraAccountId__c = 'zaid1234';
    insert testQuote;

    CustomQuotePreviewSample stzbp = new CustomQuotePreviewSample(new ApexPages.StandardController(testQuote));

    //Verify that no failure message is displayed
    System.assertEquals(stzbp.previewOptions.disableCreateButton, false);
    System.assertEquals(stzbp.previewOptions.notificationOptions.failureBody, null);
    System.assertEquals(stzbp.previewOptions.notificationOptions.isPopup, false);
    System.assertEquals(stzbp.previewOptions.notificationOptions.backAction, '');

    /* CASE 1: Quote successfully sent to Z-Billing */

    testZBillingResult.success = true;

    //Init custom plugin instance
    Type customCreateOrderPlugin = Type.forName('CustomQuotePreviewSample.CreateOrderPlugin');
    CustomQuotePreviewSample.CreateOrderPlugin pluginInstance = (CustomQuotePreviewSample.CreateOrderPlugin) customCreateOrderPlugin.newInstance();

    //User clicks create order
    PageReference successCreateOrderPage = pluginInstance.CreateOrder(stzbp);

    //Verify success message was posted to current page
    System.assertEquals(null, successCreateOrderPage);
    System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.CONFIRM));

    /* CASE 2: Quote not successfully sent to Z-Billing */

    //Set test result success to false
    testZBillingResult.success = false;
    testZBillingResult.message = 'test error message';

    //User clicks create order
    PageReference failureCreateOrderPage = pluginInstance.CreateOrder(stzbp);

    //Verify failure message was posted to current page
    System.assertEquals(null, failureCreateOrderPage);
    System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.ERROR));
  }

  @isTest
  private static void testInvalidCustomQuotePreviewSample() {
    //Create an invalid test quote with no contancts
    zqu__Quote__c testQuote = zqu.ZQTestDataSetup.prepareNewSubscriptionQuote(false);
    testQuote.zqu__SoldToContact__c = null;
    testQuote.zqu__BillToContact__c = null;
    insert testQuote;

    CustomQuotePreviewSample stzbp = new CustomQuotePreviewSample(new ApexPages.StandardController(testQuote));

    //Verify that failure message is displayed and create order button is disabled
    System.assertEquals(stzbp.previewOptions.disableCreateButton, true);
    System.assertEquals(stzbp.previewOptions.notificationOptions.failureBody, CustomQuotePreviewSample.BLANK_CONTACT_ERROR_MESSAGE);
    System.assertEquals(stzbp.previewOptions.notificationOptions.isPopup, true);
    System.assertEquals(stzbp.previewOptions.notificationOptions.backAction, 'toQuoteDetail();');

    //User clicks Go Back on popup error message
    System.assertEquals(stzbp.toQuoteDetail().getUrl(), '/' + testQuote.Id);
  }

  //Mock ZBilling result for testing purposes
  public static zqu.zQuoteUtil.ZBillingResult testZBillingResult {
    get {
      if(testZBillingResult == null) testZBillingResult = new zqu.zQuoteUtil.ZBillingResult();
      return testZBillingResult;
    }
    private set;
  }
}