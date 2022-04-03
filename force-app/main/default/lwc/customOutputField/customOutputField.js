import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CustomOutputField extends NavigationMixin(LightningElement) {
    @api fielddescribe;
    @api fieldvalue;
    @api recordid;
    @api isnavigatable = false;
    @api currencyisocode;

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
        switch(this.fielddescribe.type){
            case 'boolean': 
                this.field.properties.isBoolean = true;
                break;
            case 'currency': 
                this.field.properties.isCurrency = true;
                this.field.properties.scale = this.fielddescribe.scale;
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
                this.field.properties.scale = this.fielddescribe.scale;
                break;
            case 'percent': 
                this.field.properties.isPercent = true;
                this.field.properties.scale = this.fielddescribe.scale;
                break;
            case 'reference': 
                this.field.properties.isReference = true;
                this.field.recordid = this.recordid;
                this.field.properties.isNavigatable = this.isnavigatable;
                break;
            case 'textarea': 
                this.field.properties.isTextArea = true;
                break;
            case 'url': 
                this.field.properties.isURL = true;
                break;
            default:

                if(this.fielddescribe.nameField){
                    this.field.properties.isName = true;
                    this.field.recordid = this.recordid;
                    //this.field.href = '/' + this.recordid;
                } else if(this.fieldvalue!=null && this.fieldvalue.endsWith("</a>")){
                    var hrefStart = this.fieldvalue.indexOf("\"")+1;
                    var hrefEnd = this.fieldvalue.indexOf("\"",hrefStart);
                    var href = this.fieldvalue.substr(hrefStart, hrefEnd-hrefStart);
                    var displayStart =  this.fieldvalue.indexOf(">")+1;
                    var displayEnd =  this.fieldvalue.indexOf("<",displayStart);
                    var value = this.fieldvalue.substr(displayStart, displayEnd-displayStart);
                    this.field.properties.isName = true;
                    this.field.value = value;
                    this.field.recordid = href;
                }
                else {
                    this.field.properties.isText = true;
                }
        }

        this.field.value = this.fieldvalue;
        this.field.currencyIsoCode = this.currencyisocode;
    }

    get field(){
        return this.field;
    }


    navigateToRecordViewPage(event) {
        var recordId = event.currentTarget.getAttribute('data-recordid');

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