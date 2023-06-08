/**
 * @description     Service class for SObject List LWC Component
 * @author          Vipul Taylor   
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Service
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.AvoidDeeplyNestedIfStmts, PMD.NcssMethodCount, PMD.ExcessiveParameterList')
public with sharing class SObjectService {
    /**
     * @description     Custom Exception class for SObjectService
     */
    public class SObjectServiceException extends Exception {}

    private final static String DEFAULT_PARENT_ID_FIELD_NAME = 'Id';
    private final static String DEFAULT_REFERENCE_FIELD_NAME = 'Name';
    private final static String ALL_RECORDTYPES = 'ALL_RECORDTYPES';
    private final static Integer MAX_LIMIT_COUNT = 10;
    private final static Integer MAX_FULLVIEW_LIMIT_COUNT = 2000;

    //Create a map of objects where 'Name' is not the right identifier
    private final static Map<String, String> MAP_OBJECT_IDENTIFIERS = new Map<String, String>{ 
        'WorkOrder' => 'WorkOrderNumber'
    };

    /**
     * @description           Get the Sobject information in the response wrapper
     * @param  recordId       recordId of the record on which the component is placed
     * @param  requestWrapper request Wrapper instance
     * @param  viewAll        whether All records should be queried
     * @return                Response Wrapper instance
     * 
     * @note                  Suppressing SOQL Injection notification as its a false positive in this method
     */
    @SuppressWarnings('PMD.ApexSOQLInjection')
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
                for(Schema.DescribeFieldResult dfr : fieldDescribeResults){
                    //Check if the field is of type reference
                    String referenceFieldIdentifierPath = getReferenceFieldIdentifierPath(dfr);
                    if(String.isNotBlank(referenceFieldIdentifierPath)){
                        referenceFields.add(referenceFieldIdentifierPath);
                    }
                }
        
                if(referenceFields.size() > 0){
                    requestWrapper.additionalFields = String.join(referenceFields, ',');
                }

                //Get Context Object Details
                Schema.DescribeSObjectResult contextSobjDescribe = ((Id) recordId).getSObjectType().getDescribe();
                String contextObjName = contextSobjDescribe.getName();
                String contextObjIdentifierField = DEFAULT_REFERENCE_FIELD_NAME;
                if(MAP_OBJECT_IDENTIFIERS.containsKey(contextObjName)){
                    contextObjIdentifierField = MAP_OBJECT_IDENTIFIERS.get(contextObjName);
                }

                //Build the query
                //build the list of fields
                String parentIdFieldName = DEFAULT_PARENT_ID_FIELD_NAME;
                String parentIdentifierFieldName = contextObjIdentifierField;

                List<String> lstContextQueryFields = new List<String>{'Id', contextObjIdentifierField};
                if(String.isNotBlank(requestWrapper.idField) && requestWrapper.idField != parentIdFieldName){
                    //set the parent Id field
                    parentIdFieldName = requestWrapper.idField;
                    lstContextQueryFields.add(parentIdFieldName);

                    //get the parent id related identifier field
                    Map<String, Schema.SObjectField> contextObjFieldMap = contextSobjDescribe.fields.getMap();
					if(contextObjFieldMap.containsKey(parentIdFieldName)){
						Schema.DescribeFieldResult dfr = contextObjFieldMap.get(parentIdFieldName).getDescribe();
						String parentReferenceFieldIdentifierPath = getReferenceFieldIdentifierPath(dfr);
						if(String.isNotBlank(parentReferenceFieldIdentifierPath)){
							lstContextQueryFields.add(parentReferenceFieldIdentifierPath);
							parentIdentifierFieldName = parentReferenceFieldIdentifierPath;
						}
					} else {
						throw new SObjectServiceException(System.Label.Error_Invalid_Parent_Identifier_Field);
					}
                }

				String query = 'SELECT ' + String.join(lstContextQueryFields, ',') + ' FROM ' + String.escapeSingleQuotes(contextObjName) + ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\'';

                List<SObject> lstRecordDetails = Database.query(query);

                String parentRecordId = (String) lstRecordDetails[0].get(parentIdFieldName);

				//Check if there is an Id to query the records against
				if(String.isNotBlank(parentRecordId)){
					String parentRecordIdentifier;
                
					//Check if the Parent Identifier field name is a dot notation reference
					if(parentIdentifierFieldName.contains('.')){
						SObject parentRecordInstance = lstRecordDetails[0].getSObject(parentIdentifierFieldName.subStringBefore('.'));
						if(parentRecordInstance != null){
							parentRecordIdentifier = (String) parentRecordInstance.get(parentIdentifierFieldName.subStringAfter('.'));
						}
					} else {
						parentRecordIdentifier = (String) lstRecordDetails[0].get(parentIdentifierFieldName);
					}
	
					Schema.DescribeSObjectResult parentSobjDescribe = ((Id) parentRecordId).getSObjectType().getDescribe();
			
					//Add Parent SObject details to the response
					response.parentSObj.recordId = parentRecordId;
					response.parentSObj.recordName = parentRecordIdentifier;
					response.parentSObj.name = parentSobjDescribe.getName();
					response.parentSObj.label = parentSobjDescribe.getLabel();
					response.parentSObj.labelPlural = parentSobjDescribe.getLabelPlural();
				}

                //Add Permisssions to the response
                response.permissions.accessible = true;
                response.permissions.creatable = sobjDescribe.isCreateable();
                response.permissions.updatable = sobjDescribe.isUpdateable();
                response.permissions.deletable = sobjDescribe.isDeletable();

                //Add Field Describe Results to the response
                response.fieldDescribeResults = JSON.serialize(fieldDescribeResults);

                //Add SObject Records to the response
				if(String.isNotBlank(parentRecordId)){
					response.sObj = getSObjectRecords(parentRecordId, requestWrapper, viewAll);
				} else {
					response.sObj = new SObjectResponseWrapper.SObj();
				}
            }
        }

        return response;
    }

    /**
     * @description           Get the field describe information from the wrapper inputs
     * @param  requestWrapper request Wrapper instance
     * @return                Field Describe results
     */
    private static List<Schema.DescribeFieldResult> getFieldDescribe(SObjectRequestWrapper requestWrapper) {
        List<Schema.DescribeFieldResult> lstDescribeFieldResult = new List<Schema.DescribeFieldResult>();

        // Field Set
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(requestWrapper.sObjectName).getDescribe().fields.getMap();
        for(Schema.FieldSetMember fsm : Utils.getFieldsForFieldSet(requestWrapper.sObjectName, requestWrapper.fieldSetForColumns)){
            Schema.DescribeFieldResult dfr = fieldMap.get(fsm.getFieldPath()).getDescribe();

            if(dfr.isAccessible()){
                lstDescribeFieldResult.add(dfr);
            }
        }

        return lstDescribeFieldResult;
    }

    /**
     * @description     reference Field Identifier Path (dot naming convention)
     * @param  dfr      field descrbe result instance
     * @return          reference field identifier path
     */
    private static String getReferenceFieldIdentifierPath(Schema.DescribeFieldResult dfr){
        String referenceFieldIdentifierPath = '';

        if(dfr.type == Schema.DisplayType.REFERENCE){
            String identifierField = DEFAULT_REFERENCE_FIELD_NAME;
            List<Schema.SObjectType> lstReferenceObjectTypes = dfr.getReferenceTo();
            String objName = lstReferenceObjectTypes[0].getDescribe().getName();
            if(MAP_OBJECT_IDENTIFIERS.containsKey(objName)){
                identifierField = MAP_OBJECT_IDENTIFIERS.get(objName);
            }
    
            referenceFieldIdentifierPath = dfr.getRelationshipName() + '.' + identifierField;
        }

        return referenceFieldIdentifierPath;
    }

    /**
     * @description           Query the SObject Records and return the wrapper instance
     * @param  parentRecordId the Parent Record Id
     * @param  requestWrapper request Wrapper instance
     * @param  viewAll        whether All records should be queried
     * @return                SObj wrapper instance
     */
    private static SObjectResponseWrapper.SObj getSObjectRecords(String parentRecordId, SObjectRequestWrapper requestWrapper, Boolean viewAll){
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
            for(Id recordtypeId : recordTypeInfos.keySet()){
                Schema.RecordTypeInfo rtInfo = recordTypeInfos.get(recordtypeId);
                //Check if the recordtype is in the list of requested recordtypes
                if(requestWrapper.commaSeparatedRecordtypes != ALL_RECORDTYPES){
                    for(String recordTypeName : requestWrapper.commaSeparatedRecordtypes.split(',')){
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

        List<SObject> lstSObjects = querySObjectRecords(parentRecordId, requestWrapper, recordtypeIdSet, viewAll);
        List<SObject> lstAllSObjects = querySObjectRecords(parentRecordId, requestWrapper, recordtypeIdSet, true);

        sObjResponse.sObjectLabel = sObjDescribe.getLabel();
        sObjResponse.lstSObjects = lstSObjects;
        sObjResponse.fullCountOfSObjects = lstAllSObjects.size();

        return sObjResponse;
    }

    /**
     * @description            Query the SObject Records
     * @param  parentRecordId  the Parent Record Id
     * @param  requestWrapper  request Wrapper instance
     * @param  recordtypeIdSet Set of recordtype Ids
     * @param  viewAll         whether All records should be queried
     * @return                 List of SObject records
     */
    @SuppressWarnings('PMD.ApexSOQLInjection')
    private static List<SObject> querySObjectRecords(String parentRecordId, SObjectRequestWrapper requestWrapper, Set<Id> recordtypeIdSet, Boolean viewAll){
        //Get a distinct list of fields
        //Id field is included by default
        Set<String> additionalFieldsSet = new Set<String>();
        if(requestWrapper.additionalFields != null){
            additionalFieldsSet = new Set<String>(requestWrapper.additionalFields.split(','));
        }

        Set<String> sObjectFields = Utils.getFieldListFromFieldSet(requestWrapper.sObjectName, new Set<String>{requestWrapper.fieldSetForColumns}, additionalFieldsSet);

        //Build the query
        //Include the fields in the query
        String query = 'SELECT ' + String.join(new List<String>(sObjectFields),',');
            
        //Specify the SObject
        query += ' FROM ' + requestWrapper.sObjectName;

        //Specify the relationship filters
        List<String> relationshipFilters = new List<String>();
        for(String fieldName : requestWrapper.relationshipFieldNames.split(',')){
            relationshipFilters.add(' ' + fieldName + '= \'' + parentRecordId + '\'');
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

        return Database.query(query);
    }

    /**
     * @description           Validate if the Request Wrapper has all the required parameters
     * @param  recordId       recordId of the record on which the component is placed
     * @param  requestWrapper request Wrapper instance
     */
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