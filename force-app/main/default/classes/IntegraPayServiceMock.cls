@isTest
public class IntegraPayServiceMock implements HttpCalloutMock{
    public static HttpResponse respond(HTTPRequest req) {
        PaymentSetting__mdt config = [SELECT IntegraPay_API_Username__c, IntegraPay_API_Password__c, IntegraPay_API_Login__c, IntegraPay_endpoint__c, IntegraPay_Business_Key__c, IntegraPay_Business_Id__c FROM PaymentSetting__mdt WHERE DeveloperName = :Constants.PAYMENT_SETTING];
        if(req.getEndpoint() == config.IntegraPay_API_Login__c) {
            return getAuthenticateResponse();
        }else if(req.getEndpoint() == config.IntegraPay_endpoint__c+'/businesses/'+config.IntegraPay_Business_Key__c+'/services/tokenize-card') {
            return tokenizeCard();
        }else if(req.getEndpoint() == config.IntegraPay_endpoint__c+'/businesses/'+config.IntegraPay_Business_Id__c+'/transactions/card-payments/token') {
            return processLiveTransactionSuccess();
        }else if(req.getEndpoint().contains(config.IntegraPay_endpoint__c)) {
            return processRefundTransaction();
        }else {
            return new HttpResponse();
        }
    }
    public static HttpResponse getAuthenticateResponse(){
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('{"access_token": "123xyz","expires_in": 3600,"token_type": "Bearer","scope": "integrapay.api.public"}');
		response.setStatusCode(200);
		return response;
	}
    public static HttpResponse tokenizeCard() {
        HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('{"token": "4bbb3ee15c494e68a052b5dbb045d258"}');
		response.setStatusCode(200);
		return response;
    }
    public static HttpResponse processLiveTransactionSuccess() {
        HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('{"transactionId": "RT683427","reference": "createApplicationscc1c","statusCode": "S","processedAmount": 10.00,"cardType": "Visa"}');
		response.setStatusCode(200);
		return response;
    }
    public static HttpResponse processRefundTransaction() {
        HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		response.setBody('{"transactionId": "OPT15941","reference": "REFUND-TXN-1155","statusCode": "S","statusDescription": "Successful","processedAmount": 10.00}');
		response.setStatusCode(200);
		return response;
    }
}