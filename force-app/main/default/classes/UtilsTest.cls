/**
 * @description     Test class for Utils class
 * @author          Vipul Taylor   
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Test
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest 
public with sharing class UtilsTest {
    private static Integer fakeIdCount = 0;
	private static final String ID_PATTERN = '000000000000';

    @IsTest
    private static void getFieldsForFieldSet(){
        List<Schema.FieldSetMember> lstFieldSetMembers = Utils.getFieldsForFieldSet('Opportunity', 'OpportunityFieldSetForTesting');
        System.assertNotEquals(null, lstFieldSetMembers, 'Null response recieved');
        System.assertEquals(6, lstFieldSetMembers.size(), '6 field set members should have been received');
    }

    @IsTest
    private static void getFieldsForFieldSet_BlankFieldSetName(){
        List<Schema.FieldSetMember> lstFieldSetMembers = Utils.getFieldsForFieldSet('Opportunity', '');
        System.assertNotEquals(null, lstFieldSetMembers, 'Null response recieved');
        System.assertEquals(0, lstFieldSetMembers.size(), 'No field set members should have been received');
    }

    @IsTest
    private static void getFieldsForFieldSet_NullFieldSetName(){
        List<Schema.FieldSetMember> lstFieldSetMembers = Utils.getFieldsForFieldSet('Opportunity', null);
        System.assertNotEquals(null, lstFieldSetMembers, 'Null response recieved');
        System.assertEquals(0, lstFieldSetMembers.size(), 'No field set members should have been received');
    }

    @IsTest
    private static void getFieldsForFieldSet_InvalidFieldSetName(){
        try{
            List<Schema.FieldSetMember> lstFieldSetMembers = Utils.getFieldsForFieldSet('Opportunity', 'Invalid');
        } catch (Utils.UtilsException ex){
            System.assertEquals('Field Set Invalid does not exist for sobject Opportunity', ex.getMessage(), 'Unexpected Error Message');
        }
    }

    @IsTest
    private static void getFieldsForFieldSet_InvalidSObjectName(){
        try{
            List<Schema.FieldSetMember> lstFieldSetMembers = Utils.getFieldsForFieldSet('Invalid', 'OpportunityFieldSetForTesting');
        } catch (Utils.UtilsException ex){
            System.assertEquals('Invalid sObjectName Invalid', ex.getMessage(), 'Unexpected Error Message');
        }
    }

    @IsTest
    private static void getFieldListFromFieldSet(){
        Set<String> fieldsSet = Utils.getFieldListFromFieldSet('Opportunity', new Set<String>{ 'OpportunityFieldSetForTesting' }, new Set<String>{'CreatedDate'});
        System.assertNotEquals(null, fieldsSet, 'Null response recieved');
        System.assertEquals(8, fieldsSet.size(), 'Id field, 6 fields from fieldset and 1 additional field should have been received');
    }

    @IsTest
    private static void getSetValuesForDynamicSoql_String(){
        String concatenatedString = Utils.getSetValuesForDynamicSoql(new Set<String>{ 'fieldA', 'fieldB', 'fieldC' });
        System.assertEquals('(\'fieldA\',\'fieldB\',\'fieldC\')', concatenatedString, 'Concatenated value in set format should have been received');
    }

    @IsTest
    private static void getSetValuesForDynamicSoql_Id(){
        Id fakeIdA = generateFakeId(Schema.Opportunity.SObjectType);
        Id fakeIdB = generateFakeId(Schema.Opportunity.SObjectType);
        Id fakeIdC = generateFakeId(Schema.Opportunity.SObjectType);
        String concatenatedString = Utils.getSetValuesForDynamicSoql(new Set<Id>{ fakeIdA, fakeIdB, fakeIdC });
        System.assertEquals('(\'' + fakeIdA + '\',\'' + fakeIdB + '\',\'' + fakeIdC +'\')', concatenatedString, 'Concatenated value in set format should have been received');
    }

	private static Id generateFakeId(Schema.SObjectType sobjectType) {
		String keyPrefix = sobjectType.getDescribe().getKeyPrefix();
		fakeIdCount++;

		String fakeIdPrefix = ID_PATTERN.substring(0, 12 - fakeIdCount.format().length());
		return Id.valueOf(keyPrefix + fakeIdPrefix + fakeIdCount);
	}
}