/**
* -------------------------------------------------------------------------------------------------+
* Controller class for SObject List LWC Component.
* --------------------------------------------------------------------------------------------------
* @author         Vipul Taylor   
* @modifiedBy     Vipul Taylor
* @maintainedBy   Vipul Taylor
* @version        1.0
* @created        2022-03-12
* @systemLayer    Controller
* --------------------------------------------------------------------------------------------------+
*/
public with sharing class SObjectListController {
    @AuraEnabled
    public static SObjectResponseWrapper getResponse(String recordId, SObjectRequestWrapper requestWrapper, Boolean viewAll){
        return SObjectService.getResponse(recordId, requestWrapper, viewAll);
    }
}