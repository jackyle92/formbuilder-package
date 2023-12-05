public with sharing class Promotion_Code_Controller {
    public Promotion_Code_Controller() {

    }

    
    //check the promotion code
    @AuraEnabled
    public static Decimal getRateFromPromtionCode(String proCode, String formId) {
        Decimal rate = 0;
        if(proCode == null || proCode.length() == 0) return null;
        else {
            List<Promotion__c> pros = [SELECT Promotion_Code__c, Rate__c, Status__c, Form__c FROM Promotion__c WHERE Promotion_Code__c = :ProCode AND Status__c NOT IN ('Used', 'Inactive')];
            if(pros.size() > 0 ) {
                for(Promotion__c pro : pros) {
                    if(pro.Status__c != 'Active') {
                        return null;
                    } else if((pro.Form__c != null && pro.Form__c == formId) || pro.Form__c == null) {
                        // process logic
                        rate = pro.Rate__c;
                    } else return null;
                }
            } else return null;
        }
        return rate;
    }

    public static void updateUsedPromotionCode (String proCode, String formId) {
        try {
            List<Promotion__c> pros = [SELECT Id, Promotion_Code__c, Rate__c, Status__c FROM Promotion__c WHERE Promotion_Code__c = :ProCode AND Status__c NOT IN ('Used', 'Inactive') LIMIT 1];
            if(pros.size() > 0) {
                pros[0].Status__c = 'Used';
            }
            update pros;
        } catch (Exception e) {
            throw new AuraException(e.getMessage());
        }
        
    }
}