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
		project.CustomerName = opp.Account.Name;
    project.CustomerWebsite = opp.Account.Website;
		
    // adds all opportunity contacts to the project
		for (OpportunityContactRole cr : opp.OpportunityContactRoles) {
			project.addCustomerTeamMember(cr.Contact.Firstname, cr.Contact.LastName, cr.Contact.Email);
		}

    // will only work if you're using Opportunity Teams and these emails must match
    // existing accounts in your GuideCX organization. 
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