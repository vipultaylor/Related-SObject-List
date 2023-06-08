import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CustomOutputField extends NavigationMixin(LightningElement) {
    @api fieldDescribe;
    @api fieldValue;
    @api recordId;
    @api isNavigatable = false;
    @api currencyIsoCode;
    @api isHoverable = false;

    @track recordIdForPopover = false;
    @track containerBoundingBoxLeft;
    @track containerBoundingBoxRight;
    @track isPopoverActive = false;

    field = {
        properties: {
            isBoolean: false,
            isCurrency: false,
            isDate: false,
            isDateTime: false,
            isEmail: false,
            isName: false,
            isNumber: false,
            isPercent: false,
            isReference: false,
            isText: false,
            isTextArea: false,
            isURL: false,
        },
    }

    connectedCallback(){
        switch(this.fieldDescribe.type){
            case 'boolean': 
                this.field.properties.isBoolean = true;
                break;
            case 'currency': 
                this.field.properties.isCurrency = true;
                this.field.properties.scale = this.fieldDescribe.scale;
                break;
            case 'date': 
                this.field.properties.isDate = true;
                break;
            case 'datetime': 
                this.field.properties.isDateTime = true;
                break;
            case 'email': 
                this.field.properties.isEmail = true;
                break;
            case 'double': 
                this.field.properties.isNumber = true;
                this.field.properties.scale = this.fieldDescribe.scale;
                break;
            case 'percent': 
                this.field.properties.isPercent = true;
                this.field.properties.scale = this.fieldDescribe.scale;
                break;
            case 'reference': 
                this.field.properties.isReference = true;
                this.field.recordId = this.recordId;
                this.field.properties.isNavigatable = this.isNavigatable;
                this.field.properties.isHoverable = this.isHoverable;
                break;
            case 'textarea': 
                this.field.properties.isTextArea = true;
                break;
            case 'url': 
                this.field.properties.isURL = true;
                break;
            default:

                if(this.fieldDescribe.nameField){
                    this.field.properties.isName = true;
                    this.field.recordId = this.recordId;
                    this.field.properties.isHoverable = this.isHoverable;
                    //this.field.href = '/' + this.recordId;
                } else if(this.fieldValue!=null && this.fieldValue.endsWith("</a>")){
                    var hrefStart = this.fieldValue.indexOf("\"")+1;
                    var hrefEnd = this.fieldValue.indexOf("\"",hrefStart);
                    var href = this.fieldValue.substr(hrefStart, hrefEnd-hrefStart);
                    var displayStart =  this.fieldValue.indexOf(">")+1;
                    var displayEnd =  this.fieldValue.indexOf("<",displayStart);
                    var value = this.fieldValue.substr(displayStart, displayEnd-displayStart);
                    this.field.properties.isName = true;
                    this.field.value = value;
                    this.field.recordId = href;
                }
                else {
                    this.field.properties.isText = true;
                }
        }

        this.field.value = this.fieldValue;
        this.field.currencyIsoCode = this.currencyIsoCode;
    }

    get field(){
        return this.field;
    }


    navigateToRecordViewPage(event) {
        var recordId = event.currentTarget.getAttribute('data-recordid');

        if(recordId){
            // View a custom object record.
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view'
                }
            });
        }
    }

    handlePopoverStateChange(event){
        console.log(event.type, JSON.parse(JSON.stringify(event.detail)));
        this.isPopoverActive = event.detail.state === 'active';
    }

    showPopover(event){
        var containerBoundingBox = event.currentTarget.getBoundingClientRect();

        this.recordIdForPopover = null;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.recordIdForPopover = this.recordId;
            this.containerBoundingBoxLeft = containerBoundingBox.left;
            this.containerBoundingBoxRight = containerBoundingBox.right;
        }, 500);
    }

    hidePopover(event){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            if(!this.isPopoverActive){
                this.recordIdForPopover = null;
                this.containerBoundingBoxLeft = null;
                this.containerBoundingBoxRight = null;
            }
        }, 300);
    }

}