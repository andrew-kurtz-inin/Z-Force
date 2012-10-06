/**
Sample email template: 

<TodayDate>

Dear <BillToContactName>,

According to our records, you have outstanding invoices on your account. To help you settle this matter immediately, please see the table below. 

<MergeTablePastDueInvoice>

Please make proper payment arrangement for the invoices that are past due.

Thank you for your business! 
*/

public with sharing class DunningEmailController {
	
	public String toAddress {get; set;}
	public String ccAddress {get; set;}
	public String replyTo {get; set;}
	public String senderDisplayName {get; set;}
	public String subject {get; set;}
	public String body {get;set;}
	
	public static String BillToContactName = '<BillToContactName>';
	public static String MergeTablePastDueInvoice = '<MergeTablePastDueInvoice>';
	public static String TodayDate = '<TodayDate>';
	
	public static List<String> BOUND_VARS = new List<String> {
		BillToContactName, 
    MergeTablePastDueInvoice,		
    TodayDate
	};
	
  public DunningEmailController(
    String toAddress, 
    String ccAddress, 
    String replyTo,
    String senderDisplayName, 
    String subject, 
    String body) {
    	this.toAddress = toAddress;
    	this.ccAddress = ccAddress;
    	this.replyTo = replyTo;
    	this.senderDisplayName = senderDisplayName; 
    	this.subject = subject;
    	this.body = body;
  }
  
  public void sendEmail() {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    // Strings to hold the email addresses to which you are sending the email. 

    String[] toAddresses = new String[] {
      this.toAddress
    };
    String[] ccAddresses = new String[] {
      this.ccAddress
    };

    // Assign the addresses for the To and CC lists to the mail object. 
    mail.setToAddresses(toAddresses);
    mail.setCcAddresses(ccAddresses);

    // Specify the address used when the recipients reply to the email.  
    mail.setReplyTo(this.replyTo);
    // Specify the name used as the display name. 
    mail.setSenderDisplayName(this.senderDisplayName);
    // Specify the subject line for your email address. 
    mail.setSubject(this.subject);
    // Set to True if you want to BCC yourself on the email. 
    mail.setBccSender(false);
    mail.setUseSignature(false);
    
    mail.setPlainTextBody(this.body);
    
    if ( !Test.isRunningTest() ) {
	    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
	      mail
	    });
    }

  }
  
  public class DunningEmailServiceException extends Exception { 
  	
  }
  
  @isTest
  private static void testSendEmail() {
  	DunningEmailController controller = new DunningEmailController(
  	 'tina.kung@zuora.com', 
  	 'tina.kung@zuora.com', 
  	 'tina.kung@zuora.com', 
  	 'Tina Kung Test', 
  	 'Your invoice is overdue', 
  	 'email body');
  	controller.sendEmail();
  }

}