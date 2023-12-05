@isTest
public with sharing class FormInitCtrlTest {
    
    @isTest 
    public static void testInitData(){
        
        Form__c testForm = new Form__c();
        testForm.Form_Name__c = 'Test Form';
        testForm.Brand_Color__c = '#FFFFFF';
        testForm.isMaxQPEqual_to_1__c = false;
        testForm.Object_Reference_N__c = 'Contact';
        insert testForm;

        Test.startTest();
        Map<String,Object> mapResults = FormInitCtrl.initData(testForm.Id);
        Test.stopTest();

        System.assertEquals(true, mapResults.size() > 0);
    }

    @isTest 
    public static void testProcessPayment(){

        Form__c testForm = new Form__c();
        testForm.Form_Name__c = 'Test Form';
        testForm.Brand_Color__c = '#FFFFFF';
        testForm.isMaxQPEqual_to_1__c = false;
        testForm.Object_Reference_N__c = 'Contact';
        insert testForm;

        Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware');
        insert prod;
        
        Form_Product__c fp = new Form_Product__c();
        fp.Product__c = prod.Id;
        fp.Form__c = testForm.Id;
        fp.Name = prod.Name;
        insert fp;

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = prod.Id,
        UnitPrice = 50, IsActive = true);
        insert standardPrice;

        System.debug('==standardPrice==');
        System.debug(standardPrice);

        List<PricebookEntry> lstPricebookEntry = [
                SELECT Id
                    , UnitPrice
                    , Pricebook2Id
                    , Product2Id
                    , IsActive
                    FROM PricebookEntry 
                    WHERE Pricebook2Id =: pricebookId
                    ORDER BY CreatedDate DESC];
        
        System.debug('==lstPricebookEntry==');
        System.debug(lstPricebookEntry);
        System.debug(lstPricebookEntry[0].Pricebook2Id);
        System.debug(lstPricebookEntry[0].Product2Id);
        System.debug(lstPricebookEntry[0].IsActive);
        

        Test.getStandardPricebookId();

        String jsonData = '[{"variable":null,"valuereplaced":null,"value":null,"type":"Screen","requiredDisplayTooltip":null,"parentid":"a055i00000S22SSAAZ","order":0,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":null,"key":"FC-0821","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmufvAAB","defaultValue":null,"confirmationContent":null,"columnSize":null,"childs":[{"variable":null,"valuereplaced":null,"value":null,"type":"Layout","requiredDisplayTooltip":null,"parentid":"a045i00000HmufvAAB","order":0,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":"Layout","key":"FC-0824","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmufyAAB","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[{"variable":null,"valuereplaced":null,"value":null,"type":"Column","requiredDisplayTooltip":null,"parentid":"a045i00000HmufyAAB","order":0,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":null,"key":"FC-0825","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmufzAAB","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":6,"childs":[{"variable":null,"valuereplaced":null,"value":"VAN","type":"Text","requiredDisplayTooltip":"tooltip-hide","parentid":"a045i00000HmufzAAB","order":0,"optionsValue":null,"options":null,"name":null,"mapping":"FirstName","listOptions":null,"label":"First Name","key":"FC-0835","isYesNoOption":false,"isSpacer":null,"isRequired":true,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":true,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000Hmug9AAB","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":true,"columnSize":null,"childs":[],"address":null},{"variable":null,"valuereplaced":null,"value":"LE","type":"Text","requiredDisplayTooltip":"tooltip-hide","parentid":"a045i00000HmufzAAB","order":1,"optionsValue":null,"options":null,"name":null,"mapping":"LastName","listOptions":null,"label":"Last Name","key":"FC-0836","isYesNoOption":false,"isSpacer":null,"isRequired":true,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":true,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmugAAAR","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[],"address":null},{"variable":null,"valuereplaced":null,"value":"lehongthang.hue@gmail.com","type":"Text","requiredDisplayTooltip":"tooltip-hide","parentid":"a045i00000HmufzAAB","order":2,"optionsValue":null,"options":null,"name":null,"mapping":"Email","listOptions":null,"label":"Email","key":"FC-0837","isYesNoOption":false,"isSpacer":null,"isRequired":true,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":true,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmugBAAR","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[],"address":null}],"address":null},{"variable":null,"valuereplaced":null,"value":null,"type":"Column","requiredDisplayTooltip":null,"parentid":"a045i00000HmufyAAB","order":1,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":null,"key":"FC-0826","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000Hmug0AAB","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":6,"childs":[{"variable":null,"valuereplaced":null,"value":"2023-07-03","type":"inputDate","requiredDisplayTooltip":"tooltip-hide","parentid":"a045i00000Hmug0AAB","order":0,"optionsValue":null,"options":null,"name":null,"mapping":"Birthdate","listOptions":null,"label":"Birthdate","key":"FC-0838","isYesNoOption":false,"isSpacer":null,"isRequired":true,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":true,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmugCAAR","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[],"address":null},{"variable":null,"valuereplaced":null,"value":"0975049091","type":"Text","requiredDisplayTooltip":"tooltip-hide","parentid":"a045i00000Hmug0AAB","order":1,"optionsValue":null,"options":null,"name":null,"mapping":"HomePhone","listOptions":null,"label":"Home/Phone Number","key":"FC-0840","isYesNoOption":false,"isSpacer":null,"isRequired":true,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":true,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmugEAAR","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[],"address":null}],"address":null}],"address":null},{"variable":null,"valuereplaced":null,"value":null,"type":"Layout","requiredDisplayTooltip":null,"parentid":"a045i00000HmufvAAB","order":1,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":"Layout","key":"FC-0830","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000Hmug4AAB","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[{"variable":null,"valuereplaced":null,"value":null,"type":"Column","requiredDisplayTooltip":null,"parentid":"a045i00000Hmug4AAB","order":0,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":null,"key":"FC-0831","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000Hmug5AAB","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":12,"childs":[{"variable":null,"valuereplaced":null,"value":null,"type":"Text","requiredDisplayTooltip":"tooltip-hide","parentid":"a045i00000Hmug5AAB","order":0,"optionsValue":null,"options":null,"name":null,"mapping":"ccpformbuilder__Medical_Condition__c","listOptions":null,"label":"Medical Condition","key":"FC-0842","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":true,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmugGAAR","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[],"address":null},{"variable":null,"valuereplaced":null,"value":null,"type":"spacer","requiredDisplayTooltip":"tooltip-hide","parentid":"a045i00000Hmug5AAB","order":1,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":null,"key":"FC-0843","isYesNoOption":false,"isSpacer":true,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmugHAAR","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[],"address":null},{"variable":null,"valuereplaced":null,"value":null,"type":"Product_List","requiredDisplayTooltip":"tooltip-hide","parentid":"a045i00000Hmug5AAB","order":2,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":"Products","key":"FC-0844","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":true,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmugIAAR","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[],"address":null}],"address":null}],"address":null},{"variable":null,"valuereplaced":null,"value":null,"type":"Layout","requiredDisplayTooltip":null,"parentid":"a045i00000HmufvAAB","order":2,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":"Layout","key":"FC-0832","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000Hmug6AAB","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[{"variable":null,"valuereplaced":null,"value":null,"type":"Column","requiredDisplayTooltip":null,"parentid":"a045i00000Hmug6AAB","order":0,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":null,"key":"FC-0833","isYesNoOption":false,"isSpacer":null,"isRequired":false,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":null,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000Hmug7AAB","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":12,"childs":[{"variable":null,"valuereplaced":null,"value":null,"type":"Payment_Form","requiredDisplayTooltip":"tooltip-text tooltip-show","parentid":"a045i00000Hmug7AAB","order":0,"optionsValue":null,"options":null,"name":null,"mapping":null,"listOptions":null,"label":"Payment Form","key":"FC-0845","isYesNoOption":false,"isSpacer":null,"isRequired":true,"isReceiptEmailField":false,"isRadioGroup":null,"isProductList":null,"isPicklist":null,"isPaymentForm":true,"isInputDate":null,"isImage":null,"isHidden":false,"isField":null,"isDisplayText":null,"isConfirmationCheckbox":null,"isCheckbox":null,"isAddress":null,"imageUrl":null,"imageAltText":null,"id":"a045i00000HmugJAAR","defaultValue":null,"confirmationContent":null,"isAddFieldToQuery":null,"columnSize":null,"childs":[],"address":null}],"address":null}],"address":null}],"address":null,"isFinalScreen":false,"isOnlyOne":true,"isShow":true,"isStartScreen":false,"isMiddleScreen":false}]';
        String cardToken = 'test11223344';
        String listProductStr = '[{"Id":"' + fp.Id + '","Name":"Demo Product","Product__c":"' + prod.Id + '","Form__c":"' + testForm.Id + '","value__c":1,"unit_price__c":50}]';

        Test.setMock(HttpCalloutMock.class, new IntegraPayServiceMock());
        
        Test.startTest();
        FormInitCtrl.processPayment(
            jsonData, 
            'Contact',
            'Object_Reference_N__c',
            cardToken,
            listProductStr, 
            pricebookId, 
            false,
            null
        );//sdfsf
        FormInitCtrl.submitForm(jsonData, 'Contact');
        Test.stopTest();
    }

}