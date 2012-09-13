trigger QuoteValidationTrigger on zqu__Quote_Processing_Data__c(before insert) {

  // gather all of the quote numbers from the triggered records to be used in a query for the quotes, default those QPD records to valid
  // if the quote number is blank, set it to invalid
  Set < String > quoteNumbers = new Set < String > ();
  for (zqu__Quote_Processing_Data__c q: Trigger.new) {
    if (q.zqu__Quote_Number__c != null && q.zqu__Quote_Number__c != '') {
      quoteNumbers.add(q.zqu__Quote_Number__c);
      q.zqu__Is_Valid__c = true;
    }
    else {
      q.zqu__Is_Valid__c = false;
      q.zqu__Invalid_Reason__c = 'The Quote Number on this row is blank.';
    }
  }

  // retrieve the quotes based on the numbers in the quoteNumbers set
  Map < Id, zqu__Quote__c > quotesMap = new Map < Id, zqu__Quote__c > ([select Id, zqu__Number__c, zqu__Status__c, zqu__SubscriptionTermStartDate__c, zqu__Total__c from zqu__Quote__c where zqu__Number__c in : quoteNumbers]);

  // build the map of <quote number,quote>
  Map < String, zqu__Quote__c > quotesMapByNumber = new Map < String, zqu__Quote__c > ();
  for (zqu__Quote__c q: quotesMap.values()) {
    quotesMapByNumber.put(q.zqu__Number__c, q);
  }

  List < zqu__Quote__c > quotesToUpdate = new List < zqu__Quote__c > ();
  zqu__Quote__c tempQuote;

  // iterate over the triggered records that weren't previously marked invalid and perform the additional validations
  // when this loop is done, all of the invalid quotes will be marked as such, and there will be a list of quotes with updated SubscriptionTermStartDate__c fields ready to be updated
  for (zqu__Quote_Processing_Data__c q: Trigger.new) {
    if (q.zqu__Is_Valid__c) {

      // make sure the quote number was found in the query for the quote records (if it wasn't found, the quote number will not be present as a key in the quotesMapByNumber map)
      // if the quote number is in the quotesMapByNumber, continue to perform the validations
      if (!quotesMapByNumber.containsKey(q.zqu__Quote_Number__c)) {
        q.zqu__Is_Valid__c = false;
        q.zqu__Invalid_Reason__c = 'A quote with Quote Number ' + q.zqu__Quote_Number__c + ' was not found in Salesforce.';
      }
      else {

        // get a temporary handle to the quote in the map
        tempQuote = quotesMapByNumber.get(q.zqu__Quote_Number__c);

        // check the quote status, if it is sent to z-billing, mark the QPD record as invalid
        if (tempQuote.zqu__Status__c == 'Sent to Z-Billing') {
          q.zqu__Is_Valid__c = false;
          q.zqu__Invalid_Reason__c = 'This quote has already been sent to Z-Billing';
        }

        // check the quote's total against the QPD record's payment amount
        if (tempQuote.zqu__Total__c != q.zqu__Payment_Amount__c) {
          q.zqu__Is_Valid__c = false;
          q.zqu__Invalid_Reason__c = 'The Payment Amount on this row is not equal to the Quote Total';
        }

        // only check/change the quote's SubscriptionTermStartDate__c if the QPD record is still valid
        if (q.zqu__Is_Valid__c) {
          if (q.zqu__Effective_Date__c.addDays(1) > tempQuote.zqu__SubscriptionTermStartDate__c) {
            quotesToUpdate.add(new zqu__Quote__c(
            Id = tempQuote.Id, zqu__SubscriptionTermStartDate__c = q.zqu__Effective_Date__c.addDays(1)));
          }
        }
      }
    }
  }

  if (!quotesToUpdate.isEmpty()) {
    update quotesToUpdate;
  }

}