import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class CustomOutputField extends NavigationMixin(LightningElement) {
    @api fieldDescribe;
    @api fieldValue;
    @api recordId;
    @api currencyIsoCode;

	@api isNavigatable = false;
    @api isHoverable = false;
    @api allowTextWrapping = false;

    @track recordIdForPopover = false;
    @track containerBoundingBoxLeft;
    @track containerBoundingBoxRight;
    @track isPopoverActive = false;

    timeZone = TIME_ZONE;

    // Separate timeouts for show and hide to prevent conflicts
    showDelayTimeout;
    hideDelayTimeout;
    isHovering = false;

    fieldObj = {
        properties: {
            isBoolean: false,
            isCurrency: false,
            isDate: false,
            isDateTime: false,
            isEmail: false,
            isName: false,
            isNumber: false,
            isPercent: false,
            isPhone: false,
            isReference: false,
            isText: false,
            isTextArea: false,
            isRichTextArea: false,
            isTime: false,
            isURL: false,
        },
    }

    connectedCallback(){
		this.fieldObj.properties.isHoverable = this.isHoverable;
		this.fieldObj.properties.isNavigatable = this.isNavigatable;
		this.fieldObj.recordId = this.recordId;
		this.fieldObj.value = this.fieldValue;
        this.fieldObj.currencyIsoCode = this.currencyIsoCode;

		switch(this.fieldDescribe.type){
            case 'boolean':
                this.fieldObj.properties.isBoolean = true;
                break;
            case 'currency':
                this.fieldObj.properties.isCurrency = true;
                this.fieldObj.properties.scale = this.fieldDescribe.scale;
                break;
            case 'date':
                this.fieldObj.properties.isDate = true;
                break;
            case 'datetime':
                this.fieldObj.properties.isDateTime = true;
                break;
            case 'email':
                this.fieldObj.properties.isEmail = true;
                break;
            case 'double':
                this.fieldObj.properties.isNumber = true;
                this.fieldObj.properties.scale = this.fieldDescribe.scale;
                break;
            case 'percent':
                this.fieldObj.properties.isPercent = true;
                this.fieldObj.properties.scale = this.fieldDescribe.scale;
                break;
            case 'phone':
                this.fieldObj.properties.isPhone = true;
                break;
            case 'reference':
                this.fieldObj.properties.isReference = true;
                this.fieldObj.recordId = this.recordId;
                break;
            case 'textarea':
                if(this.fieldDescribe.htmlFormatted){
                    this.fieldObj.properties.isRichTextArea = true;
                } else {
                    this.fieldObj.properties.isTextArea = true;
                }
                break;
            case 'time':
                this.fieldObj.properties.isTime = true;
                break;
            case 'url':
                this.fieldObj.properties.isURL = true;
                break;
            default:

                if(this.fieldDescribe.nameField){
                    this.fieldObj.properties.isName = true;
                } else if(this.fieldValue!=null && this.fieldValue.endsWith("</a>")){
                    let hrefStart = this.fieldValue.indexOf("\"")+1;
                    let hrefEnd = this.fieldValue.indexOf("\"",hrefStart);
                    let href = this.fieldValue.substr(hrefStart, hrefEnd-hrefStart);
                    let displayStart =  this.fieldValue.indexOf(">")+1;
                    let displayEnd =  this.fieldValue.indexOf("<",displayStart);
                    let value = this.fieldValue.substr(displayStart, displayEnd-displayStart);
                    this.fieldObj.properties.isName = true;
                    this.fieldObj.value = value;
                    this.fieldObj.recordId = href;
                }
                else {
                    this.fieldObj.properties.isText = true;
                }
        }
    }

    get field(){
        return this.fieldObj;
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
        this.isPopoverActive = event.detail.value;
        // If popover became active, cancel any pending hide
        if (this.isPopoverActive) {
            window.clearTimeout(this.hideDelayTimeout);
        } else {
            // Popover requested to close (e.g., close button clicked)
            // Hide immediately without delay
            this.recordIdForPopover = null;
            this.containerBoundingBoxLeft = null;
            this.containerBoundingBoxRight = null;
        }
    }

    showPopover(event){
        // Cancel any pending hide operation
        window.clearTimeout(this.hideDelayTimeout);
        this.isHovering = true;

        // If popover is already showing for this record, don't restart
        if (this.recordIdForPopover === this.recordId) {
            return;
        }

        var containerBoundingBox = event.currentTarget.getBoundingClientRect();

        // Cancel any pending show operation and start fresh
        window.clearTimeout(this.showDelayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.showDelayTimeout = setTimeout(() => {
            // Only show if still hovering
            if (this.isHovering) {
                this.recordIdForPopover = this.recordId;
                this.containerBoundingBoxLeft = containerBoundingBox.left;
                this.containerBoundingBoxRight = containerBoundingBox.right;
            }
        }, 500);
    }

    hidePopover(){
        // Cancel any pending show operation
        window.clearTimeout(this.showDelayTimeout);
        this.isHovering = false;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.hideDelayTimeout = setTimeout(() => {
            // Only hide if not hovering and popover is not being interacted with
            if(!this.isHovering && !this.isPopoverActive){
                this.recordIdForPopover = null;
                this.containerBoundingBoxLeft = null;
                this.containerBoundingBoxRight = null;
            }
        }, 350);
    }

}