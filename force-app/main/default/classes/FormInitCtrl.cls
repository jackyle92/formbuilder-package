/**
 * Classname: FormInitCtrl
 * Author: Vinh Hua
 * Created Date: 2022/07/20
 */

public without sharing class FormInitCtrl {

  public class CustomException extends Exception {}
  // Add filter to the contact query <NameField, Value> Ex. <'MemberNumber__c', '1223992'>
  public static Map<String, String> mapFilterContactQuery = new Map<String, String>();

  @AuraEnabled
  public static Map<String, Object> initData(String formid) {

    if (!Test.isRunningTest()) {
      try {
        String activeLicense = ProductLicenseManagement.getActiveLicense();
        System.debug('activeLicense: ' + activeLicense);
        if (activeLicense == null) {
          System.debug('Do not have license');
          throw new ProductsException(
            'You Do not have license to perform this action'
          );
        }
      } catch (Exception e) {
        System.debug('Error, when try to get the active license.');
        throw new FormBuilderException(
          'Error, when try to get the active license. Please contact to owner of product to solve this problem.'
        );
      }
    }

    Map<String, Object> mapResults = FormBuilderHelper.initHelper(formid);

    PaymentSetting__mdt config = [
      SELECT IntegraPay_endpoint__c, IntegraPay_Business_Key__c
      FROM PaymentSetting__mdt
      WHERE DeveloperName = :Constants.PAYMENT_SETTING
    ];

    mapResults.put('isHaveLicense', true);
    mapResults.put('endpoint', config.IntegraPay_endpoint__c);
    mapResults.put('businesskey', config.IntegraPay_Business_Key__c);
    // mapResults.put('linkobject', config.LinkOppToObject__c);
    // mapResults.put('linkfield', config.LinkOppUsingField__c);

    return mapResults;
  }

  public static Map<String, List<FieldWrapper>> getMapData(
    String linkobject,
    List<Component> lstComponent
  ) {
    // String emailForSendingReceipt;
    Map<String, List<FieldWrapper>> mapData = new Map<String, List<FieldWrapper>>();
    for (
      Integer indexScreen = 0; indexScreen < lstComponent.size(); indexScreen++
    ) {
      for (
        Integer indexLayout = 0;
        indexLayout < lstComponent[indexScreen].childs.size();
        indexLayout++
      ) {
        for (
          Integer indexColumn = 0;
          indexColumn <
          lstComponent[indexScreen].childs[indexLayout].childs.size();
          indexColumn++
        ) {
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
            if (childCmp.isAddFieldToQuery != null && childCmp.isAddFieldToQuery != false) {
              mapFilterContactQuery.put(
                childCmp.mapping,
                childCmp.value.trim()
              );
            }
            if (String.isNotBlank(childCmp.mapping)) {
              FieldWrapper fm = new FieldWrapper();
              fm.fieldName = childCmp.mapping;
              fm.fieldValue = childCmp.value;
              if (mapData.containsKey(linkobject)) {
                mapData.get(linkobject).add(fm);
              } else {
                mapData.put(linkobject, new List<FieldWrapper>{ fm });
              }
            }
            //for composite address field
            try {
              if (childCmp.isAddress != null && childCmp.isAddress == true) {
                AddressElement addressComp = AddressElement.parse(
                  childCmp.address
                );
                mapData.get(linkobject)
                  .add(new FieldWrapper('MailingStreet', addressComp.street));
                mapData.get(linkobject)
                  .add(new FieldWrapper('MailingCity', addressComp.city));
                mapData.get(linkobject)
                  .add(new FieldWrapper('MailingState', addressComp.province));
                mapData.get(linkobject)
                  .add(
                    new FieldWrapper(
                      'MailingPostalCode',
                      addressComp.postalCode
                    )
                  );
                mapData.get(linkobject)
                  .add(new FieldWrapper('MailingCountry', addressComp.country));

                // System.debug('Address: ' + addressComp);
                // addressWrapper.fieldAddress = addressComp;
                System.debug('Finished Data Mapping: ' + mapData);
              }
            } catch (Exception e) {
              System.debug('Got an error at try to map address field');
              System.debug(e.getMessage());
              return null;
            }
          }
        }
      }
    }
    return mapData;
  }

  public static List<sObject> correctFieldTypeBeforeUpsert(
    String linkobject,
    Map<String, List<FieldWrapper>> mapData
  ) {
    List<sObject> lstRecord = new List<sObject>();

    Integer linkObjIndex = 0;
    String linkObjectName = linkobject;
    String email = '';
    String firstName = '';
    String lastName = '';
    for (String objectName : mapData.keySet()) {
      sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject();
      for (FieldWrapper fwrapper : mapData.get(objectName)) {
        String typeField = String.valueOf(
          ((SObject) (Type.forName('Schema.' + objectName).newInstance()))
            .getSObjectType()
            .getDescribe()
            .fields.getMap()
            .get(fwrapper.fieldName)
            .getDescribe()
            .getType()
        );
        // find the type of field
        if (typeField == 'BOOLEAN') {
          if (fwrapper.fieldValue == 'true') {
            sObj.put(fwrapper.fieldName, true);
          } else {
            sObj.put(fwrapper.fieldName, false);
          }
        } else if (typeField == 'Date') {
          Date dateValue = date.valueOf(fwrapper.fieldValue);
          sObj.put(fwrapper.fieldName, dateValue);
        } else {
          if (fwrapper.fieldName == 'Email') {
            fwrapper.fieldValue = fwrapper.fieldValue.trim().toLowerCase();
            email = fwrapper.fieldValue;
          } else if (fwrapper.fieldName == 'FirstName') {
            firstName = fwrapper.fieldValue;
          } else if (fwrapper.fieldName == 'LastName') {
            lastName = fwrapper.fieldValue;
          }
          sObj.put(fwrapper.fieldName, fwrapper.fieldValue);
        }
      }

      // check map filter is not empty // support for one map value
      if (!mapFilterContactQuery.isEmpty()) {
        String fieldName = '';
        String fieldValue = '';
        for (String filterName : mapFilterContactQuery.keySet()) {
          fieldName = filterName;
          fieldValue = mapFilterContactQuery.get(filterName);
        }
        for (String objName : mapData.keySet()) {
          String strQuery =
            'SELECT Id FROM ' +
            objName +
            ' WHERE Email = ' +
            '\'' +
            email +
            '\'' +
            ' AND ' +
            fieldName +
            ' = ' +
            '\'' +
            fieldValue +
            '\'' +
            ' Limit 1';
          List<sObject> existRecord = Database.query(strQuery);
          System.debug('Query: ' + existRecord);
          if (existRecord.size() > 0) {
            sObj.put('Id', existRecord[0].Id);
          }
        }
      } else {
        for (String objName : mapData.keySet()) {
          String strQuery =
            'SELECT Id FROM ' +
            objName +
            ' WHERE Email = ' +
            '\'' +
            email +
            '\'' +
            ' Limit 1';
          List<sObject> existRecord = Database.query(strQuery);
          System.debug('query: ' + Database.query(strQuery));
          if (existRecord.size() > 0) {
            sObj.put('Id', existRecord[0].Id);
          }
        }
      }

      lstRecord.add(sObj);
    }
    return lstRecord;
  }

  public static Map<String, String> getReceiptData(
    String linkobject,
    Map<String, List<FieldWrapper>> mapData
  ) {
    Map<String, String> mapReceiptData = new Map<String, String>();

    Integer linkObjIndex = 0;
    String linkObjectName = linkobject;
    for (String objectName : mapData.keySet()) {
      for (FieldWrapper fwrapper : mapData.get(objectName)) {
        if (fwrapper.fieldName == 'Email') {
          mapReceiptData.put('Email', fwrapper.fieldValue);
        } else if (fwrapper.fieldName == 'FirstName') {
          mapReceiptData.put('FirstName', fwrapper.fieldValue);
        } else if (fwrapper.fieldName == 'LastName') {
          mapReceiptData.put('LastName', fwrapper.fieldValue);
        }
      }
    }
    return mapReceiptData;
  }

  public static String getFormId(List<Component> lstComponent) {
    String formId;
    for (
      Integer indexScreen = 0; indexScreen < lstComponent.size(); indexScreen++
    ) {
      formId = lstComponent[0].parentid;
      System.debug('formId: ' + formId);
    }
    return formId;
  }

  @AuraEnabled
  public static String submitForm(String jsonData, String linkobject) {
    List<Component> lstComponent = (List<Component>) JSON.deserialize(
      jsonData,
      List<Component>.class
    );
    Map<String, List<FieldWrapper>> mapData = new Map<String, List<FieldWrapper>>();

    mapData = getMapData(linkobject, lstComponent);

    System.debug('map filter contact query: ' + mapFilterContactQuery);

    try {
      Integer indexObj = 0;
      List<sObject> lstRecord = correctFieldTypeBeforeUpsert(
        linkobject,
        mapData
      );
      try {
        upsert lstRecord;
      } catch (DmlException e) {
        System.debug(e.getMessage());
        System.debug('Exception! Error when upsert records');
        return null;
      }
      /**
       * Insert data to form data
      Form_Data__c formData = new Form_Data__c();
      formData.Form_Name__c = formName;
      formData.Json_Data__c = jsonData;
      formData.Time_Submitted__c = Datetime.now();

      try {
        insert formData;
      } catch (Exception e) {
        System.debug(e.getMessage());
        System.debug('Exception! Error when insert submitted data');
      }
       */
      System.debug('==lstRecord==' + lstRecord);
      return 'Success Submission';
    } catch (Exception e) {
      System.debug('Exception! Global Error when trying to submit form');
      throw new AuraHandledException(e.getMessage());
    }
  }


  @AuraEnabled
  public static Map<String, String> processPayment(
    String jsonData,
    String linkobject,
    String linkfield,
    String cardToken,
    String productListStr,
    String priceBookId,
    Boolean deductedFromSettlement,
    String promotionCode
  ) {

    String formId = '';
    Decimal proRate = 0;

    List<Component> lstComponent = (List<Component>) JSON.deserialize(
      jsonData,
      List<Component>.class
    );
    List<FormSetting.cls_productList> productList = (List<FormSetting.cls_productList>) JSON.deserialize(
      productListStr,
      List<FormSetting.cls_productList>.class
    );

    String emailForSendingReceipt = '';
    String firstName = '';
    String lastName = '';
    Map<String, List<FieldWrapper>> mapData = new Map<String, List<FieldWrapper>>();

    mapData = getMapData(linkobject, lstComponent);

    System.debug('map filter contact query: ' + mapFilterContactQuery);
    formId = getFormId(lstComponent);

    Map<Id, Integer> mapProductIds = new Map<Id, Integer>();
    System.debug('PRODUCT LIST: ' + productList);
    //Value in product list is the quantity 
    for (FormSetting.cls_productList fpr : productList) {
      Integer valueData = 0;
      if (fpr.value != null) {
        valueData = fpr.value.intValue();
      }
      mapProductIds.put(fpr.productId, valueData);
    }
    System.debug('==mapProductIds==' + mapProductIds); // productId : quantity

    // get price amount
    List<PricebookEntry> lstPricebookEntry = [
      SELECT Id, UnitPrice, Pricebook2Id, Product2Id, Pricebook2.Name
      FROM PricebookEntry
      WHERE
        Pricebook2.IsActive = TRUE
        AND Pricebook2.Id = :priceBookId
        AND Product2Id IN :mapProductIds.keySet()
      ORDER BY CreatedDate DESC
    ];

    System.debug('==lstPricebookEntry==' + lstPricebookEntry);

    // get unique reference
    String uniqueString =
      Datetime.now().format('yyyyMMddHHmmssSSS') +
      Math.round((Math.random() * (900000) + 100000));

    Map<String, String> result = new Map<String, String>();

    try {
      Integer linkObjIndex = 0;
      String linkObjectName = linkobject;
      String linkOppField = linkfield;

      List<sObject> lstRecord = new List<sObject>();
      Integer indexObj = 0;

      System.debug('mapData: ' + mapData);
      lstRecord = correctFieldTypeBeforeUpsert(linkObjectName, mapData);
      Map<String, String> receiptData = new Map<String, String>(); // email, first name, last name
      receiptData = getReceiptData(linkobject, mapData);
      System.debug(receiptData);

      emailForSendingReceipt = receiptData.get('Email');
      firstName = receiptData.get('FirstName');
      lastName = receiptData.get('LastName');
      System.debug('==lstRecord==');
      System.debug(lstRecord);

      IntegraPayService.PayerInfo payer = new IntegraPayService.PayerInfo();
      if (String.isNotBlank(emailForSendingReceipt)) {
        payer.email = emailForSendingReceipt;
      }
      payer.savePayer = false;

      PaymentSetting__mdt config = [
        SELECT IntegraPay_Deducted_From_Settlement__c
        FROM PaymentSetting__mdt
        WHERE DeveloperName = :Constants.PAYMENT_SETTING
      ];

      Decimal totalAmount = 0;
      for (PricebookEntry pbEntry : lstPricebookEntry) {
        if (mapProductIds.containsKey(pbEntry.Product2Id)) {
          totalAmount +=
            pbEntry.UnitPrice * mapProductIds.get(pbEntry.Product2Id);
        }
      }

      System.debug('prom-code: '+promotionCode);
      if(promotionCode != null) {
        proRate = Promotion_Code_Controller.getRateFromPromtionCode(promotionCode,formId);
        if(proRate > 0) {
          totalAmount -= (totalAmount * proRate)/ 100;
        }
      }


      System.debug('==totalAmount==' + totalAmount);

      IntegraPayService.IntegraTransRequest req = new IntegraPayService.IntegraTransRequest();
      req.Amount = totalAmount;
      req.ProcessType = 'COMPLETE';
      req.Reference = uniqueString;
      req.CurrencyCode = 'AUD';
      req.CardToken = cardToken;
      req.Payer = payer;
      req.profile = 1;
      if (
        config.IntegraPay_Deducted_From_Settlement__c != deductedFromSettlement
      )
        // req.profile = 2;
      System.debug('Before');
      IntegraPayService.IntegraTransResponse response = IntegraPayService.processLiveTransaction(req);


      if (response.statusCode == Constants.STATUS_CODE_SUCCESS) {

        //update promotioncode status to used
        if(promotionCode != null) {
          Promotion_Code_Controller.updateUsedPromotionCode(promotionCode, formId);
        }
        Decimal feePerMember = (response.processedAmount - totalAmount)
          .divide(1, 2, System.RoundingMode.DOWN);

        System.debug('response statuscode: ' + response.statusCode);
        upsert lstRecord;
        //Create opp
        Opportunity opp = new Opportunity();
        List<Form__c> fB = [
          SELECT Id, name, Form_Name__c
          FROM Form__c
          WHERE Id = :formId
        ];
        String formName = '';
        if (fB.size() > 0) {
          formName = fB[0].Form_Name__c;
        }
        opp.Name =
          formName +
          '-' +
          firstName +
          ' ' +
          lastName +
          '-' +
          Datetime.now().format('yyyy/MM/dd');
        opp.StageName = 'Closed Won';
        opp.Pricebook2Id = priceBookId;
        opp.CloseDate = System.Today();
        opp.Transaction_Id__c = response.transactionId;
        opp.IntegraPay_Reference__c = response.reference;
        opp.IntegraPay_Transaction_Fee__c = feePerMember;
        opp.Transaction_fee_deducted_from_settlement__c = feePerMember > 0
          ? false
          : true;
        opp.put(linkOppField, lstRecord[linkObjIndex].Id);

        insert opp;

        List<OpportunityLineItem> lstOppLine = new List<OpportunityLineItem>();
        for (PricebookEntry pbEntry : lstPricebookEntry) {
          if (mapProductIds.containsKey(pbEntry.Product2Id)) {
            Integer prdquantity = mapProductIds.get(pbEntry.Product2Id);
            if (prdquantity != 0) {
              System.debug('product quantity: ' + prdquantity);
              OpportunityLineItem oppLine = new OpportunityLineItem();
              oppLine.Product2Id = pbEntry.Product2Id;
              // oppLine.Quantity = mapProductIds.get(pbEntry.Product2Id);
              oppLine.Quantity = prdquantity;
              oppLine.UnitPrice = pbEntry.UnitPrice;
              oppLine.OpportunityId = opp.Id;
              oppLine.PricebookEntryId = pbEntry.Id;
              if(proRate > 0 ) {
                oppLine.Discount = proRate;
              }
              lstOppLine.add(oppLine);
            }
          }
        }
        if (!lstOppLine.isEmpty()) {
            insert lstOppLine;
        }
        // Update the available quantity of form product
        updateQuantityOfFormProducts(productList);
        result.put('Status', 'Success');
        /**
         * // Log form data to SF Form_Data object
        try{
          Form_Data__c formData = new Form_Data__c();
          formData.Form_Name__c = formName;
          formData.Json_Data__c = jsonData;
          formData.Time_Submitted__c = Datetime.now();
          insert formData;
        } catch (Exception e) {
          System.debug('Error: ' + e.getMessage());
        }
         */
      } else {
        result.put('Status', 'Fail');
        result.put('Message', response.statusDescription);
        System.debug('Error response: ' + response);
      }

      return result;
    } catch (System.CalloutException e) {
      result.put('Status', 'Fail');
      result.put(
        'Message',
        'Payment is pending. Please contact our customer service for further support.'
      );
      return result;
    } catch (Exception e) {
      result.put('Status', 'Fail');
      result.put(
        'Message',
        'Some errors occur. Please contact our customer service for further support.'
      );
      return result;
    }
  }


  public class FieldWrapper {
    public String fieldName;
    public String fieldValue;
    public AddressElement fieldAddress;

    public FieldWrapper() {
    }

    public FieldWrapper(String fieldName, String fieldValue) {
      this.fieldName = fieldName;
      this.fieldValue = fieldValue;
    }
  }

  /**
   * @Description: Update the quantity for form product
   * @param: Form Id, productList
   * @return 
   */
  public static void updateQuantityOfFormProducts( List<FormSetting.cls_productList> formProductList) {
    List<Form_Product__c> formProductsUpdate = new List<Form_Product__c>();
    for(FormSetting.cls_productList fp: formProductList){
      if(fp.value != null) {
        Form_Product__c formProductUpdate = new Form_Product__c();
        formProductUpdate.Id = fp.id;
        formProductUpdate.Available_Product_Quantity__c = fp.maxQuantityOfProduct - fp.value;
        formProductsUpdate.add(formProductUpdate);
      }
    }
    System.debug('Update Quantity: ' + formProductsUpdate);
    if(formProductsUpdate.size() > 0) {
      update formProductsUpdate;
    }
  }
}