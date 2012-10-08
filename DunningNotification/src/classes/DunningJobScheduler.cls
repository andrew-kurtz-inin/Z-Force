public with sharing class DunningJobScheduler {
	
	private Id dunningDefId; 
	public DunningJobScheduler(ApexPages.StandardController controller) {
		this.dunningDefId = controller.getId();
	}
	
	public PageReference schedule() {
		try {
			DunningNotificationService service = new DunningNotificationService();
			service.scheduleJob();		
			
	    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'The dunning notification job has been scheduled.');
	    ApexPages.addMessage(myMsg);
		}
		catch(Exception e) {
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, e.getMessage());
      ApexPages.addMessage(myMsg);
		}
    
    return null;
	}
	
	public PageReference navigateBack() {
		return new PageReference('/' + this.dunningDefId);
	}
}