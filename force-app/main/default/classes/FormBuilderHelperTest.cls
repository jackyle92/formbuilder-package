@isTest
private with sharing class FormBuilderHelperTest {

  @TestSetup
  static void createData(){
    Form__c newForm = new Form__c();
    newForm.Form_Name__c = 'Test';
    newForm.Object_Reference_N__c = 'Contact';
    newForm.Field_Relationship__c = 'Contact_Payment__c';
    insert newForm;

    Form_Component__c formCmp = new Form_Component__c();
    formCmp.Type__c = 'Screen';
    formCmp.Form__c = newForm.id;
    formCmp.label__c = 'New Screen';
    formCmp.Order__c = 1;
    insert formCmp; 
  }

  // Test getFieldInfo
  @isTest
  public static void getFieldInfoTest() {
    String inputText = 'JackyLee';
    FormBuilderHelper.getFieldInfo(inputText);
  }

  @isTest
  public static void isValidMappingTest() {
    String inputText = 'JackyLee';
    FormBuilderHelper.isValidMapping(inputText);
  }

  // Test getPickList value of field
  @isTest
  public static void getPickListTest() {

    // create object_name, field name
    SObjectType sObjType = ((SObject) Type.forName('Contact').newInstance()).getSObjectType();
    String fieldName = 'LeadSource';
    FormBuilderHelper.getPicklist(sObjType, fieldName);
  }

  // test get map payment fee
  @isTest
  public static void getMapPaymentFeeTest() {
    FormBuilderHelper.getMapPaymentFee();
  }

  @isTest
  public static void formInitTest() {

    // query form
    List<Form__c> forms = [SELECT id FROM Form__c LIMIT 1];

    String formId = forms[0].id;
    FormbuilderHelper.initHelper(formId);
  }

}