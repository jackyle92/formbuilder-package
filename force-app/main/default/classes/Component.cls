public with sharing class Component {
  public String variable;
  public String valuereplaced;
  public String value;
  public String imageUrl; //image url
  public String imageAltText; //image Alt text
  public String type;
  public String parentid;
  public Integer order;
  public String name { get; set; }
  public String mapping; //field mapping
  public String label; //field label
  public String id;
  public String key;
  public String defaultValue;
  public Boolean isRequired;
  public Boolean isReceiptEmailField;
  public Boolean isProductList;
  public Boolean isPromotionCmp;
  public Boolean isPaymentForm;
  public Boolean isField;
  public Boolean isPicklist;
  public Boolean isCheckbox;
  public Boolean isImage;
  public Boolean isDisplayText;
  public Boolean isHidden;
  public Boolean isConfirmationCheckbox;
  public Boolean isAddress;
  public String address;
  public String requiredDisplayTooltip;
  public String confirmationContent;
  public Boolean isYesNoOption;
  public Integer columnSize;
  public String options; // save string for picklist option to render the picklist into formbuilder cmp
  public Boolean isInputDate;
  public Boolean isSpacer;
  public Boolean isRadioGroup;
  public Boolean isAddFieldToQuery;
  public List<Component> childs;
  public List<String> optionsValue;
  public List<ListOptions> listOptions;
}