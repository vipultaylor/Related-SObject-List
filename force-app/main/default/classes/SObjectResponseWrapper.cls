/**
 * @description     Wrapper class for SObject Response Information sent to Sobject List LWC Component
 * @author          Vipul Taylor
 * @modifiedBy      Vipul Taylor
 * @maintainedBy    Vipul Taylor
 * @version         1.0
 * @created         2022-03-12
 * @systemLayer     Wrapper
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public class SObjectResponseWrapper {
  @AuraEnabled
  public SObj sObj { get; set; }

  @AuraEnabled
  public ParentSObj parentSObj { get; set; }

  @AuraEnabled
  public Permissions permissions { get; set; }

  @AuraEnabled
  public String fieldDescribeResults { get; set; }

  /**
   * @description     SObjectResponseWrapper constructor
   * @return          instance of SObjectResponseWrapper class
   */
  public SObjectResponseWrapper() {
    this.sObj = new SObj();
    this.parentSObj = new ParentSObj();
    this.permissions = new Permissions();
  }

  /**
   * @description     Child wrapper class to capture SObject information
   */
  public class SObj {
    @AuraEnabled
    public String sObjectLabel { get; set; }

    @AuraEnabled
    public List<SObject> lstSObjects { get; set; }

    @AuraEnabled
    public Integer fullCountOfSObjects { get; set; }

    @AuraEnabled
    public Boolean recordtypesEnabled { get; set; }

    @AuraEnabled
    public List<RecordTypeInfo> availableRecordtypes { get; set; }

    /**
     * @description     SObj constructor
     * @return          instance of SObj class
     */
    public SObj() {
      this.lstSObjects = new List<SObject>();
      this.fullCountOfSObjects = 0;
      this.recordtypesEnabled = false;
      this.availableRecordtypes = new List<RecordTypeInfo>();
    }
  }

  /**
   * @description     Child wrapper class to capture Recordtype information
   */
  public class RecordtypeInfo {
    @AuraEnabled
    public String recordtypeId { get; set; }

    @AuraEnabled
    public String recordtypeName { get; set; }

    /**
     * @description             RecordtypeInfo constructor
     * @param  recordtypeId     Recordtype Id
     * @param  recordtypeName   Recordtype Developername
     * @return                  instance of RecordtypeInfo class
     */
    public RecordtypeInfo(String recordtypeId, String recordtypeName) {
      this.recordtypeId = recordtypeId;
      this.recordtypeName = recordtypeName;
    }
  }

  /**
   * @description     Child wrapper class to capture Parent SObject information
   */
  public class ParentSObj {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled
    public String recordName { get; set; }

    @AuraEnabled
    public String name { get; set; }

    @AuraEnabled
    public String label { get; set; }

    @AuraEnabled
    public String labelPlural { get; set; }
  }

  /**
   * @description     Child wrapper class to capture Permissions information
   */
  public class Permissions {
    @AuraEnabled
    public Boolean accessible { get; set; }

    @AuraEnabled
    public Boolean creatable { get; set; }

    @AuraEnabled
    public Boolean updatable { get; set; }

    @AuraEnabled
    public Boolean deletable { get; set; }

    /**
     * @description     Permissions constructor
     * @return          instance of Permissions class
     */
    public Permissions() {
      this.accessible = false;
      this.creatable = false;
      this.updatable = false;
      this.deletable = false;
    }
  }
}
