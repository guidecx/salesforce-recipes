trigger NewCaseTrigger on Case (after insert) {
  Set<Id> newCases = new Set<Id>();
    for (Case newCase : Trigger.new) {
        if (newCase.Priority == 'High') { 
          newCases.add(newCase.Id);
        }
   }

  if (!newCases.isEmpty()) { 
      beynd.GuideCXService.createProjects(newCases);
  }
}