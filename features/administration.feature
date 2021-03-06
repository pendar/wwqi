Feature: Overview page for the administration of the site
	As an authorized visitor
    I want to see an overview page of my Administrative options in English and Persian

		Scenario: show the administration page in English only
				Given I speak English
					And I have pages
				When I go to the admin page
		    Then I should be on the admin page
					And I should see "Administration"

		Scenario: offer a utilities page from the administration menu
			Given I speak English
				And I have pages
			When I go to the admin page
				And I follow "Utilities"
			Then I should be on the admin_utilities page
				And I should see "Utilities"
				
    Scenario: offer a comps page from the administration menu
      Given I speak English
        And I have pages
      When I go to the admin page
        And I follow "Comps"
      Then I should be on the admin_comps page
        And I should see "Comps"
        
    Scenario: offer a sections page from the administration menu
      Given I speak English
        And I have pages
      When I go to the admin page
        And I follow "Sections"
      Then I should be on the admin_sections page
        And I should see "Sections"