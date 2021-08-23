/**
  Finds opportunities that have been moved to closed/won and sends the 
  set of IDs to the GuideCXService class to handle further.
 */
trigger OpportunityTrigger on Opportunity (after insert, after update) {
  Set<Id> closedWon = new Set<Id>();
  
  for (Opportunity o : Trigger.new) {
    if (o.IsWon && !Trigger.oldMap.get(o.Id).IsWon) { 
      closedWon.add(o.Id);
    }
  }

  if (!closedWon.isEmpty()) { 
    beynd.GuideCXService.createProjects(closedWon);
  }
}