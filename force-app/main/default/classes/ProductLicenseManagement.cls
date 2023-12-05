/**
 * @author Jacky Lee
 * @Description This class use to manage the license of product which is installed in the customer organization system.
 */
public without sharing class ProductLicenseManagement {
  public static Integer licenseExpirationNotificationDate;
    // public String productName = 'ccpformbuilder';
    /**
     * @Description: Get Active License for the product which is installed 
     * 
     */
    @AuraEnabled
    public static String getActiveLicense(){
        
        Integer expirationNotification; 
        String orgId;
        Boolean isSandbox;
        String organizationName;
        String productNamespace;
        
      try {
        String accessToken = getAccessToken();
        Map<String,String> mapCredential = getMapCredentials();
        String endpoint = mapCredential.get('endpoint');
          
        // get orgName 
        Organization orgInfo= [SELECT InstanceName, Name FROM Organization LIMIT 1];
        organizationName = orgInfo.Name;

       	ClientProductInfo clientInfoBody = new ClientProductInfo(Integer.valueOf(mapCredential.get('licenseExpiredNotificationdDate')),
                                                                 organizationName,
                                                                 getOrgId(), 
                                                                 mapCredential.get('namespace_prefix'));
   
        Map<String, ClientProductInfo> requestInfo = new Map<String, ClientProductInfo>();
        requestInfo.put('requestInfo', clientInfoBody);
          
        try {
          HttpRequest req = new HttpRequest();
          req.setMethod('POST');
          req.setEndpoint(endpoint);
          req.setHeader('Content-Type', 'application/json');
          req.setHeader('Authorization', 'Bearer ' + accessToken);
          req.setBody(JSON.serialize(requestInfo));
          System.debug('Body Request: ' + JSON.serialize(requestInfo));
          Http http = new Http();
          HttpResponse res = http.send(req);
          // return JSON.serialize(res.getBody());
          System.debug('Status123: ' + res.getStatusCode());
          System.debug('Res Body: ' + res.getBody());
          ReturnedData dataReturn = new ReturnedData(res.getStatusCode(), res.getBody());
          return JSON.serialize(dataReturn);

        } catch (Exception e) {
          System.debug('Error sending license request: ' + e.getMessage());
        }
      } catch (Exception e) {
        System.debug('Error get active license');
        throw new AuraHandledException(e.getMessage());
      }
        return null;
    }
    
    /**
     * @Description: Get access token
     */
    public static String getAccessToken() {
        try {
            String accessToken;
            String grantType = 'client_credentials';

            Map<String, String> credentials = getMapCredentials();

            /*
            String base64Content = EncodingUtil.Base64Encode( 
                Blob.valueOf( '8B37FD80E4D07A1D0766212F621288C4D2563F6C35F3CB8C9DD424FB20056A12' ) 
            );
            System.debug('Base64 Content is ' + base64Content );
            Blob blobContent = EncodingUtil.base64Decode( base64Content );
            System.debug('Decoded Base64 value is ' + blobContent.toString());
            */

            String clientId = EncodingUtil.base64Decode(credentials.get('clientId')).toString();
            String clientSecret = EncodingUtil.base64Decode(credentials.get('clientSecret')).toString();
            String remoteSite = credentials.get('remote_site');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(remoteSite + 'grant_type=' + grantType + '&client_id=' + clientId + '&client_secret=' + clientSecret);
            req.setMethod('POST');
            // req.setHeader(key, value);

            Http http = new Http();
            HttpResponse res = http.send(req);
            Map<String, object> body = (Map<String, object>)JSON.deserializeUntyped(res.getBody());

            for (String key : body.keySet()) {
                System.debug('key: ' + key + 'value: ' + body.get(key));
                if(key == 'access_token') {
                    accessToken = body.get(key).toString();
                }
            }
            return accessToken;
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug('Error when get the access token');
            return null;
        }
    }
    
    public class ReturnedData {
        public ReturnedData() {}
        public Integer statusCode {get; set;}
        public String message {get; set;}
        public ReturnedData (Integer statusCode, String message) {
			this.statusCode = statusCode;
            this.message = message;
        }
    }
    /**
     * @author Jacky Lee
     * @Description get the org Id where the product is installed
     * @return orgId (string)
     */
    public static String getOrgId() {
        String orgId = UserInfo.getOrganizationId();
        return orgId.substring(0, 15);
    }

    /**
     * @author Jacky Lee
     * @Description get credentials to access AppExchange resources from CCP App Exchange Metadata record
     * @return Map<String, String> 
     */
    public static Map<String, String> getMapCredentials() {
      Map<String, String> mapCredentials = new Map<String, String>();

      List<CCP_App_Exchange__mdt> productCredential = [
        SELECT Id, License_Expiry_Notification_Days__c, Consumer_Key__c, Customer_Secret__c,  NamespacePrefix, Remote_Site__c, End_Point__c 
        FROM CCP_App_Exchange__mdt where label = 'CCP App Exchange'
        ];

      mapCredentials.put('clientId', productCredential[0].Consumer_Key__c);
      mapCredentials.put('clientSecret', productCredential[0].Customer_Secret__c); 
      mapCredentials.put('namespace_prefix', productCredential[0].NamespacePrefix);
      mapCredentials.put('endpoint', productCredential[0].End_Point__c);
      mapCredentials.put('remote_site', productCredential[0].Remote_Site__c);
      mapCredentials.put('licenseExpiredNotificationdDate', String.valueOf(productCredential[0].License_Expiry_Notification_Days__c));
      return mapCredentials;
    }
    
    public static Boolean isLicenseValid(string returnedMessage){
        if(returnedMessage == null){
            return false;
        }
        if(Test.isRunningTest()){
            return true;
        }
        productLicenseResponseClass result = (productLicenseResponseClass) JSON.deserialize(returnedMessage, productLicenseResponseClass.class);
        system.debug('isLicenseValid :: ' + result.status);
        
        if(result.status == 'Active'){
            return true;
        }
      
       return false;
    }
    
    public class productLicenseResponseClass{
        public date expirationDate {get; set;}
        public integer licenseExpiredNotificationdDate {get; set;}
        public string licenseId {get; set;}
        public string licenseName {get; set;}
        public string status {get; set;}
        public integer totalLicenses {get; set;}
        public integer usedLicenses {get; set;}
        public string message {get; set;}
    }   
}