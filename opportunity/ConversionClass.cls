/**
  OpportunityConversion

  This is an example implementation of the GuideCXProjectConversion where the source object 
  is an opportunity. This example assumes that you are leveraging opportunity team members.
 */ 
global class OpportunityConversion implements beynd.GuideCXProjectConversion {
  
  /**
    Project Details

    This method is responsible for building and returning a GuideCXProject. In this case,
    the source object is an opportunity so we will be pulling necessary values from the 
    opportunity to build the project. 

    The following fields are required in order to create a live project. If any of these are 
    missing or there's an error retrieving them, then GuideCX will convert this into a 
    Pending Project in GuideCX where your GuideCX Admin or Project Manager can manually complete
    the setup.

    - Name
    - CustomerName
    - CustomerWebsite
    - ProjectManager

    Refer to the GuideCXProject Class for full details of supported fields
   */
  global beynd.GuideCXProject projectDetails(String id) {
    /** Find the opportunity data */
    Opportunity opp = [
      SELECT
        Id,
        Name,
        Amount,
        CloseDate,
        Account.Name,
        Account.Website,
         (SELECT Contact.FirstName, Contact.LastName, Contact.Email FROM OpportunityContactRoles)
      FROM Opportunity
      WHERE Id = :id
    ];

    beynd.GuideCXProject project  = new beynd.GuideCXProject();
    
    project.Name = opp.Name.left(80).trim();
    project.CashValue = opp.Amount;
    project.StartDate = opp.CloseDate;
    project.CustomerName = opp.Account != null ? opp.Account.Name : 'example';
    
    // handle opportunities that may not have an account or account website
    // replace `example.com` with a domain that makes sense for your use case
    project.CustomerWebsite = opp.Account?.Website != null ? opp.Account?.Website : 'example.com';
    
    // adds all opportunity contacts to the project
    for (OpportunityContactRole cr : opp.OpportunityContactRoles) {
      project.addCustomerTeamMember(cr.Contact.Firstname, cr.Contact.LastName, cr.Contact.Email);
    }

    // Example: Adding internal team members to the project team. Note this will only work if you're using 
    // Opportunity Teams and these emails must match existing accounts in your GuideCX organization. 
    SObjectType teamMemberType = Schema.getGlobalDescribe().get('OpportunityTeamMember');
    if (teamMemberType != null) {
      List<SObject> teamMembers = Database.query('SELECT User.FirstName, User.LastName, User.Email, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId = :id');

      for(SObject tm : teamMembers) {
        User u = (User)tm.getSObject('User');

        project.addInternalTeamMember(u.FirstName, u.LastName, u.Email);

        if (tm.get('TeamMemberRole') == 'Project Manager') {
          project.setProjectManager(u.FirstName, u.LastName, u.Email);
        }
      }
    }

    // Example: Adding a template to a live project. The values you specify here are the Template SKU. This is typically
    // a product SKU you have in Salesforce and then attach the template in GuideCX. 
    project.Templates.add('product-sku-1');
    project.Templates.add('product-sku-2');

    // Example: Populating custom fields to a live project
    // ideally you're making API calls the GuideCX Open API to get the custom field Ids. 
    // https://help.guidecx.com/en/articles/5643502-open-api
    // 
    // Once you have those Ids then you can provide a value for them like this:
    project.CustomFields = new Map<String, String>();
    project.CustomFields.put('0b70415b-d512-4efd-afe3-dee53588b97b', 'Custom Field Value');
    project.CustomFields.put('f6bed2f2-41c0-4591-84db-88b5caff75df', 'Annother Field Value');
    
    return project;
  }

  /**
    You can link GuideCX Projects to your source object for easier reporting
   */
  global void linkProjects(Map<Id, Id> sourceProjectMap) {
    List<Opportunity> opportunities = new List<Opportunity>();

    for (Id source : sourceProjectMap.keySet()) {
      opportunities.add(new Opportunity (
        Id = source,
        beynd__BeyndProject__c = sourceProjectMap.get(source)
      ));
    }

    update opportunities;
  }
}