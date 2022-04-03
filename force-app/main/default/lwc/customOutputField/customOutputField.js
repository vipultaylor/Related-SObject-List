import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class CustomOutputField extends NavigationMixin(LightningElement) {
    @api fielddescribe;
    @api fieldvalue;
    @api recordid;
    @api isnavigatable = false;
    @api currencyisocode;

    get field(){
        if(this.fielddescribe.name == 'Description'){
            console.log('customOutputField fielddescribe');
            console.log(JSON.parse(JSON.stringify(this.fielddescribe)));
        }
        var fieldObj = {
            properties: {
                isBoolean: false,
                isCurrency: false,
                isDate: false,
                isDateTime: false,
                isNumber: false,
                isName: false,
                isText: false,
                isTextArea: false,
                isPercent: false,
                isReference: false,
            },
            value: this.fieldvalue,
            currencyIsoCode: this.currencyisocode
        };

        switch(this.fielddescribe.type){
            case 'boolean': 
                fieldObj.properties.isBoolean = true;
                break;
            case 'currency': 
                fieldObj.properties.isCurrency = true;
                fieldObj.properties.scale = this.fielddescribe.scale;
                break;
            case 'date': 
                fieldObj.properties.isDate = true;
                break;
            case 'datetime': 
                fieldObj.properties.isDateTime = true;
                break;
            case 'double': 
                fieldObj.properties.isNumber = true;
                fieldObj.properties.scale = this.fielddescribe.scale;
                break;
            case 'percent': 
                fieldObj.properties.isPercent = true;
                fieldObj.properties.scale = this.fielddescribe.scale;
                break;
            case 'reference': 
                fieldObj.properties.isReference = true;
                fieldObj.recordid = this.recordid;
                fieldObj.properties.isNavigatable = this.isnavigatable;
                break;
            case 'textarea': 
                fieldObj.properties.isTextArea = true;
                break;
            default:

                if(this.fielddescribe.nameField){
                    fieldObj.properties.isName = true;
                    fieldObj.recordid = this.recordid;
                    //fieldObj.href = '/' + this.recordid;
                } else if(this.fieldvalue!=null && this.fieldvalue.endsWith("</a>")){
                    var hrefStart = this.fieldvalue.indexOf("\"")+1;
                    var hrefEnd = this.fieldvalue.indexOf("\"",hrefStart);
                    var href = this.fieldvalue.substr(hrefStart,hrefEnd-hrefStart);
                    var displayStart =  this.fieldvalue.indexOf(">")+1;
                    var displayEnd =  this.fieldvalue.indexOf("<",displayStart);
                    var value = this.fieldvalue.substr(displayStart,displayEnd-displayStart);
                    fieldObj.properties.isName = true;
                    fieldObj.value = value;
                    fieldObj.recordid = href;
                }
                else {
                    fieldObj.properties.isText = true;
                }
        }

        return fieldObj;
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