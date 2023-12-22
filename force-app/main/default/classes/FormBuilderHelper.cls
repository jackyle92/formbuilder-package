/**
 * Classname: FormBuilderHelper
 * Author: Vinh Hua
 * Created Date: 2022/07/20
 */
public without sharing class FormBuilderHelper {

  public static Boolean isValidMapping(String inputText) {
    Pattern TAG_REGEX = Pattern.compile('\\{\\![a-zA-Z0-9\\s+-_\\.]*\\}');
    Matcher matcher = TAG_REGEX.matcher(inputText);
    if (matcher.find()) {
      return true;
    }
    return false;
  }

  public static List<String> getFieldInfo(String inputText) {
    String content = inputText.replace('{!', '').replace('}', '');
    return content.split('\\.');
  }

  public static List<String> getPicklist(
    sObjectType object_name,
    String field_name
  ) {
    List<String> valueOfPicklist = new List<String>();
    List<selectOption> options = new List<selectOption>();
    Schema.DescribeSObjectResult sobject_describe = object_name.getDescribe(); //describe the sobject
    Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
    List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name)
      .getDescribe()
      .getPickListValues(); //grab the list of picklist values for the passed field on the sobject
    for (Schema.PicklistEntry a : pick_list_values) {
      //for all values in the picklist list

      options.add(new selectOption(a.getValue(), a.getLabel())); //add the value and label to our final list
    }
    for (Integer i = 0; i < options.size(); i++) {
      valueOfPicklist.add(options[i].getValue());
    }
    return valueOfPicklist; //return the List
  }

  public static Map<String, Object> initHelper(String formid) {
    Map<String, Object> mapResults = new Map<String, Object>();

    Map<Id, Form_Component__c> mapScreens = getCmpByParentIds(
      new Set<Id>{ formid }
    );

    Map<Id, Form_Component__c> mapLayouts = getCmpByParentIds(
      mapScreens.keySet()
    );
    Map<Id, Form_Component__c> mapColumns = getCmpByParentIds(
      mapLayouts.keySet()
    );
    Map<Id, Form_Component__c> mapChildCmps = getCmpByParentIds(
      mapColumns.keySet()
    );

    Map<Id, List<Component>> mapParentChilds = new Map<Id, List<Component>>();

    updateMapParentChilds(formid, mapChildCmps, mapParentChilds);
    updateMapParentChilds(formid, mapColumns, mapParentChilds);
    updateMapParentChilds(formid, mapLayouts, mapParentChilds);
    updateMapParentChilds(formid, mapScreens, mapParentChilds);

    mapResults.put('jsondata', JSON.serialize(mapParentChilds.get(formid)));

    List<Form__c> lstForm = [
      SELECT
        Id,
        Name,
        Form_Name__c,
        Brand_Color__c,
        Thank_You_Page__c,
        Use_Thank_You_Page__c,
        Duplicate_Process__c,
        Price_Book__c,
        Currency_Code__c,
        Object_Reference_N__c,
        isMaxQPEqual_to_1__c,
        Field_Relationship__c
      FROM Form__c
      WHERE Id = :formid
    ];

    System.debug('list form: ' + lstForm);

    mapResults.put('formName', lstForm[0].Form_Name__c);
    mapResults.put('brandColor', lstForm[0].Brand_Color__c);
    mapResults.put('thankYouPageContent', lstForm[0].Thank_You_Page__c);
    mapResults.put('isUseThankYouPage', lstForm[0].Use_Thank_You_Page__c);
    mapResults.put('duplicateSelected', lstForm[0].Duplicate_Process__c);
    mapResults.put('currencyCode', lstForm[0].Currency_Code__c);
    mapResults.put('isMaxQuanlityEqto1', lstForm[0].isMaxQPEqual_to_1__c);
    mapResults.put('objectReference', lstForm[0].Object_Reference_N__c);

    String nameSpace = getNameSpacePrefix();
    String fieldRelateionship = '';
    if (nameSpace.length() > 5) {
      fieldRelateionship = getNameSpacePrefix() + '__' + 'Contact_Payment__c';
    } else {
      fieldRelateionship = 'Contact_Payment__c';
    }

    mapResults.put('fieldRelation', fieldRelateionship);

    // get picklist fields for FormBuilder
    List<Map<String, String>> lstFields = new List<Map<String, String>>();
    lstFields = getListFields(lstForm[0].Object_Reference_N__c);
    mapResults.put('lstFieldsMapping', lstFields);

    // Get price book
    List<PriceBook2> listPriceBook = [
      SELECT Id, Name
      FROM PriceBook2
      WHERE IsActive = TRUE
    ];
    mapResults.put('listPriceBook', listPriceBook);
    mapResults.put('priceBookId', lstForm[0].Price_Book__c);

    // Get products
    List<Form_Product__c> productList = [
      SELECT Id, Name, Product__c, Form__c, value__c, unit_price__c, Available_Product_Quantity__c
      FROM Form_Product__c
      WHERE Form__c = :formid
    ];

    Set<Id> setProductIds = new Set<Id>();
    for (Form_Product__c fp : productList) {
      setProductIds.add(fp.Product__c);
    }

    List<PricebookEntry> lstPriceBook = [
      SELECT Id, UnitPrice, Product2Id
      FROM PricebookEntry
      WHERE
        Pricebook2Id = :lstForm[0].Price_Book__c
        AND Product2Id IN :setProductIds
    ];
    System.debug('lstPrice:' + lstPriceBook);

    Map<Id, Decimal> mapProductPrice = new Map<Id, Decimal>();
    for (PricebookEntry pre : lstPriceBook) {
      mapProductPrice.put(pre.Product2Id, pre.UnitPrice);
    }

    //List of products
    List<FormProductData> lstProductData = new List<FormProductData>();
    for(Form_Product__c fp : productList) {
      FormProductData productData = new FormProductData();
      productData.id = fp.id;
      productData.name = fp.name;
      productData.formId = fp.Form__c;
      productData.productId = fp.Product__c;
      productData.unitPrice = fp.unit_price__c;
      productData.maxQuantityOfProduct = Integer.valueOf(fp.Available_Product_Quantity__c);
      lstProductData.add(productData);
    }

    for (FormProductData dataProduct : lstProductData) {
      if (mapProductPrice.containsKey(dataProduct.productId)) {
        dataProduct.unitPrice = mapProductPrice.get(dataProduct.productId);
      } else {
        dataProduct.unitPrice = 0;
      }
    }
    System.debug('Product Data List: ' + lstProductData);
    mapResults.put('productList', JSON.serialize(lstProductData));

    System.debug('Map result: ' + mapResults);
    return mapResults;
  }

  public static void updateMapParentChilds(
    String formId,
    Map<Id, Form_Component__c> mapCmp,
    Map<Id, List<Component>> mapParentChilds
  ) {
    String formObject;

    try {
      List<Form__c> lstForms = [
        SELECT Id, Object_Reference_N__c, Field_Relationship__c
        FROM Form__c
        WHERE Id = :formId
      ];
      formObject = lstForms[0].Object_Reference_N__c;
    } catch (Exception e) {
      System.debug(e.getMessage());
    }

    for (Form_Component__c cmp : mapCmp.values()) {
      Component childcmp = new Component();

      childcmp.id = cmp.Id;
      childcmp.key = cmp.Name;
      childcmp.label = cmp.Label__c;
      childcmp.type = cmp.Type__c;
      childcmp.order = cmp.Order__c.intValue();
      childcmp.isRequired = cmp.isRequired__c;
      childcmp.mapping = cmp.Mapping__c;
      childcmp.variable = cmp.Variable__c;
      childcmp.defaultValue = cmp.Default_Value__c;
      childcmp.isReceiptEmailField = cmp.isReceiptEmail__c;
      childcmp.isHidden = cmp.isHidden__c;
      childcmp.isYesNoOption = cmp.IsYes_NoOption__c;
      childcmp.options = cmp.Options__c;
      childcmp.isAddFieldToQuery = cmp.Does_Field_Add_To_Query__c;

      if (cmp.Column_Size__c != null) {
        childcmp.columnSize = cmp.Column_Size__c.intValue();
      }

      if (childcmp.type == 'Text') {
        childcmp.isField = true;
      }

      if (childcmp.type == 'spacer') {
        childcmp.isSpacer = true;
      }

      /* if(childcmp.type == 'Pick_List'){
        childcmp.isPicklist = true;
        // update data value for pickListValue property of comp
        List<String> fieldInfo = getFieldInfo(childcmp.mapping);
        System.debug(fieldInfo);
        // get picklist value from fieldInfo
        SObjectType sObjType = ((SObject) Type.forName(fieldInfo[0]).newInstance()).getSObjectType();


        childcmp.pickListValue = getPicklist(sObjType, fieldInfo[1]);
      } */

      // set for multi picklist
      if (childcmp.type == 'checkbox' || childcmp.type == 'Pick_List') {
        if (childcmp.type == 'checkbox') {
          childcmp.isCheckbox = true;
        } else
          childcmp.isPicklist = true;
        // update data value for checkbox property of comp
        // List<String> fieldInfo = getFieldInfo(childcmp.mapping); // object, field
        System.debug(childcmp.mapping);
        // get picklist value from fieldInfo
        SObjectType sObjType = ((SObject) Type.forName(formObject)
            .newInstance())
          .getSObjectType();
        childcmp.optionsValue = getPicklist(sObjType, childcmp.mapping);
        // System.debug('option value: '+ childcmp.type + ' ;' + childcmp.optionsValue);
        System.debug('component: ' + childcmp);
      }

      if (childcmp.type == 'radioGroup') {
        childcmp.isRadioGroup = true;
      }
      if(childcmp.type == 'Promotion') {
        childcmp.isPromotionCmp = true;
      }
      if (childcmp.type == 'Payment_Form') {
        childcmp.isPaymentForm = true;
      }
      if (childcmp.type == 'image') {
        childcmp.isImage = true;
        childcmp.imageUrl = cmp.Image_URL__c;
        childcmp.imageAltText = cmp.Alternate_Text__c;
      }

      if (childcmp.type == 'Product_List') {
        childcmp.isProductList = true;
      }

      if (childcmp.type == 'Display_Text') {
        childcmp.isDisplayText = true;
        childcmp.value = cmp.DisplayText__c;
        childcmp.valuereplaced = cmp.DisplayText__c;
      }

      if (childcmp.type == 'confirmationsBox') {
        childcmp.isConfirmationCheckbox = true;
        childcmp.label = cmp.Confirmation_Content__c;
      }

      if (childcmp.type == 'address') {
        childcmp.isAddress = true;
      }

      if (childcmp.type == 'inputDate') {
        childcmp.isInputDate = true;
      }

      childcmp.childs = new List<Component>();

      if (String.isNotBlank(cmp.Parent__c)) {
        childcmp.parentid = cmp.Parent__c;
      } else {
        childcmp.parentid = cmp.Form__c;
      }

      if (mapParentChilds.containsKey(cmp.Id)) {
        childcmp.childs.addAll(mapParentChilds.get(cmp.Id));
      }

      if (mapParentChilds.containsKey(childcmp.parentid)) {
        mapParentChilds.get(childcmp.parentid).add(childcmp);
      } else {
        mapParentChilds.put(childcmp.parentid, new List<Component>{ childcmp });
      }
    }
  }

  public static Map<Id, Form_Component__c> getCmpByParentIds(
    Set<Id> parentIds
  ) {
    Map<Id, Form_Component__c> mapCmps = new Map<Id, Form_Component__c>(
      [
        SELECT
          Alternate_Text__c,
          Column_Size__c,
          CreatedById,
          Default_Value__c,
          DisplayText__c,
          Form__c,
          Id,
          Image_URL__c,
          IsDeleted,
          Label__c,
          Mapping__c,
          Name,
          Order__c,
          OwnerId,
          Parent__c,
          Type__c,
          Variable__c,
          isCheckDuplicate__c,
          isHidden__c,
          isIdentify__c,
          isReceiptEmail__c,
          isRequired__c,
          Confirmation_Content__c,
          IsYes_NoOption__c,
          Options__c,
          Does_Field_Add_To_Query__c
        FROM Form_Component__c
        WHERE Parent__c IN :parentIds OR Form__c IN :parentIds
        ORDER BY Order__c ASC
      ]
    );
    return mapCmps;
  }

  public static List<Map<String, String>> getListFields(String objName) {
    try {
      SObject cont = (SObject) (Type.forName('Schema.' + objName)
        .newInstance());
      Schema.SObjectType typeOfObject = cont.getSObjectType();
      Schema.DescribeSObjectResult sobjectDescribeResult = typeOfObject.getDescribe();
      Map<String, Schema.SObjectField> fieldMap = sobjectDescribeResult.fields.getMap();
      // Schema.SObjectField fieldProperty = fieldMap.get(fieldName);
      System.debug('123: ' + fieldMap.keySet());
      Set<String> setFields = fieldMap.keySet();
      List<String> listFields = new List<String>(setFields);
      listFields.sort();

      List<Map<String, String>> lstFields = new List<Map<String, String>>();
      for (String field : listFields) {
        System.debug(
          'Can Update: ' +
          fieldMap.get(field).getDescribe().isUpdateable() +
          'field: ' +
          fieldMap.get(field).getDescribe().getName()
        );
        if (fieldMap.get(field).getDescribe().isUpdateable()) {
          fieldMap.get(field).getDescribe().getName();
          lstFields.add(
            new Map<String, String>{
              'label' => fieldMap.get(field).getDescribe().getLabel(),
              'value' => fieldMap.get(field).getDescribe().getName()
            }
          );
        }
      }

      System.debug(lstFields);
      return lstFields;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static string getNameSpacePrefix() {
    String nameSpacePrefix;
    String[] parts = String.valueOf(FormBuilderCtrl.class).split('\\.', 2);
    if (parts.size() > 1) {
      Type classType = Type.forName(parts[0], parts[1]);
      if (classType == FormBuilderCtrl.class) {
        nameSpacePrefix = parts[0];
      } else {
        nameSpacePrefix = '';
      }
    } else {
      nameSpacePrefix = '';
    }
    return nameSpacePrefix;
  }

  @AuraEnabled
  public static String getMapPaymentFee(){
    Map<String, Decimal> payFee = new Map<String, Decimal>();
    String strPaymentFee;
    try {
      List<PaymentSetting__mdt> paymentSetting = new List<PaymentSetting__mdt>();
      paymentSetting = [SELECT Marchant_Fee_Mastercard__c, Merchant_Fee_Amex__c, Merchant_Fee_Visa__c FROM PaymentSetting__mdt WHERE Label = 'Payment Setting'];
      if(paymentSetting.size() > 0) {
        // PaymentSetting__mdt paymentFees = paymentSetting[0];
        // strPaymentFee = JSON.serialize(paymentFees);
        payFee.put('Marchant_Fee_Mastercard', paymentSetting[0].Marchant_Fee_Mastercard__c);
        payFee.put('Marchant_Fee_Amex', paymentSetting[0].Merchant_Fee_Amex__c);
        payFee.put('Merchant_Fee_Visa', paymentSetting[0].Merchant_Fee_Visa__c);
        strPaymentFee = JSON.serialize(payFee);
      }
    } catch (Exception e) {
      System.debug('Error when getting map payment fee.');
      throw new AuraHandledException(e.getMessage());
    }
    return strPaymentFee;
  }

  public class FormProductData {
    public Decimal unitPrice;	//5000
		public String productId;	//01t5h000007Nbz1AAC
		public String name;	//GenWatt Diesel 10kW
		public String id;	//a025h00000mTB83AAG
		public String formId;	//a035h00000duMANAA2
    public Integer maxQuantityOfProduct;
    public Decimal value;
    // public FormProductData (String id, String name, String formId, String productId, Decimal unitPrice) {
    //   this.id = id;
    //   this.name = name;
    //   this.formId = formId;
    //   this.productId = productId;
    //   this.unitPrice = unitPrice;
    // }
  }
}