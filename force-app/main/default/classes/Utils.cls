/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Utilities class for shared functions.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Vipul Taylor
* @modifiedBy     Vipul Taylor
* @maintainedBy   Vipul Taylor
* @version        1.0
* @created        2022-03-12
* @systemLayer    Utilities
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class Utils {
    public class UtilsException extends Exception {}

    public static List<Schema.FieldSetMember> getFieldsForFieldSet(String sObjectName, String fieldSetName) {
        if(String.isEmpty(fieldSetName)){
            return new List<Schema.FieldSetMember>();
        }

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        if(!globalDescribe.containsKey(sObjectName)){
            throw new UtilsException('Invalid sObjectName ' + sObjectName);
        }

        //describe the provided sObject  
        Schema.DescribeSObjectResult res = globalDescribe.get(sObjectName).getDescribe();  

        //get the fields set map  
        Map<String, Schema.FieldSet> fieldSetMap = res.fieldSets.getMap();
        if(!fieldSetMap.containsKey(fieldSetName)){
            throw new UtilsException('Field Set ' + fieldSetName + ' does not exist for sobject ' + sObjectName);
        }

        return fieldSetMap.get(fieldSetName).getFields();
    }

    public static Set<String> getFieldListFromFieldSet(String sObjectName, Set<String> fieldSets, Set<String> additionalFields){
        Set<String> fields = new Set<String>{'Id'};

        //iterate through provided fieldsets 
        for(String fieldSetName : fieldSets){
            for( Schema.FieldSetMember fsm : getFieldsForFieldSet(sObjectName, fieldSetName) ) {
                //add only unique fields
                if(!fields.contains(fsm.getFieldPath())){  
                    //maintain a set of fields so that only unique fields are added  
                    fields.add(fsm.getFieldPath());
                }
            }
        }

        //iterate through additional fields
        for(String fieldName : additionalFields){
            //add only unique fields
            if(!fields.contains(fieldName)){  
                //maintain a set of fields so that only unique fields are added
                fields.add(fieldName);
            }
        }

        return fields;
    }

    public static String getSetValuesForDynamicSoql(Set<String> stringSet) {
        List<String> setValues = new List<String>();
        For(String val : stringSet){
            setValues.add('\'' + val + '\'');
        }
        return '(' + String.join(setValues, ',') + ')';
    }

    public static String getSetValuesForDynamicSoql(Set<Id> idSet) {
        List<String> setValues = new List<String>();
        For(Id val : idSet){
            setValues.add('\'' + val + '\'');
        }
        return '(' + String.join(setValues, ',') + ')';
    }
}