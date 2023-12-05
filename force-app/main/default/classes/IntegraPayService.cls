public with sharing class IntegraPayService {
    
    //get the Access Token
    public static string getAccessToken(){
        CalloutUtils callout = new CalloutUtils();
        PaymentSetting__mdt config = [SELECT IntegraPay_API_Username__c, IntegraPay_API_Password__c, IntegraPay_API_Login__c FROM PaymentSetting__mdt WHERE DeveloperName = :Constants.PAYMENT_SETTING];
        callout.method(Constants.HTTP_POST_METHOD)
                .endPoint(config.IntegraPay_API_Login__c)
                .addHeader(Constants.HTTP_CONTENT_TYPE, Constants.HTTP_APPLICATION_JSON)
                .timeout(10000);
        Map<String, String> body = new Map<String, String>();
        body.put('Username', config.IntegraPay_API_Username__c);
        body.put('Password', config.IntegraPay_API_Password__c);
        callout.body(JSON.serialize(body));
        HttpResponse res = callout.send();
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String)resMap.get('access_token');
    }

    //process live card transaction
    public static IntegraTransResponse processLiveTransaction(IntegraTransRequest req) {
        PaymentSetting__mdt config = [SELECT IntegraPay_Business_Id__c, IntegraPay_Business_Key__c, IntegraPay_endpoint__c FROM PaymentSetting__mdt WHERE DeveloperName = :Constants.PAYMENT_SETTING];
        
        String authorizationHeader = Constants.HTTP_BEARER+getAccessToken();

        CalloutUtils callout = new CalloutUtils();
        callout.method(Constants.HTTP_POST_METHOD)
                .endPoint(config.IntegraPay_endpoint__c+'/businesses/'+config.IntegraPay_Business_Id__c+'/transactions/card-payments/token')
                .addHeader(Constants.HTTP_CONTENT_TYPE, Constants.HTTP_APPLICATION_JSON)
                .addHeader(Constants.HTTP_AUTH,authorizationHeader)
                .timeout(90000);

        callout.body(JSON.serialize(req));
        HttpResponse res = callout.send();

        if(res.getStatusCode() != 200) throw new CalloutUtils.CalloutUtilsException('Connection error. Status Code: '+res.getStatusCode());
        
        IntegraTransResponse response = (IntegraTransResponse)JSON.deserialize(res.getBody(), IntegraTransResponse.Class);
        
        return response;
        
    }
    // process refund
    public static IntegraTransResponse processRefundTransaction(String transanctionId, String reference, Decimal amount) {
        PaymentSetting__mdt config = [SELECT IntegraPay_Business_Id__c, IntegraPay_Business_Key__c, IntegraPay_endpoint__c FROM PaymentSetting__mdt WHERE DeveloperName = :Constants.PAYMENT_SETTING];
        string authorizationHeader = Constants.HTTP_BEARER+getAccessToken();
        CalloutUtils callout = new CalloutUtils();
        callout.method(Constants.HTTP_POST_METHOD)
                .endPoint(config.IntegraPay_endpoint__c+'/businesses/'+config.IntegraPay_Business_Id__c+'/transactions/card-payments/'+transanctionId+'/refunds')
                .addHeader(Constants.HTTP_CONTENT_TYPE, Constants.HTTP_APPLICATION_JSON)
                .addHeader(Constants.HTTP_AUTH,authorizationHeader)
                .timeout(90000);

        IntegraRefundRequest req = new IntegraRefundRequest();
        req.Reference = reference;
        req.Amount = amount;


        callout.body(JSON.serialize(req));
        HttpResponse res = callout.send();
        if(res.getStatusCode() != 200) throw new CalloutUtils.CalloutUtilsException('An error has been occurred.');
        IntegraTransResponse response = (IntegraTransResponse)JSON.deserialize(res.getBody(), IntegraTransResponse.Class);
        system.debug('@@@ transaction resonse: '+response);
        return response;
    }

    public class IntegraTransRequest {
        public string ProcessType {get;set;}
        public string Reference {get;set;}
        public string Description {get;set;}
        public Decimal Amount {get;set;}
        public string CurrencyCode {get;set;}
        public string CardToken {get;set;}
        public PayerInfo Payer {get;set;}
        public Integer profile {get;set;}
        public IntegraTransRequest(){}
    }

    public class PayerInfo{
        public string uniqueReference {get;set;}
        public string groupReference {get;set;}
        public string familyOrBusinessName {get;set;}
        public string givenName {get;set;}
        public string email {get;set;}
        public boolean savePayer {get;set;}
        public PayerInfo(){}
    }

    public class IntegraRefundRequest {
        public string Reference {get;set;}
        public string Description {get;set;}
        public Decimal Amount {get;set;}
        public IntegraRefundRequest(){}
    }

    public class IntegraTransResponse {

        public String transactionId {get;set;}
        public String reference {get;set;}
        public String statusCode {get;set;}
        public String subStatusCode {get;set;}
        public String statusDescription {get;set;}
        public Decimal processedAmount {get;set;}
        public String cardType {get;set;}
        public String redirectId {get;set;}
        public String redirectUrl {get;set;}
        public String cardAuthorizationReference {get;set;}
        public IntegraTransResponse() {}
    }
}