/**
 * @description     Wrapper class for SObject Request Information passed from Sobject List LWC Component
 * @author          Vipul Taylor   
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Wrapper
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class SObjectRequestWrapper {
    //SObject for which the records needs to be retrieved
    @AuraEnabled
    public String sObjectName {get; set;}

    //Recordtypes on which the records need to be filtered
    @AuraEnabled
    public String commaSeparatedRecordtypes {get; set;}

    //Field Set for the list of columns which need to be displayed
    @AuraEnabled
    public String fieldSetForColumns {get; set;}

    //Comma Separated Additional Fields that need to be queried
    @AuraEnabled
    public String additionalFields {get; set;}

    //Id Field through which the related records are associated to the parent record
    @AuraEnabled
    public String idField {get; set;}

    //Comma Separated Field Name(s) through which the related records are associated to the parent record
    @AuraEnabled
    public String relationshipFieldNames {get; set;}

    //Any additional condition that needs to be applied to the query
    @AuraEnabled
    public String condition {get; set;}

    //Query Limit condition
    @AuraEnabled
    public Integer limitCount {get; set;}

    //Query Sorting condition
    @AuraEnabled
    public String sortStatement {get; set;}
}