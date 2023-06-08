/**
 * @description     Utilities class for shared functions
 * @author          Vipul Taylor   
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Utilities
 */
public with sharing class Utils {
    /**
     * @description     Custom Exception class for Utils
     */
    public class UtilsException extends Exception {}

    /**
     * @description         Get list of field set members for a given object and field set
     * @param  sObjectName  SObject name
     * @param  fieldSetName FieldSet name
     * @return              List of field set members
     */
    public static List<Schema.FieldSetMember> getFieldsForFieldSet(String sObjectName, String fieldSetName) {
        if(String.isBlank(fieldSetName)){
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

    /**
     * @description             Get list of fields set members for a given object, field set and any additional fields. 
     *                          By default always include the 'Id' field
     * @param  sObjectName      sObjectName description
     * @param  fieldSets        set of fieldsets
     * @param  additionalFields set of additional field names
     * @return                  list of fields
     */
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

    /**
     * @description      Get Set values for dynamic SOQL from a given set of strings
     * @param  stringSet Set of strings
     * @return           retur string in the ('a','b','c') format
     */
    public static String getSetValuesForDynamicSoql(Set<String> stringSet) {
        List<String> setValues = new List<String>();
        for(String val : stringSet){
            setValues.add('\'' + val + '\'');
        }
        return '(' + String.join(setValues, ',') + ')';
    }

    /**
     * @description  Get Set values for dynamic SOQL from a given set of Ids
     * @param  idSet Set of Ids
     * @return       retur string in the ('a','b','c') format
     */
    public static String getSetValuesForDynamicSoql(Set<Id> idSet) {
        List<String> setValues = new List<String>();
        for(Id val : idSet){
            setValues.add('\'' + val + '\'');
        }
        return '(' + String.join(setValues, ',') + ')';
    }
}