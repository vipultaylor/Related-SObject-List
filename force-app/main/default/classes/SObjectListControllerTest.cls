/**
 * @description     Test class for SObjectListController and SObjectService classes
 * @author          Vipul Taylor   
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Test
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest 
public with sharing class SObjectListControllerTest {
    @testSetup static void setup() {
        // Create common test data
        Test.startTest();
        Account[] lstAccounts = new List<Account>{
            new Account(Name='TestAccount1'),
            new Account(Name='TestAccount2')
        };
        Database.SaveResult[] srAccountList = Database.insert(lstAccounts);

        Opportunity[] lstOpportunities = new List<Opportunity>{
            new Opportunity(Name='TestOpportunity1', AccountId=srAccountList[0].Id, CloseDate=Date.Today(), StageName='Prospecting'),
            new Opportunity(Name='TestOpportunity2', AccountId=srAccountList[0].Id, CloseDate=Date.Today(), StageName='Prospecting'),
            new Opportunity(Name='TestOpportunity3', AccountId=srAccountList[0].Id, CloseDate=Date.Today(), StageName='Prospecting'),
            new Opportunity(Name='TestOpportunity4', AccountId=srAccountList[0].Id, CloseDate=Date.Today(), StageName='Closed Won'),
            new Opportunity(Name='TestOpportunity5', AccountId=srAccountList[1].Id, CloseDate=Date.Today(), StageName='Prospecting'),
            new Opportunity(Name='TestOpportunity6', AccountId=srAccountList[1].Id, CloseDate=Date.Today(), StageName='Closed Won')
        };
        Database.SaveResult[] srOpportunityList = Database.insert(lstOpportunities);

        Test.stopTest(); 
    }

    @IsTest
    private static void getResponse(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount1' LIMIT 1];

        Test.startTest();
        SObjectRequestWrapper requestWrapper = new SObjectRequestWrapper();
        requestWrapper.sObjectName = 'Opportunity';
        requestWrapper.commaSeparatedRecordtypes = 'ALL_RECORDTYPES';
        requestWrapper.fieldSetForColumns = 'OpportunityFieldSetForTesting';
        requestWrapper.relationshipFieldNames = 'AccountId';
        requestWrapper.condition = '';
        requestWrapper.limitCount = 2;
        requestWrapper.sortStatement = 'Name ASC';

        SObjectResponseWrapper responseWrapper = SObjectListController.getResponse(account.Id, requestWrapper, false);
        System.assertNotEquals(null, responseWrapper, 'Null response recieved');
        System.assertEquals(account.Id, responseWrapper.parentSObj.recordId, 'Returned Parent objectId is not the same as the passed recordId');
        System.assertEquals('Account', responseWrapper.parentSObj.name, 'Returned Parent object Name does not correspond to the object name of the passed recordId');
        System.assertNotEquals(null, responseWrapper.sObj.lstSObjects, 'Null list of sobjects recieved');
        System.assertEquals(2, responseWrapper.sObj.lstSObjects.size(), 'Filtered List of Sobjects size not the same as expected');
        System.assertEquals(4, responseWrapper.sObj.fullCountOfSObjects, 'Full List of Sobjects size not the same as expected');
        Test.stopTest();
    } 

    @IsTest
    private static void getResponse_WithCondition(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount2' LIMIT 1];

        Test.startTest();
        SObjectRequestWrapper requestWrapper = new SObjectRequestWrapper();
        requestWrapper.sObjectName = 'Opportunity';
        requestWrapper.commaSeparatedRecordtypes = 'ALL_RECORDTYPES';
        requestWrapper.fieldSetForColumns = 'OpportunityFieldSetForTesting';
        requestWrapper.relationshipFieldNames = 'AccountId';
        requestWrapper.condition = 'StageName=\'Prospecting\'';
        requestWrapper.limitCount = 2;
        requestWrapper.sortStatement = 'Name ASC';

        SObjectResponseWrapper responseWrapper = SObjectListController.getResponse(account.Id, requestWrapper, false);
        System.assertNotEquals(null, responseWrapper, 'Null response recieved');
        System.assertEquals(account.Id, responseWrapper.parentSObj.recordId, 'Returned Parent objectId is not the same as the passed recordId');
        System.assertEquals('Account', responseWrapper.parentSObj.name, 'Returned Parent object Name does not correspond to the object name of the passed recordId');
        System.assertNotEquals(null, responseWrapper.sObj.lstSObjects, 'Null list of sobjects recieved');
        System.assertEquals(1, responseWrapper.sObj.lstSObjects.size(), 'Filtered List of Sobjects size not the same as expected');
        System.assertEquals(1, responseWrapper.sObj.fullCountOfSObjects, 'Full List of Sobjects size not the same as expected');
        Test.stopTest();
    } 

    @IsTest
    private static void getResponse_MaxLimitCount(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount1' LIMIT 1];

        Test.startTest();
        SObjectRequestWrapper requestWrapper = new SObjectRequestWrapper();
        requestWrapper.sObjectName = 'Opportunity';
        requestWrapper.commaSeparatedRecordtypes = 'ALL_RECORDTYPES';
        requestWrapper.fieldSetForColumns = 'OpportunityFieldSetForTesting';
        requestWrapper.relationshipFieldNames = 'AccountId';
        requestWrapper.condition = '';
        requestWrapper.limitCount = 11;
        requestWrapper.sortStatement = 'Name ASC';

        SObjectResponseWrapper responseWrapper = SObjectListController.getResponse(account.Id, requestWrapper, false);
        System.assertNotEquals(null, responseWrapper, 'Null response recieved');
        System.assertEquals(account.Id, responseWrapper.parentSObj.recordId, 'Returned Parent objectId is not the same as the passed recordId');
        System.assertEquals('Account', responseWrapper.parentSObj.name, 'Returned Parent object Name does not correspond to the object name of the passed recordId');
        System.assertNotEquals(null, responseWrapper.sObj.lstSObjects, 'Null list of sobjects recieved');
        System.assertEquals(4, responseWrapper.sObj.lstSObjects.size(), 'Filtered List of Sobjects size not the same as expected');
        System.assertEquals(4, responseWrapper.sObj.fullCountOfSObjects, 'Full List of Sobjects size not the same as expected');
        Test.stopTest();
    } 

    @IsTest
    private static void getResponse_RequestWrapperMissing(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount1' LIMIT 1];

        Test.startTest();
        try{
            SObjectListController.getResponse(account.Id, null, false);
        } catch(SObjectService.SObjectServiceException ex){
            System.assertEquals(System.Label.Error_SObject_Information_Missing, ex.getMessage(), 'Unexpected Error Message');
        }
        Test.stopTest();
    } 

    @IsTest
    private static void getResponse_SobjectNameMissing(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount1' LIMIT 1];

        Test.startTest();
        try{
            SObjectRequestWrapper requestWrapper = new SObjectRequestWrapper();
            SObjectListController.getResponse(account.Id, requestWrapper, false);
        } catch(SObjectService.SObjectServiceException ex){
            System.assertEquals(System.Label.Error_SObject_Name_Missing, ex.getMessage(), 'Unexpected Error Message');
        }
        Test.stopTest();
    } 

    @IsTest
    private static void getResponse_RecordtypesMissing(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount1' LIMIT 1];

        Test.startTest();
        try{
            SObjectRequestWrapper requestWrapper = new SObjectRequestWrapper();
            requestWrapper.sObjectName = 'Opportunity';
            SObjectListController.getResponse(account.Id, requestWrapper, false);
        } catch(SObjectService.SObjectServiceException ex){
            System.assertEquals(String.format(System.Label.Error_Recordtypes_Missing, new List<Object>{ 'Opportunity' }), ex.getMessage(), 'Unexpected Error Message');
        }
        Test.stopTest();
    } 

    @IsTest
    private static void getResponse_FieldsetMissing(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount1' LIMIT 1];

        Test.startTest();
        try{
            SObjectRequestWrapper requestWrapper = new SObjectRequestWrapper();
            requestWrapper.sObjectName = 'Opportunity';
            requestWrapper.commaSeparatedRecordtypes = 'ALL_RECORDTYPES';
            SObjectListController.getResponse(account.Id, requestWrapper, false);
        } catch(SObjectService.SObjectServiceException ex){
            System.assertEquals(String.format(System.Label.Error_Fieldset_Missing, new List<Object>{ 'Opportunity' }), ex.getMessage(), 'Unexpected Error Message');
        }
        Test.stopTest();
    } 

    @IsTest
    private static void getResponse_RelationshipFieldMissing(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount1' LIMIT 1];

        Test.startTest();
        try{
            SObjectRequestWrapper requestWrapper = new SObjectRequestWrapper();
            requestWrapper.sObjectName = 'Opportunity';
            requestWrapper.commaSeparatedRecordtypes = 'ALL_RECORDTYPES';
            requestWrapper.fieldSetForColumns = 'OpportunityFieldSetForTesting';
            SObjectListController.getResponse(account.Id, requestWrapper, false);
        } catch(SObjectService.SObjectServiceException ex){
            System.assertEquals(String.format(System.Label.Error_Relationship_Field_Names_Missing, new List<Object>{ 'Opportunity', account.Id }), ex.getMessage(), 'Unexpected Error Message');
        }
        Test.stopTest();
    } 

    @IsTest
    private static void getResponse_InvalidSobjectName(){
        Account account = [SELECT Id FROM Account WHERE Name =: 'TestAccount1' LIMIT 1];

        Test.startTest();
        try{
            SObjectRequestWrapper requestWrapper = new SObjectRequestWrapper();
            requestWrapper.sObjectName = 'InvalidObject';
            requestWrapper.commaSeparatedRecordtypes = 'ALL_RECORDTYPES';
            requestWrapper.fieldSetForColumns = 'OpportunityFieldSetForTesting';
            requestWrapper.relationshipFieldNames = 'AccountId';
            SObjectListController.getResponse(account.Id, requestWrapper, false);
        } catch(SObjectService.SObjectServiceException ex){
            System.assertEquals(System.Label.Error_Invalid_SObject_Name, ex.getMessage(), 'Unexpected Error Message');
        }
        Test.stopTest();
    } 
}