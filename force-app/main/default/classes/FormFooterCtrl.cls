public without sharing class FormFooterCtrl {
    @AuraEnabled
    public static PaymentSetting__mdt getCompanyInfo() {
        PaymentSetting__mdt config = [
            SELECT Company_Name__c, Email__c,
                Facebook__c, Instagram__c,
                Twitter__c, Phone__c,
                Physical_Address__c, Terms_Conditions__c
            FROM PaymentSetting__mdt 
            WHERE DeveloperName = :Constants.PAYMENT_SETTING
        ];
        return config;
    }
}