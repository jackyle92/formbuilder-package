@isTest
public class FormFooterCtrlTest {
	@isTest 
    public static void testGetCompanyInfo(){
        
        Test.startTest();
        PaymentSetting__mdt paymentSetting = FormFooterCtrl.getCompanyInfo();
        Test.stopTest();
        
        System.assertEquals(true, paymentSetting != null);
    }
}