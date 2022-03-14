import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import New_SObject from '@salesforce/label/c.New_SObject';
import SOBject_Select_Recordtype from '@salesforce/label/c.SOBject_Select_Recordtype';

import getResponse from '@salesforce/apex/SObjectListController.getResponse';

export default class SobjectList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api title;
    @api iconName = 'standard:app';
    @api iconSize = 'small';
    @api sObjectName = '';
    @api commaSeparatedRecordtypes = '';
    @api fieldSetForColumns = '';
    @api relationshipFieldNames = '';
    @api condition = '';
    @api limitCount = 6;
    @api sortStatement = 'Name ASC';
    @api showNewButton;
    @api primaryRelationshipField = '';

    @api isLoaded = false;
    @api viewAll = false;

    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 
    @track isModalOpen = false;

    selectedrecordtypeId = '';

    label = {
        New_SObject,
        SOBject_Select_Recordtype
    };

    responseWrapper = {
        sObj: {
            records: [],
            displayCount: '0',
            recordtypesEnabled: false
        },
        permissions: {
            accessible: false,
            creatable: false
        }
    };

    connectedCallback(){
        //Check if the component is ready to make a call to Apex
        if(this.sObjectName && this.commaSeparatedRecordtypes && this.fieldSetForColumns && this.relationshipFieldNames){
            getResponse({
                recordId: this.recordId,
                requestWrapper: {
                    sObjectName: this.sObjectName,
                    commaSeparatedRecordtypes: this.commaSeparatedRecordtypes,
                    fieldSetForColumns: this.fieldSetForColumns,
                    additionalFields: this.additionalFields,
                    relationshipFieldNames: this.relationshipFieldNames,
                    condition: this.condition,
                    limitCount: this.limitCount,
                    sortStatement: this.sortStatement
                },
                viewAll: this.viewAll
            })
            .then(result => {
                console.log('response from Apex');
                console.log(result);
                var fields = JSON.parse(result.fieldDescribeResults);
                var records = this.formatData(result.sObj.lstSObjects, fields);
                var recordCount = result.sObj.fullCountOfSObjects;

                var displayCountString = '0';
                if(this.viewAll){
                    displayCountString = recordCount;
                } else {
                    if(this.limitCount <=0 || this.limitCount > 10){
                        this.limitCount = 10
                    }
    
                    if(recordCount <= this.limitCount){
                        displayCountString = recordCount; 
                    } else {
                        displayCountString = this.limitCount + '+';
                    }
                }
    
                this.responseWrapper.fields = fields;
                this.responseWrapper.sObj.label = result.sObj.sObjectLabel;
                this.responseWrapper.sObj.records = records;
                this.responseWrapper.sObj.displayCount = displayCountString;
                this.responseWrapper.sObj.recordtypesEnabled = result.sObj.recordtypesEnabled;
                this.responseWrapper.sObj.availableRecordtypes = result.sObj.availableRecordtypes;
                this.responseWrapper.parentSObj = result.parentSObj;
                this.responseWrapper.permissions = result.permissions;
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoaded = true;
            });
        }
    }

    get breadcrumbSobjectListURL(){
        return '/lightning/o/' + this.responseWrapper.parentSObj.name + '/list';
    }

    get breadcrumbSobjectURL(){
        return '/lightning/r/' + this.responseWrapper.parentSObj.name + '/' + this.recordId + '/view';
    }

    get modalHeader(){
        return this.formatLabel(this.label.New_SObject, this.responseWrapper.sObj.label);
    }

    get recordtypeOptions() {
        var options = [];

        this.responseWrapper.sObj.availableRecordtypes.forEach(rtInfo => {
            options.push({
                label: rtInfo.recordtypeName,
                value: rtInfo.recordtypeId
            })
        });

        return options;
    }

    createRecord() {
        if(this.responseWrapper.sObj.recordtypesEnabled && this.responseWrapper.sObj.availableRecordtypes.length > 0){
            if(this.responseWrapper.sObj.availableRecordtypes.length == 1){
                this.selectedrecordtypeId = this.responseWrapper.sObj.availableRecordtypes[0].recordtypeId;
                this.navigateToNewRecordPage();
            } else {
                this.isModalOpen = true;
            }
        } else {
            this.navigateToNewRecordPage();
        }
    }

    handleRecordtypeChange(event){
        this.selectedrecordtypeId = event.target.value;
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.selectedrecordtypeId = '';
    }

    navigateToNewRecordPage(){
        this.isModalOpen = false;

        var defaultValuesObj ={}
        
        //Check if Primary Relationship field is provided
        if(this.primaryRelationshipField){
            defaultValuesObj[this.primaryRelationshipField] = this.recordId;
        }

        const defaultValues = encodeDefaultFieldValues(defaultValuesObj);

        var stateObj = {
            nooverride: 1,
            useRecordTypeCheck: 1,
            defaultFieldValues: defaultValues
        };

        if(this.selectedrecordtypeId != ''){
            stateObj.recordTypeId = this.selectedrecordtypeId;
        }

        // Navigate to the new SObject Record
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.sObjectName,
                actionName: 'new'
            },
            state: stateObj
        });
    }

    navigateToViewAll() {
        var compDefinition = {
            componentDef: "c:sobjectList",
            attributes: {
                recordId: this.recordId,
                title: this.title,
                iconName: this.iconName,
                iconSize: 'medium',
                sObjectName: this.sObjectName,
                commaSeparatedRecordtypes: this.commaSeparatedRecordtypes,
                fieldSetForColumns: this.fieldSetForColumns,
                relationshipFieldNames: this.relationshipFieldNames,
                condition: this.condition,
                limitCount: this.limitCount,
                sortStatement: this.sortStatement,
                showNewButton: this.showNewButton,
                primaryRelationshipField: this.primaryRelationshipField,
                viewAll: true
            }
        };
        // Base64 encode the compDefinition JS object
        var encodedCompDef = btoa(JSON.stringify(compDefinition));
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/one/one.app#' + encodedCompDef
            }
        });
    }

    formatData(data, fields){
        debugger; 
        var lstObjectsNotNavigatable = ['RecordType'];
        var records = [];
        if(data){
            data.forEach(record => {
                var recordObj = new Object();
                recordObj.fields = [];
                recordObj.Id = record.Id;
                if(fields){
                    fields.forEach(field => {
                        var recordObjField = {
                            key: record.Id + field.name,
                            fieldDescribe: field,
                            recordId: record.Id
                        };

                        if(record.hasOwnProperty(field.name)){
                            recordObjField.value = record[field.name];
                        } else {
                            recordObjField.value = null;
                        }

                        //Change the record id and field value for reference fiekds
                        if(field.type == 'reference'){
                            if(record[field.relationshipName]){
                                recordObjField.value = record[field.relationshipName]['Name'];
                                recordObjField.recordId = record[field.relationshipName]['Id'];
                                recordObjField.isNavigatable = false;
                                if(field.referenceTo){
                                    field.referenceTo.forEach(referenceObjName => {
                                        //Only make it navigatable if the reference object name 
                                        //is not found in the list defined above 
                                        if(lstObjectsNotNavigatable.indexOf(referenceObjName) < 0){
                                            recordObjField.isNavigatable = true;
                                        }
                                    })
                                }
                            }
                        }
                        recordObj.fields.push(recordObjField);
                    });
                }

                records.push(recordObj);
            })     
        }

        return records;
    }

    formatLabel(stringToFormat, ...formattingArguments) {
        if (typeof stringToFormat !== 'string') throw new Error('\'stringToFormat\' must be a String');
        return stringToFormat.replace(/{(\d+)}/gm, (match, index) =>
            (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
    }
    
    handleError(error){
        debugger;
        console.error(error);
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error loading data',
                message,
                variant: 'error',
            }),
        );
    }
}