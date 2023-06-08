import { api, wire, LightningElement, track} from 'lwc';
import { getRecordUi } from 'lightning/uiRecordApi';

const NUBBIN_PADDING = 20;
const STATE = {
    LOADED: 'loaded',
    ACTIVE: 'active',
    CLOSED: 'closed'
};

const EVENT = {
    STATECHANGE: 'statechange'
};

export default class SobjectCompactLayoutOnHover extends LightningElement {
    @api recordId;
    @api containerBoundingBoxLeft;
    @api containerBoundingBoxRight;

    @track objectApiName;
    @track isLoaded = false;
    @track isPopoverActive = false;

    primaryObjectInfo = {};
    titleField = {};
    summaryFields = [];

    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: 'Compact', modes: 'View' })
    wiredRecord({ error, data }) {
        if (error) {
            this._handleError(error);
        } else if (data) {
            //console.log(data);

            //Set the Object Api Name
            this.objectApiName = data.records[this.recordId].apiName;

            //Get Layout Info
            let objectLayoutInfo = data.layouts[this.objectApiName];
            let layoutId = Object.keys(objectLayoutInfo)[0];
            let layoutInfo = objectLayoutInfo[layoutId];

            //Get Primary Object Info
            this.primaryObjectInfo = data.objectInfos[this.objectApiName];

            //Get Field Info
            let fieldsAsLayoutRows = layoutInfo.Compact.View.sections[0].layoutRows;

            fieldsAsLayoutRows.forEach((element, index) => {
                let fieldApiName = element.layoutItems[0].layoutComponents[0].apiName;
                
                //Set Field Describe by copying the data
                let fieldDescribe = JSON.parse(JSON.stringify(data.objectInfos[this.objectApiName].fields[fieldApiName]));
                fieldDescribe["type"] = fieldDescribe.dataType;

                //Set Field Value
                let fieldValue = data.records[this.recordId].fields[fieldApiName].value;
                if(fieldDescribe.dataType == 'Reference'){
                    fieldValue = data.records[this.recordId].fields[fieldDescribe.relationshipName].displayValue;
                }

                let field = {
                    fieldDescribe: fieldDescribe,
                    value: fieldValue
                };

                if(index == 0){
                    //Set the first field as title field
                    this.titleField = field;
                } else {
                    if(index < 5){
                        //Set the remaining fields from the compact layout
                        //up to a maximum of 4 values
                        this.summaryFields.push(field);
                    }
                }
            });

            this.isLoaded = true;
            this._dispatchEvent(EVENT.STATECHANGE, STATE.LOADED);
        }
    }

    renderedCallback(){
        let sectionElement = this.template.querySelector(".custom-popover-section");
        if(sectionElement){
            if(this.containerBoundingBoxLeft && this.containerBoundingBoxRight){
                var popoverXPos = this.containerBoundingBoxRight - this.containerBoundingBoxLeft + NUBBIN_PADDING;
                var popoverYPos = -25;
                sectionElement.style.left = popoverXPos + 'px';
                sectionElement.style.top = popoverYPos + 'px';
            }
        }

        let titleIconElement = this.template.querySelector(".custom-popover-title-icon");
        if(titleIconElement){
            titleIconElement.style["background-color"] = '#' + this.primaryObjectInfo.themeInfo.color;
        }

        let closeIconElement = this.template.querySelector(".slds-popover__close");
        if(closeIconElement){
            closeIconElement.focus();
        }
    }

    keepPopoverActive(){
        if(!this.isPopoverActive){
            this.isPopoverActive = true;
            this._dispatchEvent(EVENT.STATECHANGE, STATE.ACTIVE);
        }
    }

    closePopover(){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.isPopoverActive = false;
            this.isLoaded = false;
            this.recordId = null;
            this._dispatchEvent(EVENT.STATECHANGE, STATE.CLOSED);
        }, 150);
    }

    _dispatchEvent(eventName, stateName){
        //create custom event
        const popoverEvent = new CustomEvent(eventName, {
            detail: {
                recordId: this.recordId,
                state: stateName
            }
        });

        //dispatch event
        this.dispatchEvent(popoverEvent);
    }

    _handleError(error){
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
                message: message,
                variant: 'error',
            }),
        );
    }
}