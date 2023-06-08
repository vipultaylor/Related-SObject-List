/**
 * @description     Picklist class for SObject List LWC Component
 * @author          Vipul Taylor   
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Service
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class SObjectListDisplayTypePicklist extends VisualEditor.DynamicPickList {
    
    /**
     * @description     get default value for the dynamic picklist
     * @return          Data Row for the default value
     */
    global override VisualEditor.DataRow getDefaultValue(){
        return new VisualEditor.DataRow('List', 'list');
    }

    /**
     * @description     get picklist values for the dynamic picklist
     * @return          Dynamic Picklist Rows
     */
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows displayTypeValues = new VisualEditor.DynamicPickListRows();
        displayTypeValues.addRow(new VisualEditor.DataRow('List', 'list'));
        displayTypeValues.addRow(new VisualEditor.DataRow('Tiles', 'tiles'));
        displayTypeValues.addRow(new VisualEditor.DataRow('Board', 'board'));
        return displayTypeValues;
    }
}