import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import { deleteRecord } from "lightning/uiRecordApi";

import New_SObject from "@salesforce/label/c.New_SObject";
import Delete_SObject from "@salesforce/label/c.Delete_SObject";
import Delete_SObject_Confirm from "@salesforce/label/c.Delete_SObject_Confirm";
import Delete_Success_Message from "@salesforce/label/c.Delete_Success_Message";

import Button_Cancel from "@salesforce/label/c.Button_Cancel";
import Button_Delete from "@salesforce/label/c.Button_Delete";
import Button_Next from "@salesforce/label/c.Button_Next";
import Button_View_All from "@salesforce/label/c.Button_View_All";
import Button_Close from "@salesforce/label/c.Button_Close";

import SOBject_Select_Recordtype from "@salesforce/label/c.SOBject_Select_Recordtype";

import getResponse from "@salesforce/apex/SObjectListController.getResponse";

export default class SobjectList extends NavigationMixin(LightningElement) {
	@api recordId;
	@api sObjectName = "";
	@api commaSeparatedRecordtypes = "";
	@api fieldSetForColumns = "";
	@api relationshipFieldNames = "";
	@api hyperlinkFieldNames = "";
	@api idField = "Id";
	@api condition = "";
	@api limitCount = 6;
	@api sortStatement = "CreatedDate DESC";

	@api title;
	@api iconName = "standard:app";
	@api iconSize = "small";
	@api displayType = "list";
	@api displayTypeViewAll = "list";

	@api showHeader;
	@api hideOnZeroRecords;
	@api showNewButton;
	@api isHoverable;
	@api allowTextWrapping;

	@api primaryRelationshipField = "";
	@api fieldsDispalyedForTilesLayout = 4;
	@api firstFieldLabeledDisplayed;
	@api columnsForSupportedLayouts = 1;

	@api viewAll = false;
	@api zIndex = 0;

	@track isLoaded = false;
	@track isRefreshing = false;
	@track hasRecords = false;
	@track hasRendered = false;

	//Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded
	@track isModalOpen = false;

	@track isNewModal = false;
	@track isDeleteModal = false;

	@track initialResponseWrapper;
	@track responseWrapper;

	sortedColumn;
    sortedDirection = 'asc';
	
	selectedrecordtypeId = "";
	selectedRecordIdForDelete = "";

	LABEL = {
		New_SObject,
		Delete_SObject,
		Delete_SObject_Confirm,
		Delete_Success_Message,
		Button_Cancel,
		Button_Delete,
		Button_Next,
		Button_View_All,
		Button_Close,
		SOBject_Select_Recordtype
	};

	connectedCallback() {
		if (!this.hasRendered) {
			this._getDataFromApex();
		}
	}

	renderedCallback() {
		if (!this.hasRendered) {
			let containerElement = this.template.querySelector(".custom-sobject-list-container");
			if (containerElement) {
				containerElement.style["z-index"] = this.zIndex;
				this.hasRendered = true;
			}
		}
	}

	get isListLayout() {
		return this.displayType === "list";
	}

	get isTilesLayout() {
		return this.displayType === "tiles";
	}

	get isBoardLayout() {
		return this.displayType === "board";
	}

	get breadcrumbSobjectListURL() {
		return "/lightning/o/" + this.responseWrapper.parentSObj.name + "/list";
	}

	get breadcrumbSobjectURL() {
		return ("/lightning/r/" + this.responseWrapper.parentSObj.name + "/" + this.recordId + "/view");
	}

	get modalHeader() {
		let modalHeader;
		if (this.isNewModal) {
			modalHeader = this._formatLabel(this.LABEL.New_SObject, this.responseWrapper.sObj.label);
		} else if (this.isDeleteModal) {
			modalHeader = this._formatLabel(this.LABEL.Delete_SObject, this.responseWrapper.sObj.label);
		}

		return modalHeader;
	}

	get buttonCancel() {
		return this.LABEL.Button_Cancel;
	}

	get buttonDelete() {
		return this.LABEL.Button_Delete;
	}

	get buttonNext() {
		return this.LABEL.Button_Next;
	}

	get buttonViewAll() {
		return this.LABEL.Button_View_All;
	}

	get buttonClose() {
		return this.LABEL.Button_Close;
	}

	get deleteConfirmationMessage() {
		return this._formatLabel(this.LABEL.Delete_SObject_Confirm, this.responseWrapper.sObj.label.toLowerCase());
	}

	get recordtypeOptions() {
		var options = [];
		
		this.responseWrapper.sObj.availableRecordtypes.forEach((rtInfo) => {
			options.push({
				label: rtInfo.recordtypeName,
				value: rtInfo.recordtypeId
			});
		});

		return options;
	}

	get tilesLayoutColumnClass() {
		var columnClasses = "slds-item slds-col slds-m-bottom_small slds-size_1-of-1 ";
		var columnsForSupportedLayouts = this.columnsForSupportedLayouts;

		if(!columnsForSupportedLayouts || columnsForSupportedLayouts === 0 || columnsForSupportedLayouts > 3){
			columnsForSupportedLayouts = 1;
		}

		if(columnsForSupportedLayouts === 2){
			columnClasses += "slds-medium-size_1-of-2 slds-large-size_1-of-2";
		}
		else if(columnsForSupportedLayouts === 3){
			columnClasses += "slds-medium-size_1-of-3 slds-large-size_1-of-3";
		}
		
		return columnClasses;
	}

	get boardLayoutColumnClass() {
		var columnClasses = "slds-item slds-col slds-size_1-of-1 ";
		var columnsForSupportedLayouts = this.columnsForSupportedLayouts;

		if(!columnsForSupportedLayouts || columnsForSupportedLayouts === 0 || columnsForSupportedLayouts > 3){
			columnsForSupportedLayouts = 1;
		}

		if(columnsForSupportedLayouts === 2){
			columnClasses += "slds-medium-size_1-of-2 slds-large-size_1-of-2";
		}
		else if(columnsForSupportedLayouts === 3){
			columnClasses += "slds-medium-size_1-of-3 slds-large-size_1-of-3";
		}
		
		return columnClasses;
	}

	refreshData() {
		this.isRefreshing = true;
		this._getDataFromApex();
	}

	createRecord() {
		if (this.responseWrapper.sObj.recordtypesEnabled 
				&& this.responseWrapper.sObj.availableRecordtypes.length > 0) {
			if (this.responseWrapper.sObj.availableRecordtypes.length === 1) {
				this.selectedrecordtypeId =
				this.responseWrapper.sObj.availableRecordtypes[0].recordtypeId;
				this.navigateToNewRecordPage();
			} else {
				this.isNewModal = true;
				this.isModalOpen = true;
			}
		} else {
			this.navigateToNewRecordPage();
		}
	}

	handleRecordtypeChange(event) {
		this.selectedrecordtypeId = event.target.value;
	}

	editRecord(event) {
		// Navigate to the new SObject Record
		this[NavigationMixin.Navigate]({
			type: "standard__objectPage",
			attributes: {
				recordId: event.target.value,
				objectApiName: this.sObjectName,
				actionName: "edit"
			}
		});
	}

	deleteRecord(event) {
		this.selectedRecordIdForDelete = event.target.value;
		this.isDeleteModal = true;
		this.isModalOpen = true;
	}

	handleDelete() {
		var deleteId = this.selectedRecordIdForDelete;

		this.isModalOpen = false;

		//Get Record Name
		let recordName = "";
		for (let recordIndex in this.responseWrapper.sObj.records) {
			if (Object.hasOwn(this.responseWrapper.sObj.records, recordIndex)) {
				let record = this.responseWrapper.sObj.records[recordIndex];
				if (record.Id === this.selectedRecordIdForDelete) {
					for (let fieldIndex in record.fields) {
						if (Object.hasOwn(record.fields, fieldIndex)) {
							let field = record.fields[fieldIndex];
							if (field.fieldDescribe.nameField) {
								recordName = field.value;
								break;
							}
						}
					}
				}
			}
		}

		// Pass the record id to deleteRecord method
		deleteRecord(deleteId)
			.then(() => {
				this.dispatchEvent(
					new ShowToastEvent({
						message: this._formatLabel(this.LABEL.Delete_Success_Message, this.responseWrapper.sObj.label, recordName),
						variant: "success"
					})
				);

				// Delete the record from UI
				for (let recordIndex in this.responseWrapper.sObj.records) {
					if (Object.hasOwn(this.responseWrapper.sObj.records, recordIndex)) {
						let record = this.responseWrapper.sObj.records[recordIndex];
						if (record.Id === this.selectedRecordIdForDelete) {
							this.responseWrapper.sObj.records.splice(recordIndex, 1);
							break;
						}
					}
				}

				// Update record counts
				this._setRecordCounts(this.responseWrapper.sObj.records.length);
			})
			.catch((error) => {
				this._handleError(error);
			})
			.finally(() => {
				this._resetVariables();
			});
	}

	sortRecords( event ) {
		let fieldIndex = event.currentTarget.getAttribute('data-index');
		let fieldName = event.currentTarget.getAttribute('data-name');

		console.log('fieldIndex: ' + fieldIndex +', fieldName: ' + fieldName);
	
		//set the sorted direction
		if ( this.sortedColumn === fieldName ) {
			this.sortedDirection = ( this.sortedDirection === 'asc' ? 'desc' : 'asc' );
		}
		else {
			this.sortedDirection = 'asc';
		}

		let isReverse = this.sortedDirection === 'asc' ? 1 : -1;
	
		this.sortedColumn = fieldName;
	
		// sort the data
		this.responseWrapper.sObj.records = JSON.parse(JSON.stringify(this.responseWrapper.sObj.records)).sort((a, b) => {
			a = a.fields[fieldIndex].value ? a.fields[fieldIndex].value.toLowerCase() : ''; // Handle null values
			b = b.fields[fieldIndex].value ? b.fields[fieldIndex].value.toLowerCase() : '';
			return a >= b ? 1 * isReverse : -1 * isReverse;
		});

		//update the index for the records
		this.responseWrapper.sObj.records.forEach((record, recordIndex) => {
			record.index = recordIndex + 1;
		})
		
		//update the sorting icon
		this.responseWrapper.fields.forEach((field) => {
			if(field.name === fieldName){
				field.sortIcon = this.sortedDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
			} else {
				field.sortIcon = undefined;
			}
		})
	}

	closeModal() {
		// to close modal set isModalOpen tarck value as false
		this.isModalOpen = false;
		this._resetVariables();
	}

	navigateToNewRecordPage() {
		this.isModalOpen = false;
		
		let defaultValuesObj = {};

		//Check if Primary Relationship field is provided
		if (this.primaryRelationshipField) {
			defaultValuesObj[this.primaryRelationshipField] = this.responseWrapper.parentSObj.recordId;
		}

		const defaultValues = encodeDefaultFieldValues(defaultValuesObj);

		let stateObj = {
			nooverride: 1,
			useRecordTypeCheck: 1,
			defaultFieldValues: defaultValues
		};

		if (this.selectedrecordtypeId !== "") {
			stateObj.recordTypeId = this.selectedrecordtypeId;
		}

		// Navigate to the new SObject Record
		this[NavigationMixin.Navigate]({
			type: "standard__objectPage",
			attributes: {
				objectApiName: this.sObjectName,
				actionName: "new"
			},
			state: stateObj
		});
	}

	navigateToViewAll() {
		var displayTypeData = this.displayType;
		if(this.displayTypeViewAll){
			displayTypeData = this.displayTypeViewAll;
		}

		this[NavigationMixin.Navigate]({
			type: "standard__component",
			attributes: {
				componentName: "c__sObjectListAuraComponent" //aura component name
			},
			state: {
				c__recordId: this.recordId,
				c__sObjectName: this.sObjectName,
				c__commaSeparatedRecordtypes: this.commaSeparatedRecordtypes,
				c__fieldSetForColumns: this.fieldSetForColumns,
				c__relationshipFieldNames: this.relationshipFieldNames,
				c__hyperlinkFieldNames: this.hyperlinkFieldNames,
				c__idField: this.idField,
				c__condition: this.condition,
				c__limitCount: this.limitCount,
				c__sortStatement: this.sortStatement,

				c__title: this.title,
				c__iconName: this.iconName,
				c__iconSize: "medium",
				c__displayType: displayTypeData,

				c__showHeader: this.showHeader,
				c__showNewButton: this.showNewButton,
				c__isHoverable: this.isHoverable,
				c__allowTextWrapping: this.allowTextWrapping,

				c__primaryRelationshipField: this.primaryRelationshipField,
				c__fieldsDispalyedForTilesLayout: this.fieldsDispalyedForTilesLayout,
				c__firstFieldLabeledDisplayed: this.firstFieldLabeledDisplayed,
				c__viewAll: true,
				c__zIndex: this.zIndex
			}
		});
	}

	_resetResponsWrapper() {
		this.responseWrapper = undefined;

		this.responseWrapper = {
			sObj: {
				records: [],
				displayCount: "0",
				recordtypesEnabled: false
			},
			parentSObj: {
				name: "",
				recordName: "",
				labelPlural: ""
			},
			permissions: {
				accessible: this.isRefreshing,
				creatable: false,
				updatable: false,
				deletable: false
			},
			displayComponent: false
		};
	}

	_resetVariables() {
		// reset any other variables
		this.isNewModal = false;
		this.isDeleteModal = false;
		this.selectedrecordtypeId = "";
		this.selectedRecordIdForDelete = "";
	}

	_getDataFromApex() {
		//Reset Data every time before the apex is called
		//to ensure that the display is refreshed when the refresh method is called
		this._resetResponsWrapper();

		//Check if the component is ready to make a call to Apex
		if ( this.recordId && this.sObjectName && this.commaSeparatedRecordtypes && this.fieldSetForColumns && this.idField && this.relationshipFieldNames) {
			getResponse({
				recordId: this.recordId,
				requestWrapper: {
					sObjectName: this.sObjectName,
					commaSeparatedRecordtypes: this.commaSeparatedRecordtypes,
					fieldSetForColumns: this.fieldSetForColumns,
					additionalFields: this.additionalFields,
					relationshipFieldNames: this.relationshipFieldNames,
					idField: this.idField,
					condition: this.condition,
					limitCount: this.limitCount,
					sortStatement: this.sortStatement
				},
				viewAll: this.viewAll
			})
			.then((result) => {
				let fields = JSON.parse(result.fieldDescribeResults);
				let records = this._formatData(result.sObj.lstSObjects, fields);

				this.responseWrapper.fields = fields;
				this.responseWrapper.sObj.label = result.sObj.sObjectLabel;
				this.responseWrapper.sObj.records = records;
				this.responseWrapper.sObj.recordtypesEnabled = result.sObj.recordtypesEnabled;
				this.responseWrapper.sObj.availableRecordtypes = result.sObj.availableRecordtypes;
				this.responseWrapper.parentSObj = result.parentSObj;
				this.responseWrapper.permissions = result.permissions;

				console.log(JSON.parse(JSON.stringify(this.responseWrapper)));

				this._setRecordCounts(result.sObj.fullCountOfSObjects);
			})
			.catch((error) => {
				this._handleError(error);
			})
			.finally(() => {
				this.isLoaded = true;
				this.isRefreshing = false;
			});
		}
	}

	_setRecordCounts(recordCount) {
		var displayCountString = "0";

		if (recordCount > 0) {
			this._hasRecords(true);

			if (this.viewAll) {
				displayCountString = recordCount;
			} else {
				if (this.limitCount <= 0 || this.limitCount > 10) {
					// eslint-disable-next-line @lwc/lwc/no-api-reassignments
					this.limitCount = 10;
				}

				if (recordCount <= this.limitCount) {
					displayCountString = recordCount;
				} else {
					displayCountString = this.limitCount + "+";
				}
			}
		} else {
			this._hasRecords(false);
		}

		//Set the display count
		this.responseWrapper.sObj.displayCount = displayCountString;
	}

	_hasRecords(hasRecords){
		this.hasRecords = hasRecords;
		this.responseWrapper.displayComponent = this.responseWrapper.permissions.accessible 
									&& (hasRecords || (!hasRecords && !this.hideOnZeroRecords));
	}

	_formatData(data, fields) {
		var lstObjectsNotNavigatable = ["RecordType"];
		var records = [];

		var hyperlinkFields = new Array();
		if(this.hyperlinkFieldNames){
			hyperlinkFields = this.hyperlinkFieldNames.split(",");
		}

		if (data) {
			data.forEach((record, recordIndex) => {
				var recordObj = {};
				recordObj.index = recordIndex + 1;
				recordObj.fields = [];
				recordObj.Id = record.Id;
				if (fields) {
					fields.forEach((field, fieldIndex) => {
						var recordObjField = {
							key: record.Id + field.name,
							fieldDescribe: field,
							recordId: record.Id,
							tilesLayout: {
								displayField: fieldIndex < this.fieldsDispalyedForTilesLayout ? true : false,
								displayLabel: fieldIndex === 0 && !this.firstFieldLabeledDisplayed ? false : true
							}
						};
						
						if (Object.prototype.hasOwnProperty.call(record, field.name)) {
							recordObjField.value = record[field.name];
						} else {
							recordObjField.value = null;
						}
						
						//Change the record id and field value for reference fields
						if (field.type === "reference") {
							if (record[field.relationshipName]) {
								// eslint-disable-next-line dot-notation
								recordObjField.value = record[field.relationshipName]["Name"];
								// eslint-disable-next-line dot-notation
								recordObjField.recordId = record[field.relationshipName]["Id"];
								recordObjField.isNavigatable = false;
								if (field.referenceTo) {
									field.referenceTo.forEach((referenceObjName) => {
										//Only make it navigatable if the reference object name
										//is not found in the list defined above
										if (lstObjectsNotNavigatable.indexOf(referenceObjName) < 0) {
											recordObjField.isNavigatable = true;
										}
									});
								}
							}
						}

						//Change the record id and field value for reference fiekds
						if(hyperlinkFields.indexOf(field.name) >= 0){
							//Add 
							recordObjField.recordId = record.Id;
							recordObjField.isNavigatable = true;
						}

						recordObj.fields.push(recordObjField);
					});
				}
				
				records.push(recordObj);
			});
		}
		
		return records;
	}

	_formatLabel(stringToFormat, ...formattingArguments) {
		if (typeof stringToFormat !== "string")
		throw new Error("'stringToFormat' must be a String");
		// eslint-disable-next-line no-confusing-arrow
		return stringToFormat.replace(/{(\d+)}/gm, (match, index) => formattingArguments[index] === undefined ? "" : `${formattingArguments[index]}`);
	}

	_handleError(error) {
		console.error(error);
		let message = "Unknown error";
		if (Array.isArray(error.body)) {
			message = error.body.map((e) => e.message).join(", ");
		} else if (typeof error.body.message === "string") {
			message = error.body.message;
		}
		
		this.dispatchEvent(
			new ShowToastEvent({
				message: message,
				variant: "error"
			})
		);
	}
}