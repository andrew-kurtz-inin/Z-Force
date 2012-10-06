/**
 * Copyright (c) 2012 Zuora, Inc.
 * 
 * Author: tkung
 */
global with sharing class DunningNotificationJob implements Schedulable {

  private Dunning_Notification_Definition__c dunningDefHeader;
  private List < DunningPhaseDef__c > dunningPhaseDefs;
  private Map < Integer, String > emailTemplates;
  private List < Integer > dunningDays;

  global DunningNotificationJob(
  Dunning_Notification_Definition__c dunningDefHeader,
  List < DunningPhaseDef__c > dunningPhaseDefs,
  Map < Integer, String > emailTemplates,
  List < Integer > dunningDays) {
    this.dunningDefHeader = dunningDefHeader;
    this.dunningDays = dunningDays;
    this.dunningPhaseDefs = dunningPhaseDefs;
    this.emailTemplates = emailTemplates;
  }

  global void execute(SchedulableContext SC) {
    executeJob();
  }

  public void executeJob() {
    List < Zuora__ZInvoice__c > pastDueInvoices = getPastDueInvoices();
    if (pastDueInvoices == null || pastDueInvoices.size() == 0) {
      return;
    }

    System.debug('tina pastDueInvoices = ' + pastDueInvoices.size());

    Map < DunningPhaseDef__c, List < Zuora__ZInvoice__c >> invoicesByPhase = new Map < DunningPhaseDef__c, List < Zuora__ZInvoice__c >> ();

    for (Zuora__ZInvoice__c invoice: pastDueInvoices) {
      Date dueDate = invoice.Zuora__DueDate__c;
      Integer overdueDays = dueDate.daysBetween(Date.today());
      for (Integer i = 0; i < dunningPhaseDefs.size(); i++) {
        Integer dunningDays = dunningPhaseDefs.get(i).days__c.intValue(); // e.g. 1 day
        if (overdueDays == dunningDays) {
          // Add the invoice to the corresponding phase bucket
          DunningPhaseDef__c currentPhase = dunningPhaseDefs.get(i);
          List < Zuora__ZInvoice__c > invoicesInPhase = invoicesByPhase.get(currentPhase);
          if (invoicesInPhase == null) {
            invoicesInPhase = new List < Zuora__ZInvoice__c > ();
          }
          invoicesInPhase.add(invoice);
          invoicesByPhase.put(currentPhase, invoicesInPhase); 
        }
      }
    }

    Set < DunningPhaseDef__c > phases = invoicesByPhase.keySet();
    System.debug('tina phases = ' + phases);
    for (DunningPhaseDef__c phase: phases) {
      List < Zuora__ZInvoice__c > invoices = invoicesByPhase.get(phase);
      System.debug('tina invoices # for phase ' + phase.Phase__c + ' = ' + invoices.size());

      // First group invoices by billing account 
      Map < Id, List < Zuora__ZInvoice__c >> invoicesByAccount = new Map < Id, List < Zuora__ZInvoice__c >> ();
      for (Zuora__ZInvoice__c invoice: invoices) {
        Id billingAccountId = invoice.Zuora__BillingAccount__c;
        List < Zuora__ZInvoice__c > invoicesForAccount = invoicesByAccount.get(billingAccountId);
        if (invoicesForAccount == null) {
          invoicesForAccount = new List < Zuora__ZInvoice__c > ();
        }
        invoicesForAccount.add(invoice);
        invoicesByAccount.put(billingAccountId, invoicesForAccount);
      }

      // Send email notification for each billing account using the email notification template for the current phase.
      Set < Id > billingAccountIdSet = invoicesByAccount.keySet();
      System.debug('BillingAccountIdSet = ' + billingAccountIdSet);
      for (Id baId: billingAccountIdSet) {
        List < Zuora__ZInvoice__c > accountInvoices = invoicesByAccount.get(baId);
        Zuora__CustomerAccount__c ba = accountInvoices.get(0).Zuora__BillingAccount__r;
        String toEmailAddress = ba.Zuora__BillToWorkEmail__c;
        if (toEmailAddress == null) {
          System.debug(LoggingLevel.ERROR, 'Billing account ' + ba.Name + ' does not have an email address specified. ');
          // If the BillToContactWorkEmail is null, set the To Email Address to the CC Address
          toEmailAddress = phase.DunningDef__r.CC_Address__c;
        }
        System.debug('Sending email notifications for invoices for billing account ' + ba.Name + ' at phase ' + phase.Phase__c);
        String emailBody = constructEmailBody(phase, accountInvoices);

        DunningEmailController emailController = new DunningEmailController(
        toEmailAddress, // toAddress
        phase.DunningDef__r.CC_Address__c,
        phase.DunningDef__r.Reply_To_Address__c,
        phase.DunningDef__r.From_Name__c,
        phase.Subject__c,
        emailBody);
        emailController.sendEmail();
      }
    }
  }

  /**
   * Construct the email body according to the email template defined for the dunning phase, as well as all the 
   * past due invoices for this phase.
   *
   * The invoice merge table includes the following information: 
   * Invoice Number
   * Invoice Balance
   * Invoice Date
   * Payment Term
   * Due Date
   * # of Days Past Due
   */
  private String constructEmailBody(DunningPhaseDef__c phase, List < Zuora__ZInvoice__c > accountInvoices) {

    Map < String, String > boundVariables = new Map < String, String > ();
    String pastDueInvoices = getInvoiceTableHeader();
    for (Zuora__ZInvoice__c invoice: accountInvoices) {
      pastDueInvoices += rightPad(invoice.Name, PADDED_LENGTH) + rightPad(String.valueOf(invoice.Zuora__Balance2__c) + invoice.Zuora__BillingAccount__r.Zuora__Currency__c, PADDED_LENGTH) + rightPad(invoice.Zuora__InvoiceDate__c.format(), PADDED_LENGTH) + rightPad(invoice.Zuora__PaymentTerm__c, PADDED_LENGTH) + rightPad(invoice.Zuora__DueDate__c.format(), PADDED_LENGTH) + rightPad(String.valueOf(invoice.Zuora__DueDate__c.daysBetween(Date.today())) + ' Days Past Due', PADDED_LENGTH) + '\n';
    }

    boundVariables.put(DunningEmailController.MergeTablePastDueInvoice, pastDueInvoices);
    boundVariables.put(DunningEmailController.BillToContactName, accountInvoices.get(0).Zuora__BillingAccount__r.Zuora__BillToName__c);
    boundVariables.put(DunningEmailController.TodayDate, DateTime.now().format());

    String emailTemplate = this.emailTemplates.get(phase.Phase__c.intValue());
    String emailBody = Test.isRunningTest() ? 'test email body <TodayDate>  <BillToContactName>: \n<MergeTablePastDueInvoice> ' : emailTemplate;

    for (String
    var: DunningEmailController.BOUND_VARS) {
      System.debug('Bound variable: ' +
      var +' with ' + boundVariables.get(var));
      emailBody = emailBody.replaceAll(var, boundVariables.get(var));
    }

    System.debug('Email Body = \n' + emailBody);

    return emailBody;
  }

  private List < Zuora__ZInvoice__c > getPastDueInvoices() {
    List < Zuora__ZInvoice__c > invoices = [
    SELECT Id, Name, Zuora__Balance2__c, Zuora__InvoiceDate__c, Zuora__DueDate__c, Zuora__PaymentTerm__c,
	    Zuora__BillingAccount__r.Name,
	    Zuora__BillingAccount__r.Zuora__Currency__c,
	    Zuora__BillingAccount__r.Zuora__BillToName__c,
	    Zuora__BillingAccount__r.Zuora__BillToWorkEmail__c
    FROM Zuora__ZInvoice__c
    WHERE Zuora__Balance2__c > 0
    AND Zuora__DueDate__c < TODAY];
    return invoices;
  }

  private String invoiceTableHeader;
  private static List < String > INVOICE_FIELDS = new List < String > {
    'Invoice Number', 'Invoice Balance', 'Invoice Date', 'Payment Term', 'Due Date', '# of Days Past Due'
  };
  private static Integer PADDED_LENGTH = 20;

  private String getInvoiceTableHeader() {
    if (invoiceTableHeader == null) {
      invoiceTableHeader = '';
      for (String field: INVOICE_FIELDS) {
        invoiceTableHeader += rightPad(field, PADDED_LENGTH);
      }
      invoiceTableHeader += '\n';
    }
    return invoiceTableHeader;
  }

  // This may introduce too many script statements.  So need to replace it with String.rightPad() once Winter '13 is available.
  private String rightPad(String str, Integer len) {
    if (str.length() > len) {
      return str.substring(0, len);
    }
    String paddedStr = str;
    Integer pad = len - str.length();
    for (Integer i = 0; i < pad; i++) {
      paddedStr += ' ';
    }
    return paddedStr;
  }

  @isTest
  private static void testExecuteJob() {
    createDunningDefinition();
    createTestData();

    DunningNotificationService service = new DunningNotificationService();
    DunningNotificationJob job = service.getJob();
    job.executeJob();
  }

  private static void createTestData() {
    Account account = new Account(Name = 'Dunning Test');
    insert account;

    Zuora__CustomerAccount__c ba = new Zuora__CustomerAccount__c(Zuora__Account__c = account.Id);
    ba.Name = 'Test Billing Account';
    ba.Zuora__AccountNumber__c = 'A000000001';
    ba.Zuora__BillToName__c = 'Jack Looney';
    ba.Zuora__BillToWorkEmail__c = 'tina.kung@zuora.com';
    ba.Zuora__Currency__c = 'USD';
    insert ba;

    // Now create invoices
    List < Zuora__ZInvoice__c > invoices = new List < Zuora__ZInvoice__c > ();
    Zuora__ZInvoice__c invoice = new Zuora__ZInvoice__c(Zuora__BillingAccount__c = ba.Id, Name = 'INV0000001', Zuora__Account__c = account.Id);
    invoice.Zuora__Balance2__c = 1000;
    invoice.Zuora__InvoiceDate__c = Date.today().addDays(-2);
    invoice.Zuora__DueDate__c = Date.today().addDays(-1);
    invoice.Zuora__PaymentTerm__c = 'Net 30';
    invoices.add(invoice);

    invoice = new Zuora__ZInvoice__c(Zuora__BillingAccount__c = ba.Id, Name = 'INV0000002', Zuora__Account__c = account.Id);
    invoice.Zuora__Balance2__c = 2000;
    invoice.Zuora__InvoiceDate__c = Date.today().addDays(-2);
    invoice.Zuora__DueDate__c = Date.today().addDays(-4);
    invoice.Zuora__PaymentTerm__c = 'Net 15';
    invoices.add(invoice);

    invoice = new Zuora__ZInvoice__c(Zuora__BillingAccount__c = ba.Id, Name = 'INV0000003', Zuora__Account__c = account.Id);
    invoice.Zuora__Balance2__c = 9000;
    invoice.Zuora__InvoiceDate__c = Date.today().addDays(-2);
    invoice.Zuora__DueDate__c = Date.today().addDays(-10);
    invoice.Zuora__PaymentTerm__c = 'Net 20';
    invoices.add(invoice);

    insert invoices;
  }

  private static void createDunningDefinition() {
    Dunning_Notification_Definition__c dunningDef = new Dunning_Notification_Definition__c();
    dunningDef.From_Name__c = 'Invoice Reminder';
    dunningDef.Default_Subject__c = 'Your invoice is overdue';
    dunningDef.Default_Email_Template_Name__c = 'DunningEmailTemplateA';
    insert dunningDef;

    DunningPhaseDef__c phaseDef = new DunningPhaseDef__c(DunningDef__c = dunningDef.Id);
    phaseDef.Phase__c = 1;
    phaseDef.Days__c = 1;
    phaseDef.Subject__c = '';
    phaseDef.Email_Template_Name__c = null;
    insert phaseDef;

    phaseDef = new DunningPhaseDef__c(DunningDef__c = dunningDef.Id);
    phaseDef.phase__c = 2;
    phaseDef.Days__c = 2;
    phaseDef.Subject__c = 'Second Notice: Your invoice is overdue';
    phaseDef.Email_Template_Name__c = 'DunningEmailTemplateB';
    insert phaseDef;
  }

}