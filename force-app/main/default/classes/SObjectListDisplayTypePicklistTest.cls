/**
 * @description     Test class for SObjectListDisplayTypePicklist class
 * @author          Vipul Taylor
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Test
 */
@IsTest
public with sharing class SObjectListDisplayTypePicklistTest {
  @IsTest
  private static void getDefaultValue() {
    SObjectListDisplayTypePicklist dpl = new SObjectListDisplayTypePicklist();
    VisualEditor.DataRow defaultRow = dpl.getDefaultValue();
    System.assertEquals(
      'list',
      defaultRow.getValue(),
      '"list" should have been set as the default data row for dynamic picklist'
    );
  }

  @IsTest
  private static void getValues() {
    SObjectListDisplayTypePicklist dpl = new SObjectListDisplayTypePicklist();
    VisualEditor.DynamicPickListRows dataRows = dpl.getValues();
    System.assertEquals(
      3,
      dataRows.size(),
      '3 options should have been returned for dynamic picklist'
    );
  }
}
