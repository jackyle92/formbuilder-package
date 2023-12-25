public with sharing class FormSetting {
  // public String id;
  // public String formName;
  // public String objectReference;
  // public String brandColor;
  // public String thankYouPageContent;
  // public Boolean isUseThankYouPage;
  // public Boolean isShowDisclaimer;
  // public Boolean isMaxQEqualto1;
  // public String duplicateSelected;
  // public String priceBookId;
  // public String currencyCode;
  // // public List<Form_Product__c> productList;
  // public List<FormBuilderHelper.FormProductData> productDataLst;
  // public List<String> productListDel;
  public String id;	//a035h00000duMANAA2
	public String brandColor;	//#FFFFFF
	public String thankYouPageContent;	//<p style="text-align: center;"><span style="font-size: 28px;">Thank you </span></p>
	public boolean isUseThankYouPage;
	public String priceBookId;	//01s5h00000K6c5FAAR
	public String objectReference;	//Contact
  public String duplicateSelected;
	public cls_productList[] productList;
  public List<String> productListDel;
	public String currencyCode;	//AUD
	public class cls_productList {
		public Decimal unitPrice;	//5000
		public String productId;	//01t5h000007Nbz1AAC
		public String name;	//GenWatt Diesel 10kW
		public String id;	//a025h00000mTB83AAG
		public String formId;	//a035h00000duMANAA2
    public Integer maxQuantityOfProduct;
    public Decimal value; // update by quantity of product when user increase or decrease quantity
	}
	public static FormSetting parse(String json){
		return (FormSetting) System.JSON.deserialize(json, FormSetting.class);
	}

}