/**
 * Classname: FormBuilderCtrl
 * Author: Vinh Hua
 * Created Date: 2022/07/20
 */
public with sharing class FormBuilderCtrl {
  @AuraEnabled
  public static Map<String, Object> initData(String formid) {
    Map<String, Object> mapResults = FormBuilderHelper.initHelper(formid);

    PaymentSetting__mdt companyinfo = [
      SELECT
        Company_Name__c,
        Email__c,
        Facebook__c,
        Instagram__c,
        Twitter__c,
        Phone__c,
        Physical_Address__c,
        Terms_Conditions__c,
        NamespacePrefix
      FROM PaymentSetting__mdt
      WHERE DeveloperName = :Constants.PAYMENT_SETTING
    ];

    return mapResults;
  }

  @AuraEnabled
  public static String getProduct(String productId) {
    List<Product2> lstProduct = [
      SELECT Id, Name
      FROM Product2
      WHERE Id = :productId
    ];
    if (!lstProduct.isEmpty()) {
      return JSON.serialize(lstProduct[0]);
    } else {
      return JSON.serialize(new Product2());
    }
  }

  /**
   * @AuraEnabled
   * @Description:
   * @param: String all comp of screen, String formSetting (color, product, ...), List<String> lstRemoveId
   */

  @AuraEnabled
  public static void saveForm(
    String jsonData,
    String formSetting,
    List<String> lstRemoveId
  ) {
    try {
      Boolean isHaveLicense = true;
      // if (!Test.isRunningTest()) {
      //   isHaveLicense = cppexchange.LicenseActivationChecking.isHaveLicense(
      //     'CCP_Form_Builder'
      //   );
      // }


      if(!Test.isRunningTest()) {
        try {
          String activeLicense = ProductLicenseManagement.getActiveLicense();
          System.debug('activeLicense: ' + activeLicense);
          if(activeLicense == null) {
            System.debug('Do not have license');
            throw new ProductsException('You Do not have license to perform this action');
          }
        } catch (Exception e) {
          System.debug('Error, when try to get the active license.');
          throw new FormBuilderException('Error, when try to get the active license. Please contact to owner of product to solve this problem.');
        }
      }

      /*
      if (!isHaveLicense) {
        System.debug('Do not have license.');
        throw new FormBuilderException('Do not have license.');
      }
      */
      System.debug('==formSetting==');
      System.debug(formSetting);

      FormSetting fsetting = (FormSetting) JSON.deserialize(
        formSetting,
        FormSetting.class
      );

      Form__c form = new Form__c();
      form.Id = fsetting.id;
      form.Brand_Color__c = fsetting.brandColor;
      form.Thank_You_Page__c = fsetting.thankYouPageContent;
      form.Use_Thank_You_Page__c = fsetting.isUseThankYouPage;
      form.Duplicate_Process__c = fsetting.duplicateSelected;
      form.Price_Book__c = fsetting.pricebookId;
      form.Currency_Code__c = fsetting.currencyCode;
      form.Object_Reference_N__c = fsetting.objectReference;
      // form.isMaxQPEqual_to_1__c = fsetting.isMaxQEqualto1;
      update form;

      if (!fsetting.productListDel.isEmpty()) {
        Database.delete(fsetting.productListDel);
      }

      System.debug('==fsetting.productList==' + fsetting.productList);
      if (!fsetting.productList.isEmpty()) {
        upsert fsetting.productList;
      }

      List<Form_Component__c> lstScreen = new List<Form_Component__c>();

      List<Component> lstComponent = (List<Component>) JSON.deserialize(
        jsonData,
        List<Component>.class
      );

      List<Form_Component__c> lstChildCmp = new List<Form_Component__c>();

      for (
        Integer indexScreen = 0;
        indexScreen < lstComponent.size();
        indexScreen++
      ) {
        Form_Component__c screenObject = new Form_Component__c();

        if (String.isNotBlank(lstComponent[indexScreen].id)) {
          screenObject.Id = lstComponent[indexScreen].id;
        }

        screenObject.Form__c = fsetting.id;
        screenObject.Label__c = lstComponent[indexScreen].label;
        screenObject.Order__c = indexScreen;
        screenObject.Type__c = lstComponent[indexScreen].type;

        upsert screenObject;

        for (
          Integer indexLayout = 0;
          indexLayout < lstComponent[indexScreen].childs.size();
          indexLayout++
        ) {
          Component ly = lstComponent[indexScreen].childs[indexLayout];

          Form_Component__c layoutObject = new Form_Component__c();

          if (String.isNotBlank(ly.id)) {
            layoutObject.Id = ly.id;
          }

          layoutObject.Parent__c = screenObject.Id;
          layoutObject.Label__c = ly.label;
          layoutObject.Order__c = indexLayout;
          layoutObject.Type__c = ly.type;

          upsert layoutObject;

          for (
            Integer indexColumn = 0;
            indexColumn <
            lstComponent[indexScreen].childs[indexLayout].childs.size();
            indexColumn++
          ) {
            Component col = lstComponent[indexScreen]
              .childs[indexLayout]
              .childs[indexColumn];
            Form_Component__c columnObject = new Form_Component__c();
            if (String.isNotBlank(col.id)) {
              columnObject.Id = col.id;
            }
            columnObject.Parent__c = layoutObject.Id;
            columnObject.Label__c = col.label;
            columnObject.Order__c = indexColumn;
            columnObject.Type__c = col.type;
            columnObject.Column_Size__c = col.columnSize;
            upsert columnObject;

            for (
              Integer indexCmp = 0;
              indexCmp <
              lstComponent[indexScreen]
                .childs[indexLayout]
                .childs[indexColumn]
                .childs.size();
              indexCmp++
            ) {
              Component childCmp = lstComponent[indexScreen]
                .childs[indexLayout]
                .childs[indexColumn]
                .childs[indexCmp];

              Form_Component__c cmpObject = new Form_Component__c();

              // update Form Id form cmp Object
              if (String.isNotBlank(childCmp.id)) {
                cmpObject.Id = childCmp.id;
              }
              if (String.isNotBlank(childCmp.mapping)) {
                cmpObject.Mapping__c = childCmp.mapping;
              }
              if (String.isNotBlank(childCmp.variable)) {
                cmpObject.Variable__c = childCmp.variable;
              }
              cmpObject.Parent__c = columnObject.Id;
              cmpObject.Order__c = indexCmp;
              cmpObject.Type__c = childCmp.type;

              if (childCmp.options != null) {
                cmpObject.Options__c = childCmp.options;
              }

              if (childCmp.isConfirmationCheckbox != null) {
                cmpObject.Confirmation_Content__c = childCmp.label;
              } else {
                cmpObject.Label__c = childCmp.label;
              }
              if (childCmp.isYesNoOption != null) {
                cmpObject.IsYes_NoOption__c = childCmp.isYesNoOption;
              }
              if (childCmp.isRequired != null) {
                cmpObject.isRequired__c = childCmp.isRequired;
              }
              if (childCmp.defaultValue != null) {
                cmpObject.Default_Value__c = childCmp.defaultValue;
              }
              if (childCmp.isReceiptEmailField != null) {
                cmpObject.isReceiptEmail__c = childCmp.isReceiptEmailField;
              }
              if(childCmp.isAddFieldToQuery != null) {
                cmpObject.Does_Field_Add_To_Query__c = childCmp.isAddFieldToQuery;
              }

              // hidden
              if (childCmp.isHidden != null) {
                cmpObject.isHidden__c = childCmp.isHidden;
              }

              if (
                childCmp.isDisplayText != null &&
                childCmp.isDisplayText == true
              ) {
                cmpObject.DisplayText__c = childCmp.value;
              }
              //added for image url and alt text attributes
              if (
                childCmp.isImage == true &&
                childCmp.imageUrl != null &&
                childCmp.imageAltText != null
              ) {
                cmpObject.Image_URL__c = childCmp.imageUrl; //childCmp.imgUrl;
                cmpObject.Alternate_Text__c = childCmp.imageAltText; //childCmp.imgAltText;
              }
              lstChildCmp.add(cmpObject);
            }
          }
        }
      }

      if (!lstChildCmp.isEmpty()) {
        upsert lstChildCmp;
      }

      if (!lstRemoveId.isEmpty()) {
        Database.delete(lstRemoveId, false);
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static List<Map<String, String>> getPicklistValue(
    String objectName,
    String fieldName
  ) {
    List<String> listValues = new List<String>();
    SObjectType sObjType = ((SObject) Type.forName(objectName).newInstance())
      .getSObjectType();
    listValues = FormBuilderHelper.getPicklist(sObjType, fieldName);
    List<Map<String, String>> options = new List<Map<String, String>>();
    for (String value : listValues) {
      options.add(
        new Map<String, String>{ 'label' => value, 'value' => value }
      );
    }
    System.debug(options);
    return options;
  }
}