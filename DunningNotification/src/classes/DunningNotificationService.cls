/**
 * Copyright (c) 2012 Zuora, Inc.
 * 
 * Author: tkung
 */
global with sharing class DunningNotificationService {

  private Dunning_Notification_Definition__c dunningDefHeader;
  private List < DunningPhaseDef__c > dunningPhaseDefs;
  private Map < Integer, String > emailTemplates;
  private List < Integer > dunningDays;

  private DunningNotificationJob job;

  global DunningNotificationService() {
    loadDunningDefinition();
    this.job = new DunningNotificationJob(
	    dunningDefHeader,
	    dunningPhaseDefs,
	    emailTemplates,
	    dunningDays);
  }

  global void scheduleJob() {
    System.schedule('Dunning Notification Service', this.dunningDefHeader.CRON_Expression__c, this.job);
  }

  public DunningNotificationJob getJob() {
    return this.job;
  }

  /**
   * Loads the email dunning notification definition and the dunning notification phases definition.
   * 
   * For each dunning phase: 
   * If the email template name is empty, default the email template name from the header definition.  
   * If the email subject is empty, default the email subject from the header definition.
   */
  private void loadDunningDefinition() {
    this.dunningDefHeader = [
	    SELECT id, Default_Subject__c, Default_Email_Template_Name__c, CRON_Expression__c
	    FROM Dunning_Notification_Definition__c LIMIT 1];
    if (this.dunningDefHeader == null) {
      throw new DunningNotificationException('There is no dunning definition defined. ');
    }

    Id dunningDefId = this.dunningDefHeader.Id;
    this.dunningPhaseDefs = [
	    SELECT Phase__c, Days__c, Email_Template_Name__c, Subject__c,
	      DunningDef__r.From_Name__c,
	      DunningDef__r.CC_Address__c,
	      DunningDef__r.Reply_To_Address__c
	    FROM DunningPhaseDef__c
	    WHERE DunningDef__c = : dunningDefId
	    ORDER BY phase__c];
    if (this.dunningPhaseDefs == null || this.dunningPhaseDefs.size() == 0) {
      throw new DunningNotificationException('There are no dunning phases defined. ');
    }

    dunningDays = new List < Integer > ();
    emailTemplates = new Map < Integer, String > ();

    for (DunningPhaseDef__c dunningPhase: dunningPhaseDefs) {
      System.debug('tina dunningPhase = ' + dunningPhase);
      Integer days = dunningPhase.days__c.intValue();
      dunningDays.add(days);
      if (dunningPhase.Subject__c == null || ''.equals(dunningPhase.Subject__c.trim())) {
        dunningPhase.Subject__c = this.dunningDefHeader.Default_Subject__c;
      }
      if (dunningPhase.Email_Template_Name__c == null || ''.equals(dunningPhase.Email_Template_Name__c.trim())) {
        dunningPhase.Email_Template_Name__c = this.dunningDefHeader.Default_Email_Template_Name__c;
      }

      String emailTemplateFileName = dunningPhase.Email_Template_Name__c;
      PageReference template = new PageReference('/resource/' + emailTemplateFileName);
      if (template == null) {
        throw new DunningEmailController.DunningEmailServiceException('An error occurred while loading email template from static resources: ' + emailTemplateFileName);
      }
      this.emailTemplates.put(dunningPhase.Phase__c.intValue(), Test.isRunningTest() ? '<BillToContactName>\n<MergeTablePastDueInvoice>' : template.getContent().toString());
    }
  }

  global class DunningNotificationException extends Exception {}
}