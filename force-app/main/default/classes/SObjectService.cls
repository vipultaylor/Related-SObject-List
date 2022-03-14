/**
* -------------------------------------------------------------------------------------------------+
* Service class for SObject List LWC Component.
* --------------------------------------------------------------------------------------------------
* @author         Vipul Taylor   
* @modifiedBy     Vipul Taylor
* @maintainedBy   Vipul Taylor
* @version        1.0
* @created        2022-03-12
* @systemLayer    Service
* --------------------------------------------------------------------------------------------------+
*/
public with sharing class SObjectService {
    public class SObjectServiceException extends Exception {}

    private final static String ALL_RECORDTYPES = 'ALL_RECORDTYPES';
    private final static Integer MAX_LIMIT_COUNT = 10;
    private final static Integer MAX_FULLVIEW_LIMIT_COUNT = 2000;

    public static SObjectResponseWrapper getResponse(String recordId, SObjectRequestWrapper requestWrapper, Boolean viewAll){
        //Validate Wrapper
        validateWrapper(recordId, requestWrapper);

        SObjectResponseWrapper response = new SObjectResponseWrapper();

        //Check If the object is accessible
        Schema.DescribeSObjectResult sobjDescribe = Schema.getGlobalDescribe().get(requestWrapper.sObjectName).getDescribe();

        if(sobjDescribe.isAccessible()){
            //Get Field Describe Information
            List<Schema.DescribeFieldResult> fieldDescribeResults = getFieldDescribe(requestWrapper);

            //Check if the user can access at least one field
            if(fieldDescribeResults.size() > 0){
                List<String> referenceFields = new List<String>();
                For(Schema.DescribeFieldResult dfr : fieldDescribeResults){
                    //Check if the field is of type reference
                    if(dfr.type == Schema.DisplayType.REFERENCE){
                        referenceFields.add(dfr.relationshipName + '.Name');
                    }
                }
        
                if(referenceFields.size() > 0){
                    requestWrapper.additionalFields = String.join(referenceFields, ',');
                }

                Schema.DescribeSObjectResult parentSobjDescribe = ((Id) recordId).getSObjectType().getDescribe();
                List<SObject> lstRecordDetails = Database.query('SELECT Name FROM ' + parentSobjDescribe.getName() + ' WHERE Id = \'' + recordId + '\'');
        
                //Add Parent SObject details to the response
                response.parentSObj.recordId = recordId;
                response.parentSObj.recordName = (String) lstRecordDetails[0].get('Name');
                response.parentSObj.name = parentSobjDescribe.getName();
                response.parentSObj.label = parentSobjDescribe.getLabel();
                response.parentSObj.labelPlural = parentSobjDescribe.getLabelPlural();

                //Add Permisssions to the response
                response.permissions.accessible = true;
                response.permissions.creatable = sobjDescribe.isCreateable();

                //Add Field Describe Results to the response
                response.fieldDescribeResults = JSON.serialize(fieldDescribeResults);

                //Add SObject Records to the response
                response.sObj = getSObjectRecords(recordId, requestWrapper, viewAll);
            }

        }

        return response;
    }

    private static List<Schema.DescribeFieldResult> getFieldDescribe(SObjectRequestWrapper requestWrapper) {
        List<Schema.DescribeFieldResult> lstDescribeFieldResult = new List<Schema.DescribeFieldResult>();

        // Field Set
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(requestWrapper.sObjectName).getDescribe().fields.getMap();
        For(Schema.FieldSetMember fsm : Utils.getFieldsForFieldSet(requestWrapper.sObjectName, requestWrapper.fieldSetForColumns)){
            Schema.DescribeFieldResult dfr = fieldMap.get(fsm.getFieldPath()).getDescribe();

            if(dfr.isAccessible()){
                lstDescribeFieldResult.add(dfr);
            }
        }

        return lstDescribeFieldResult;
    }

    private static SObjectResponseWrapper.SObj getSObjectRecords(String recordId, SObjectRequestWrapper requestWrapper, Boolean viewAll){
        //Initiate the object for response
        SObjectResponseWrapper.SObj sObjResponse = new SObjectResponseWrapper.SObj();

        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(requestWrapper.sObjectName);
        // Get the Describe Result
        Schema.DescribeSObjectResult sObjDescribe = sObjType.getDescribe();

        //Check if Recordtypes are enabled for this object or not
        List<RecordType> lstRecordtypes = [SELECT Id FROM RecordType WHERE SObjectType =: requestWrapper.sObjectName];

        //RecordtypeIdSet for SObject Query
        Set<Id> recordtypeIdSet = new Set<Id>();

        if(lstRecordtypes.size() > 0){
            sObjResponse.recordtypesEnabled = true;

            // Obtain the RecordTypeInfos for this SObjectType token
            Map<Id,Schema.RecordTypeInfo> recordTypeInfos = sObjDescribe.getRecordTypeInfosByID();

            //Filter out all the requested recordtype ids based on the comma separated recordtype names
            For(Id recordtypeId : recordTypeInfos.keySet()){
                Schema.RecordTypeInfo rtInfo = recordTypeInfos.get(recordtypeId);
                //Check if the recordtype is in the list of requested recordtypes
                if(requestWrapper.commaSeparatedRecordtypes != ALL_RECORDTYPES){
                    For(String recordTypeName : requestWrapper.commaSeparatedRecordtypes.split(',')){
                        if(rtInfo.getDeveloperName() == recordTypeName){
                            recordtypeIdSet.add(rtInfo.getRecordTypeId());
    
                            //Check if this recordtype is active and available for the current user
                            if(rtInfo.isActive() && rtInfo.isAvailable() && rtInfo.getName() != 'Master'){
                                sObjResponse.availableRecordtypes.add(new SObjectResponseWrapper.RecordtypeInfo(rtInfo.getRecordTypeId(), rtInfo.getName()));
                            }
                        }
                    }
                } else {
                    //All Recordtypes are requested
                    //So no need to provide any Ids in the id set
                    //as we will ignore the filter condition for the recordtypes
                    //But we still need to filter out only active and available recordtypes
                    if(rtInfo.isActive() && rtInfo.isAvailable() && rtInfo.getName() != 'Master'){
                        sObjResponse.availableRecordtypes.add(new SObjectResponseWrapper.RecordtypeInfo(rtInfo.getRecordTypeId(), rtInfo.getName()));
                    }
                }
            }
        }

        //Check if we didn't request All recordtypes 
        //and if the requested recordtypes couldn't be matched to any recordtype for the SObject
        if(requestWrapper.commaSeparatedRecordtypes != ALL_RECORDTYPES && recordtypeIdSet.size() == 0){
            return new SObjectResponseWrapper.SObj();
        }

        List<SObject> lstSObjects = querySObjectRecords(recordId, requestWrapper, recordtypeIdSet, viewAll);
        List<SObject> lstAllSObjects = querySObjectRecords(recordId, requestWrapper, recordtypeIdSet, true);

        sObjResponse.sObjectLabel = sObjDescribe.getLabel();
        sObjResponse.lstSObjects = lstSObjects;
        sObjResponse.fullCountOfSObjects = lstAllSObjects.size();

        return sObjResponse;
    }

    private static List<SObject> querySObjectRecords(String recordId, SObjectRequestWrapper requestWrapper, Set<Id> recordtypeIdSet, Boolean viewAll){
        //Get a distinct list of fields
        //Id field is included by default
        Set<String> sObjectFields = Utils.getFieldListFromFieldSet(requestWrapper.sObjectName, new Set<String>{requestWrapper.fieldSetForColumns}, new Set<String>(requestWrapper.additionalFields.split(',')));

        //Build the query
        //Include the fields in the query
        String query = 'SELECT ' + String.join(new List<String>(sObjectFields),',');
            
        //Specify the SObject
        query += ' FROM ' + requestWrapper.sObjectName;

        //Specify the relationship filters
        List<String> relationshipFilters = new List<String>();
        For(String fieldName : requestWrapper.relationshipFieldNames.split(',')){
            relationshipFilters.add(' ' + fieldName + '= \'' + recordId + '\'');
        }
        query += ' WHERE (' + String.join(relationshipFilters, ' OR ') + ')';
        
        //Check if All Recordtypes should be included in the result
        if(requestWrapper.commaSeparatedRecordtypes != ALL_RECORDTYPES){
            //Add recordtype conditions
            query += ' AND RecordtypeId in ' + Utils.getSetValuesForDynamicSoql(recordtypeIdSet);
        }

        //Add any additional conditions
        if(String.isNotEmpty(requestWrapper.condition)){
            query += ' AND ' + requestWrapper.condition;
        }

        //Sorting
        if(String.isNotEmpty(requestWrapper.sortStatement)){
            query += ' ORDER BY ' + requestWrapper.sortStatement;
        }

        //Limit
        Integer limitCount = requestWrapper.limitCount;

        if(viewAll){
            limitCount = MAX_FULLVIEW_LIMIT_COUNT;
        } else if(requestWrapper.limitCount <= 0 || requestWrapper.limitCount > MAX_LIMIT_COUNT){
            limitCount = MAX_LIMIT_COUNT;
        }

        if(limitCount > 0) {
            query += ' LIMIT ' + limitCount;
        }

        System.debug(LoggingLevel.DEBUG, 'SObject List Query: ' + query);
        return Database.query(query);
    }

    private static void validateWrapper(String recordId, SObjectRequestWrapper requestWrapper){
        if(requestWrapper == null){
            throw new SObjectServiceException(System.Label.Error_SObject_Information_Missing);
        }

        if(String.isEmpty(requestWrapper.sObjectName)){
            throw new SObjectServiceException(System.Label.Error_SObject_Name_Missing);
        }

        if(String.isEmpty(requestWrapper.commaSeparatedRecordtypes)){
            throw new SObjectServiceException(String.format(System.Label.Error_Recordtypes_Missing, new List<Object>{ requestWrapper.sObjectName }));
        }

        if(String.isEmpty(requestWrapper.fieldSetForColumns)){
            throw new SObjectServiceException(String.format(System.Label.Error_Fieldset_Missing, new List<Object>{ requestWrapper.sObjectName }));
        }

        if(String.isEmpty(requestWrapper.relationshipFieldNames)){
            throw new SObjectServiceException(String.format(System.Label.Error_Relationship_Field_Names_Missing, new List<Object>{ requestWrapper.sObjectName, recordId }));
        }

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if(!gd.containsKey(requestWrapper.sObjectName)){
            throw new SObjectServiceException(System.Label.Error_Invalid_SObject_Name);
        }
    }
}