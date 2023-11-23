({
	setConsoleTabProperties : function(component, event) {
        //initialize the service components
    	var workspaceAPI = component.find("workspace");

        //Get data from Page Reference
        var pageRef = component.get('v.pageReference');
        var tabTitle = pageRef.state.c__title;
        var iconName = pageRef.state.c__iconName;
        
        //Assigning the data back to an attribute
        component.set('v.recordId', pageRef.state.c__recordId);
        component.set('v.sObjectName', pageRef.state.c__sObjectName);
        component.set('v.commaSeparatedRecordtypes', pageRef.state.c__commaSeparatedRecordtypes);
        component.set('v.fieldSetForColumns', pageRef.state.c__fieldSetForColumns);
        component.set('v.relationshipFieldNames', pageRef.state.c__relationshipFieldNames);
        component.set('v.hyperlinkFieldNames', pageRef.state.c__hyperlinkFieldNames);
        component.set('v.idField', pageRef.state.c__idField);
        component.set('v.condition', pageRef.state.c__condition);
        component.set('v.limitCount', pageRef.state.c__limitCount);
        component.set('v.sortStatement', pageRef.state.c__sortStatement);

        component.set('v.title', tabTitle);
        component.set('v.iconName', iconName);
        component.set('v.iconSize', pageRef.state.c__iconSize);
        component.set('v.displayType', pageRef.state.c__displayType);

        component.set('v.showHeader', pageRef.state.c__showHeader);
        component.set('v.showNewButton', pageRef.state.c__showNewButton);
        component.set('v.isHoverable', pageRef.state.c__isHoverable);
        component.set('v.allowTextWrapping', pageRef.state.c__allowTextWrapping);

        component.set('v.primaryRelationshipField', pageRef.state.c__primaryRelationshipField);
        component.set('v.fieldsDispalyedForTilesLayout', pageRef.state.c__fieldsDispalyedForTilesLayout);
        component.set('v.firstFieldLabeledDisplayed', pageRef.state.c__firstFieldLabeledDisplayed);
        component.set('v.viewAll', pageRef.state.c__viewAll);
        component.set('v.zIndex', pageRef.state.c__zIndex);
        
		//Set the console tab properties
        workspaceAPI
        	.isConsoleNavigation()
        	.then(function(isConsole) {
				if (isConsole) {
          			//in a console app - get the current focused tab
          			workspaceAPI.getFocusedTabInfo()
                        .then(function(response) {
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
                            console.error(JSON.parse(JSON.stringify(error)));
                        });
                }
      		})
			.catch(function(error) {
				console.error(error);
			});
	}
})