({
	setConsoleTabProperties : function(component, event) {
        //initialize the service components
    	var workspaceAPI = component.find("workspace");

        //Get data from Page Reference
        let ref = component.get('v.pageReference');
        let tabTitle = ref.state.c__title;
        let iconName = ref.state.c__iconName;
        
        //Assigning the data back to an attribute
        component.set('v.recordId', ref.state.c__recordId);
        component.set('v.title', ref.state.c__title);
        component.set('v.iconName', ref.state.c__iconName);
        component.set('v.iconSize', ref.state.c__iconSize);
        component.set('v.sObjectName', ref.state.c__sObjectName);
        component.set('v.commaSeparatedRecordtypes', ref.state.c__commaSeparatedRecordtypes);
        component.set('v.fieldSetForColumns', ref.state.c__fieldSetForColumns);
        component.set('v.relationshipFieldNames', ref.state.c__relationshipFieldNames);
        component.set('v.condition', ref.state.c__condition);
        component.set('v.limitCount', ref.state.c__limitCount);
        component.set('v.sortStatement', ref.state.c__sortStatement);
        component.set('v.showNewButton', ref.state.c__showNewButton);
        component.set('v.primaryRelationshipField', ref.state.c__primaryRelationshipField);
        component.set('v.viewAll', ref.state.c__viewAll);
        
		//Set the console tab properties
        workspaceAPI
        	.isConsoleNavigation()
        	.then(function(isConsole) {
				if (isConsole) {
          			//in a console app - get the current focused tab
          			workspaceAPI.getFocusedTabInfo()
                        .then(function(response) {
                            console.log(JSON.parse(JSON.stringify(response)));
                            var tabId = '';

                            //Check to make sure that you are changing the tab title for the right tab
                            switch(response.pageReference.type){
                                //If the pagereference is directly for the component
                                case 'standard__component':
                                    if(response.pageReference.attributes.componentName && response.pageReference.attributes.componentName == 'c__sObjectListAuraComponent'){
                                        tabId = response.tabId;
                                    }
                                    break;
                                //If the pagereference is for the parent record Page
                                case 'standard__recordPage':
                                    if(response.subtabs){
                                        response.subtabs.forEach(subtab => {
                                            if(subtab.pageReference.type == "standard__component"){
                                                if(subtab.pageReference.attributes.componentName && subtab.pageReference.attributes.componentName == 'c__sObjectListAuraComponent'){
                                                    tabId = subtab.tabId;
                                                }     
                                            }
                                        })
                                    }
                            }

                            workspaceAPI.setTabLabel({
                                tabId: tabId,
                                label: tabTitle
                            });
                            workspaceAPI.setTabIcon({
                                tabId: tabId,
                                icon: iconName,
                                iconAlt: tabTitle
                            });
                        })
                        .catch(function(error) {
                            console.log(JSON.parse(JSON.stringify(error)));
                        });
                }
      		})
			.catch(function(error) {
				console.log(error);
			});
	}
})