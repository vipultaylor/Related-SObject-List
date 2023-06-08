/**
 * @description     Controller class for SObject List LWC Component
 * @author          Vipul Taylor
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Controller
 */
public with sharing class SObjectListController {
  /**
   * @description           Get the Sobject information in the response wrapper
   * @param  recordId       recordId of the record on which the component is placed
   * @param  requestWrapper request Wrapper instance
   * @param  viewAll        whether All records should be queried
   * @return                Response Wrapper instance
   */
  @AuraEnabled
  public static SObjectResponseWrapper getResponse(
    String recordId,
    SObjectRequestWrapper requestWrapper,
    Boolean viewAll
  ) {
    return SObjectService.getResponse(recordId, requestWrapper, viewAll);
  }
}
