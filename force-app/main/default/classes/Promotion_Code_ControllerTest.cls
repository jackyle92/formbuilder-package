@isTest
private class Promotion_Code_ControllerTest {
  @TestSetup
  static void makeData(){
    Form__c form = new Form__c();
    form.Form_Name__c = 'Test Form';
    insert form;

    //create promotion
    Promotion__c promo = new Promotion__c();
    promo.Promotion_Code__c = '92uuksjlgks';
    promo.Form__c = form.Id;
    promo.Status__c = 'Active';
    promo.Rate__c = 5;
    insert promo;
  }

  @isTest
  public static void testGetRateFormPromotionCode() {
    String promoCode = '92uuksjlgks';
    Form__c form = [SELECT Id FROM Form__c LIMIT 1];
    Decimal rate = Promotion_Code_Controller.getRateFromPromtionCode(promoCode, form.Id);
    System.assertEquals(5, rate);
  }

  @isTest
  public static void testUpdateUsedPromotionCode() {
    String promoCode = '92uuksjlgks';
    Form__c form = [SELECT Id FROM Form__c LIMIT 1];
    Promotion_Code_Controller.updateUsedPromotionCode(promoCode, form.Id);

    Promotion__c pro = [SELECT Id, Status__c FROM Promotion__c LIMIT 1];
    System.assertEquals('Used', pro.Status__c);
  }


}