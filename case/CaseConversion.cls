/**
  CaseConversion

  This is an example implementation of the GuideCXProjectConversion where the source object 
  is a Case
 */ 
global class CaseConversion implements beynd.GuideCXProjectConversion {
  global beynd.GuideCXProject projectDetails(String id) {
    Case sfCase = [
      SELECT Id
        , CaseNumber
        , Contact.FirstName
        , Contact.LastName
        , Contact.Email
        , Account.Name
        , Account.Website
        , Owner.FirstName
        , Owner.LastName
        , Owner.Email
      FROM Case
      WHERE Id = :id
    ];

    beynd.GuideCXProject project  = new beynd.GuideCXProject();
    
    project.Name = sfCase.Account.Name + ': ' + sfCase.CaseNumber;
    project.CustomerName = sfCase.Account.Name;
    project.CustomerWebsite = sfCase.Account.Website;
    
    project.addCustomerTeamMember(sfCase.Contact.FirstName, sfCase.Contact.LastName, sfCase.Contact.Email);
    
    project.setProjectManager(sfCase.Owner.FirstName, sfCase.Owner.LastName, sfCase.Owner.Email);
    
    return project;
  }

  /**
    You can link GuideCX Projects to your source object for easier reporting
   */
  global void linkProjects(Map<Id, Id> sourceProjectMap) {
  }
}