public class ClientProductInfo {
    
    public Integer expirationNotification;
    public String organizationName;
    public String orgId;
    public String productNamespace;
    
    public ClientProductInfo (Integer expirationNotification, 
                             String organizationName,
                             String orgId,
                             String productNamespace) {
	
		this.expirationNotification = expirationNotification;
		this.organizationName = organizationName;
		this.orgId = orgId;
        this.productNamespace = productNamespace;                   
    }

	public static ClientProductInfo parse(String json) {
		return (ClientProductInfo) System.JSON.deserialize(json, ClientProductInfo.class);
	} 
}