@isTest
public with sharing class FormBuilderCtrlTest {
  @isTest
  public static void testInitData() {
    Form__c testForm = new Form__c();
    testForm.Form_Name__c = 'Test Form';
    testForm.Object_Reference_N__c = 'Contact';
    testForm.Field_Relationship__c = 'Contact_Payment__c';
    testForm.Brand_Color__c = '#FFFFFF';
    testForm.isMaxQPEqual_to_1__c = false;
    insert testForm;

    Test.startTest();
    Map<String, Object> mapResults = FormBuilderCtrl.initData(testForm.Id);
    Test.stopTest();

    System.assertEquals(true, mapResults.size() > 0);
  }

  @isTest
  public static void testSaveForm() {
    Id pricebookId = Test.getStandardPricebookId();

    System.debug('pricebookId: ' + pricebookId);
    Product2 pro2 = new Product2(Name = 'BXCD', isActive = true);
    insert pro2;
    System.debug('==pro2==' + pro2);

   

    PricebookEntry pbe2 = new PricebookEntry(
      unitprice = 2,
      Product2Id = pro2.Id,
      Pricebook2Id = pricebookId,
      isActive = true,
      UseStandardPrice = false
    );
    insert pbe2;
    System.debug('==pbe2==' + pbe2);

     // cover getProduct
    FormBuilderCtrl.getProduct(pro2.Id, pricebookId);

    Form__c testForm = new Form__c();
    testForm.Form_Name__c = 'Test Form';
    testForm.Brand_Color__c = '#FFFFFF';
    insert testForm;
    System.debug('==testForm==' + testForm);

    Form_Product__c fproduct = new Form_Product__c();
    fproduct.Form__c = testForm.Id;
    fproduct.Product__c = pro2.Id;
    fproduct.unit_price__c = pbe2.unitprice;
    insert fproduct;
    System.debug('==fproduct==' + fproduct);

    Form_Component__c screen = new Form_Component__c();
    screen.Form__c = testForm.Id;
    screen.Label__c = 'Screen';
    screen.Type__c = 'Screen';
    screen.Order__c = 0;
    insert screen;

    Form_Component__c layout = new Form_Component__c();
    layout.Label__c = 'Layout';
    layout.Type__c = 'Layout';
    layout.Order__c = 0;
    layout.Parent__c = screen.Id;
    insert layout;

    Form_Component__c column = new Form_Component__c();
    column.Label__c = 'Column';
    column.Type__c = 'Column';
    column.Order__c = 0;
    column.Column_Size__c = 12;
    column.Parent__c = layout.Id;
    insert column;

    Form_Component__c payment = new Form_Component__c();
    payment.Label__c = 'Payment Form';
    payment.Type__c = 'Payment Form';
    payment.Order__c = 2;
    payment.Parent__c = column.Id;
    insert payment;

    Form_Component__c textfield = new Form_Component__c();
    textfield.Label__c = 'First Name';
    textfield.Type__c = 'Text';
    textfield.Mapping__c = '{!Contact.FirstName}';
    textfield.Order__c = 0;
    textfield.Parent__c = column.Id;
    insert textfield;

    String jsonData =
      '[{"variable":null,"value":null,"type":"Screen","parentid":"' +
      testForm.Id +
      '","order":0,"name":null,"mapping":null,"label":"Screen","key":"FC-0012","isRequired":false,"isReceiptEmailField":false,"isPaymentForm":null,"isField":null,"isCheckDuplicate":null,"id":"' +
      screen.Id +
      '","columnSize":null,"childs":[{"variable":null,"value":null,"type":"Layout","parentid":"' +
      screen.Id +
      '","order":0,"name":null,"mapping":null,"label":"Layout","key":"FC-0013","isRequired":false,"isReceiptEmailField":false,"isPaymentForm":null,"isField":null,"isCheckDuplicate":null,"id":"' +
      layout.Id +
      '","columnSize":null,"childs":[{"variable":null,"value":null,"type":"Column","parentid":"' +
      layout.Id +
      '","order":0,"name":null,"mapping":null,"label":null,"key":"FC-0014","isRequired":false,"isReceiptEmailField":false,"isPaymentForm":null,"isField":null,"isCheckDuplicate":null,"id":"' +
      column.Id +
      '","columnSize":12,"childs":[{"variable":null,"value":null,"type":"text","parentid":"' +
      column.Id +
      '","order":0,"name":null,"mapping":"{!Contact.FirstName}","label":"First Name","key":"FC-0015","isRequired":true,"isReceiptEmailField":false,"isPaymentForm":null,"isField":true,"isCheckDuplicate":null,"id":"' +
      payment.Id +
      '","columnSize":null,"childs":[]},{"variable":null,"value":null,"type":"text","parentid":"' +
      column.Id +
      '","order":1,"name":null,"mapping":"{!Contact.LastName}","label":"Last Name","key":"FC-0016","isRequired":true,"isReceiptEmailField":false,"isPaymentForm":null,"isField":true,"isCheckDuplicate":null,"id":"' +
      textfield.Id +
      '","columnSize":null,"childs":[]},{"key":"D-00001","label":"Payment Form","type":"payment_form","isPaymentForm":true,"order":1}]}]}],"isFinalScreen":false,"isOnlyOne":true,"isShow":true,"isMiddleScreen":false}]';

    String formSetting =
      '{"id":"' +
      testForm.Id +
      '","brandColor":"#0176d3","isUseThankYouPage":false,"priceBookId":"' +
      pricebookId +
      '","productList":[{"Id":"' +
      fproduct.Id +
      '","Name":"Demo Product","Product__c":"' +
      pro2.Id +
      '","Form__c":"' +
      testForm.Id +
      '","value__c":0,"unit_price__c":50}],"productListDel":[],"currencyCode":"AUD" ,"isMaxQEqualto1":'+ testForm.isMaxQPEqual_to_1__c + '}';

    Test.startTest();
    FormBuilderCtrl.saveForm(jsonData, formSetting, new List<String>());
    Test.stopTest();

    List<Form_Component__c> lstComponent = [SELECT Id FROM Form_Component__c];
    System.assertEquals(true, lstComponent.size() > 0);
  }
}