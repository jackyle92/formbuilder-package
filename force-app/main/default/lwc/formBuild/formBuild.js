import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import defaultBrandColor from "@salesforce/label/c.DefaultBrandColor";
import paymentLogos from "@salesforce/resourceUrl/PaymentLogos";
import initData from "@salesforce/apex/FormBuilderCtrl.initData";
import saveForm from "@salesforce/apex/FormBuilderCtrl.saveForm";
import getProduct from "@salesforce/apex/FormBuilderCtrl.getProduct";
import getNameSpacePrefix from "@salesforce/apex/FormBuilderHelper.getNameSpacePrefix";
import getPicklistValue from "@salesforce/apex/FormBuilderCtrl.getPicklistValue";
import getActiveLicense from "@salesforce/apex/ProductLicenseManagement.getActiveLicense";
import LightningAlert from 'lightning/alert';
import SystemModstamp from "@salesforce/schema/Account.SystemModstamp";

export default class FormBuild extends LightningElement {
  @api recordId;
  objectReference; // contact/ lead/form submission object
  objectValue;
  showSpinner = false;
  brandColor;
  priceBookId;
  productLookupId;
  maxQuantityPrd = 0;
  productLookupName;

  @track listProduct = [];
  @track selectedComponent = {};
  @track listScreen = [];
  @track fomularCanUse = [];
  @track isShowModal = false;

  // isMaxQEqualto1 = false;
  pricebookOptions = [];
  listProductDel = [];
  listRemoveIds = [];
  activeSections = ["A", "B"];
  activeSettingSections = [];
  fieldsMappingOptions = [];

  isUseThankYouPage = false;
  thankYouPageContent;
  helpTextMapping = "ex: {!Contact.Name}";
  styleCursor = "";
  url_Visa = paymentLogos + "/Visa_Inc.-Logo.png";
  url_Master = paymentLogos + "/Mastercard-Logo.png";
  url_AmericanExpress = paymentLogos + "/American_Express-Logo.png";
  url_JCB = paymentLogos + "/jcb_Logo.png";
  isVisa = true;
  isMaster = true;
  isAMEX = true;
  isJCB = true;

  // Lookup field
  objectSearch;
  fieldSearch;

  //license information
  licenseStatusCode;
  licenseMessage;
  licenseInfo = {};

  // preview 
  isShowFormPreview = false;
  // collect Url string
  formUrl = '';
  formId = '';


  duplicateSelected;
  isShowDuplicateFields;
  namespacePrefix = "";

  objectAPIName = '';
  fieldName = '';

  get objOptions() {
    return [
      { label: "Contact", value: "Contact" },
      { label: "Lead", value: "Lead" },
      { label: "Form Submission", value: "Form_Submission__c" }
    ];
  }

  currencyCode = "AUD";
  get currencyCodeOption() {
    return [
      { label: "AUD", value: "AUD" },
      { label: "USD", value: "USD" },
      { label: "EUR", value: "EUR" }
    ];
  }

  connectedCallback() {
    // get form Url
    this.formUrl = window.location.href;
    let lstPiecesOfUrl = window.location.href.split('/');
    this.formId = lstPiecesOfUrl[lstPiecesOfUrl.length - 2];
    console.log('formId: ', this.formId);

    // get namespacePrefix
    getNameSpacePrefix().then((result) => {
      if(result) {
        this.namespacePrefix = result + '__';
      } else {
        this.namespacePrefix = '';
      }
      this.objectAPIName = this.namespacePrefix + "Form__c";
      this.fieldName = this.namespacePrefix + "Product_Search_Only__c";
    });



    getActiveLicense().then((result) => {
      const returnData = JSON.parse(result);
      this.licenseStatusCode = returnData.statusCode;
      this.licenseMessage = returnData.message;
      if(returnData.statusCode == 200) {
      } else {
        LightningAlert.open({
          message: returnData.message,
          theme: "error",
          label: "License has been expired or no license apply for this product."
        });
        throw new Error(
            "No Active License. The FormBuilder's license has expired. Please contact support@crosscloudpartners.com to purchase and renew the license."
          );
        }
    });

    initData({
      formid: this.recordId
    }).then((result) => {
      if (result.jsondata != "null") {
        this.listScreen = JSON.parse(result.jsondata);
        // console.log(
        //   "Connected Callback List Screen: ",
        //   JSON.parse(result.jsondata)
        // );
      } else {
        var screenTemp = this.createScreen("Screen");
        this.listScreen.push(screenTemp);
      }

      var css = document.body.style;
      if (result.brandColor && result.brandColor != "null") {
        this.brandColor = result.brandColor;
      } else {
        this.brandColor = defaultBrandColor;
      }
      css.setProperty("--brandColor", this.brandColor);

      if (result.priceBookId) {
        this.priceBookId = result.priceBookId;
      }
      console.log('pricebookId: ', this.priceBookId);

      if (result.objectReference) {
        this.objectReference = result.objectReference;
        this.objectValue = result.objectReference;
      }

      this.pricebookOptions = [];
      result.listPriceBook.forEach((item) => {
        var pbObject = {};
        pbObject.label = item.Name;
        pbObject.value = item.Id;
        this.pricebookOptions.push(pbObject);
      });

      console.log('result: ', result);
      this.listProduct = JSON.parse(result.productList);
      console.log('List Product First Query: ', JSON.stringify(this.listProduct));
      this.currencyCode = result.currencyCode;
      // this.isMaxQEqualto1 = result.isMaxQuanlityEqto1;

      if (result.thankYouPageContent && result.thankYouPageContent != "null") {
        this.thankYouPageContent = result.thankYouPageContent;
      }

      if (result.isUseThankYouPage && result.isUseThankYouPage != "null") {
        this.isUseThankYouPage = result.isUseThankYouPage;
      }

      if (result.lstFieldsMapping) {
        console.log(result.lstFieldsMapping);
        this.fieldsMappingOptions = result.lstFieldsMapping;
      }

      this.resetUpScreen();
      this.listScreen[0].isShow = true;
    });
  }

  renderedCallback() {
    if (this.objectValue) {
      this.template.querySelector('[data-name="objectName"]').disabled = true;
    }
  }
 

  handleCoreObjectChange(event) {
    this.objectReference = event.detail.value;
    this.template.querySelector('[data-name="objectName"]').disabled = true;
  }

  showLicenseInfoBox() {  
        this.isShowModal = true;
    }

  hideLicenseInfoBox() {  
      this.isShowModal = false;
  }


  handlePreviewForms() {
    this.isShowFormPreview = true;
  }

  hideFormPreview() {
    this.isShowFormPreview = false;
  }

  handleChangeCurrencyCode(event) {
    this.currencyCode = event.target.value;
  }

  changePriceBook(event) {
    this.priceBookId = event.target.value;
  }

  handleProductLookup(event) {
    this.productLookupId = event.target.value;
  }

  // handleMaxQuantity(event) {
  //   this.isMaxQEqualto1 = event.target.checked;
  //   // console.log(this.isMaxQEqualto1);
  // }

  handleSetUpLimitProductQuantity(event) {
    this.maxQuantityPrd = event.target.value;
  }

  addProduct(event) {
    console.log(' pricebookId 22: ', this.priceBookId);
    var indexExisted = this.listProduct.findIndex(
      (x) => x.Product__c === this.productLookupId
    );
    if (indexExisted == -1) {
      getProduct({ 
        productId: this.productLookupId, 
          priceBookId: this.priceBookId }).then((result) => {
        var productObj = JSON.parse(result);
        var fpObject = {};
        fpObject.formId = this.recordId;
        fpObject.productId = productObj.id;
        fpObject.name = productObj.name;
        fpObject.maxQuantityOfProduct = this.maxQuantityPrd;
        fpObject.unitPrice = productObj.unitPrice;
        this.listProduct.push(fpObject);
        console.log("List Product Of Form: ", JSON.stringify(this.listProduct));
      }).catch ( err => {
          console.log(err)
        }
      );
    }
  }

  removeProduct(event) {
    var removeIndex = event.target.dataset.index;
    if (this.listProduct[removeIndex].id) {
      this.listProductDel.push(this.listProduct[removeIndex].id);
    }
    this.listProduct.splice(removeIndex, 1);
  }

  

  changeDisplayText(event) {
    console.log("==changeDisplayText==");
    var cmpbuildEvent = event.target.closest('[data-name="cmpbuild"]');

    this.listScreen[cmpbuildEvent.dataset.indexscreen].childs[
      cmpbuildEvent.dataset.indexlayout
    ].childs[cmpbuildEvent.dataset.indexcol].childs[
      cmpbuildEvent.dataset.index
    ].value = event.target.value;
  }

  updateThankYouPage(event) {
    this.thankYouPageContent = event.target.value;
    console.log("==this.thankYouPageContent==");
    console.log(this.thankYouPageContent);
  }

  gotoAllSite(event) {
    console.log("==all site==");
    var currentLocation = window.location.origin;
    window
      .open(currentLocation + "/lightning/setup/SetupNetworks/home", "_blank")
      .focus();
  }

  checkboxThanksPage(event) {
    console.log("==event.target.checked==");
    console.log(event.target.checked);
    this.isUseThankYouPage = event.target.checked;
  }

  // checkboxShowDisclaimer(event){
  //     console.log('==event.target.checked==');
  //     console.log(event.target.checked);
  //     this.isShowDisclaimer = event.target.checked;
  // }

  changeBrandColor(event) {
    this.brandColor = event.target.value;
    var css = document.body.style;
    css.setProperty("--brandColor", this.brandColor);
  }

  addNewScreen(event) {
    var screenTemp = this.createScreen("Screen");
    this.listScreen.push(screenTemp);
    this.resetUpScreen();
  }

  resetUpScreen() {
    for (let i = 0; i < this.listScreen.length; i++) {
      this.listScreen[i].isFinalScreen = false;
      this.listScreen[i].isOnlyOne = false;
      this.listScreen[i].isShow = false;
      this.listScreen[i].isMiddleScreen = true;
    }
    this.listScreen[0].isMiddleScreen = false;

    if (this.listScreen.length == 1) {
      this.listScreen[0].isOnlyOne = true;
    } else {
      this.listScreen[0].isOnlyOne = false;
      this.listScreen[this.listScreen.length - 1].isFinalScreen = true;
    }
  }

  showSuccessToast(mess) {
    const event = new ShowToastEvent({
      variant: "success",
      title: "Success",
      message: mess
    });
    this.dispatchEvent(event);
  }

  saveFormBuilder(event) {
    this.showSpinner = true;

    var jsonInput = JSON.stringify(this.listScreen);

    var formSetting = {};
    formSetting.id = this.recordId;
    formSetting.brandColor = this.brandColor;
    formSetting.thankYouPageContent = this.thankYouPageContent;
    formSetting.isUseThankYouPage = this.isUseThankYouPage;
    //formSetting.isShowDisclaimer = this.isShowDisclaimer;
    formSetting.duplicateSelected = this.duplicateSelected;
    formSetting.priceBookId = this.priceBookId;
    formSetting.objectReference = this.objectReference; // add core object for the form
    // formSetting.isMaxQEqualto1 = this.isMaxQEqualto1; // set max quantity for each product equal to 1

    // for (let pindex = 0; pindex < this.listProduct.length; pindex++) {
    //   this.listProduct[pindex].ccpformbuilder__Form__c =
    //     this.listProduct[pindex].Form__c;
    //   this.listProduct[pindex].ccpformbuilder__Product__c =
    //     this.listProduct[pindex].Product__c;
    //   this.listProduct[pindex].ccpformbuilder__unit_price__c =
    //     this.listProduct[pindex].unit_price__c;
    //   this.listProduct[pindex].ccpformbuilder__value__c =
    //     this.listProduct[pindex].value__c;
    // }

    formSetting.productList = this.listProduct;

    formSetting.productListDel = this.listProductDel;
    formSetting.currencyCode = this.currencyCode;

    console.log('Form Setting: ' , JSON.stringify(formSetting));

    if(this.licenseStatusCode != 200) {
      LightningAlert.open({
          message: this.licenseMessage,
          theme: 'error',
          label: 'Error!!!', 
        });
        this.showSpinner = false;
      return null;
    }

    console.log('1');
    saveForm({
      jsonData: jsonInput,
      formSetting: JSON.stringify(formSetting),
      lstRemoveId: this.listRemoveIds
    })
      .then((result) => {
        this.showSuccessToast("Form is saved!");

        initData({
          formid: this.recordId
        }).then((result) => {
          if (result.jsondata != "null") {
            this.listScreen = [];
            this.listScreen = JSON.parse(result.jsondata);
          }

          this.listProduct = JSON.parse(result.productList);
          this.listProductDel = [];

          this.resetUpScreen();
          this.listScreen[0].isShow = true;
          this.showSpinner = false;
        });
      })
      .catch((error) => {
        this.showErrorToast(error.body.message);
        this.showSpinner = false;
      });
  }

  showErrorToast(message) {
    const evt = new ShowToastEvent({
      title: "Error",
      message: message,
      variant: "error",
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
  }

  removeComponent(event) {
    let cmpId;
    let tempId;

    if (this.selectedComponent.cmptype == "screen") {
      if (this.listScreen.length > 1) {
        cmpId = this.listScreen[this.selectedComponent.indexScreen].id;
        for (
          let ilayout = 0;
          ilayout <
          this.listScreen[this.selectedComponent.indexScreen].childs.length;
          ilayout++
        ) {
          tempId =
            this.listScreen[this.selectedComponent.indexScreen].childs[ilayout]
              .id;
          if (tempId) {
            this.listRemoveIds.push(tempId);
          }
          for (
            let icolumn = 0;
            icolumn <
            this.listScreen[this.selectedComponent.indexScreen].childs[ilayout]
              .childs.length;
            icolumn++
          ) {
            tempId =
              this.listScreen[this.selectedComponent.indexScreen].childs[
                ilayout
              ].childs[icolumn].id;
            if (tempId) {
              this.listRemoveIds.push(tempId);
            }
            for (
              let ifield = 0;
              ifield <
              this.listScreen[this.selectedComponent.indexScreen].childs[
                ilayout
              ].childs[icolumn].childs.length;
              ifield++
            ) {
              tempId =
                this.listScreen[this.selectedComponent.indexScreen].childs[
                  ilayout
                ].childs[icolumn].childs[ifield].id;
              if (tempId) {
                this.listRemoveIds.push(tempId);
              }
            }
          }
        }
        this.listScreen.splice(this.selectedComponent.indexScreen, 1);
        this.resetUpScreen();
      }
    } else if (this.selectedComponent.cmptype == "layout") {
      cmpId =
        this.listScreen[this.selectedComponent.indexScreen].childs[
          this.selectedComponent.indexLayout
        ].id;

      for (
        let icolumn = 0;
        icolumn <
        this.listScreen[this.selectedComponent.indexScreen].childs[
          this.selectedComponent.indexLayout
        ].childs;
        icolumn++
      ) {
        tempId =
          this.listScreen[this.selectedComponent.indexScreen].childs[
            this.selectedComponent.indexLayout
          ].childs[icolumn].id;
        if (tempId) {
          this.listRemoveIds.push(tempId);
        }
        for (
          let ifield = 0;
          ifield <
          this.listScreen[this.selectedComponent.indexScreen].childs[ilayout]
            .childs[icolumn].childs;
          ifield++
        ) {
          tempId =
            this.listScreen[this.selectedComponent.indexScreen].childs[ilayout]
              .childs[icolumn].childs[ifield].id;
          if (tempId) {
            this.listRemoveIds.push(tempId);
          }
        }
      }

      this.listScreen[this.selectedComponent.indexScreen].childs.splice(
        this.selectedComponent.indexLayout,
        1
      );
    } else {
      cmpId =
        this.listScreen[this.selectedComponent.indexScreen].childs[
          this.selectedComponent.indexLayout
        ].childs[this.selectedComponent.indexColumn].childs[
          this.selectedComponent.indexCmp
        ].id;

      this.listScreen[this.selectedComponent.indexScreen].childs[
        this.selectedComponent.indexLayout
      ].childs[this.selectedComponent.indexColumn].childs.splice(
        this.selectedComponent.indexCmp,
        1
      );
    }

    if (cmpId) {
      this.listRemoveIds.push(cmpId);
    }
  }

  changeCheckBoxCmp(event) {
    this.listScreen[this.selectedComponent.indexScreen].childs[
      this.selectedComponent.indexLayout
    ].childs[this.selectedComponent.indexColumn].childs[
      this.selectedComponent.indexCmp
    ].isRequired = this.template.querySelector(
      '[data-name="isrequiredcmp"]'
    ).checked;
    this.listScreen[this.selectedComponent.indexScreen].childs[
      this.selectedComponent.indexLayout
    ].childs[this.selectedComponent.indexColumn].childs[
      this.selectedComponent.indexCmp
    ].isReceiptEmailField = this.template.querySelector(
      '[data-name="isreceiptemailcmp"]'
    ).checked;
    this.listScreen[this.selectedComponent.indexScreen].childs[
      this.selectedComponent.indexLayout
    ].childs[this.selectedComponent.indexColumn].childs[
      this.selectedComponent.indexCmp
    ].isHidden = this.template.querySelector(
      '[data-name="ishiddenfieldcmp"]'
    ).checked;

    this.listScreen[this.selectedComponent.indexScreen].childs[
      this.selectedComponent.indexLayout
    ].childs[this.selectedComponent.indexColumn].childs[
      this.selectedComponent.indexCmp
    ].isYesNoOption = this.template.querySelector(
      '[data-name="isyesnooption"]'
    ).checked;

    this.listScreen[this.selectedComponent.indexScreen].childs[
      this.selectedComponent.indexLayout
    ].childs[this.selectedComponent.indexColumn].childs[
      this.selectedComponent.indexCmp
    ].isAddFieldToQuery = this.template.querySelector(
      '[data-name="doesitaddtoquery"]'
    ).checked;
  }

  // changeDefaultCheckBoxCmp(event) {
  //   if (event.target.checked) {
  //     this.isDefaultField = true;
  //     this.listScreen[this.selectedComponent.indexScreen].childs[
  //       this.selectedComponent.indexLayout
  //     ].childs[this.selectedComponent.indexColumn].childs[
  //       this.selectedComponent.indexCmp
  //     ].isDefault = this.template.querySelector(
  //       '[data-name="isdefaultfieldcmp"]'
  //     ).checked;
  //   } else {
  //     this.listScreen[this.selectedComponent.indexScreen].childs[
  //       this.selectedComponent.indexLayout
  //     ].childs[this.selectedComponent.indexColumn].childs[
  //       this.selectedComponent.indexCmp
  //     ].isDefault = false;
  //     this.isDefaultField = false;
  //   }
  // }

  changeValueOnCmp(event) {
    console.log("==changeCmp222==");

    if (this.selectedComponent.cmptype == "screen") {
      this.listScreen[this.selectedComponent.indexScreen].label =
        this.template.querySelector('[data-name="labelUpdate"]').value;
    } else if (this.selectedComponent.cmptype == "layout") {
      this.listScreen[this.selectedComponent.indexScreen].childs[
        this.selectedComponent.indexLayout
      ].label = this.template.querySelector('[data-name="labelUpdate"]').value;
    } else if (this.selectedComponent.cmptype) {
      //Update label
      this.listScreen[this.selectedComponent.indexScreen].childs[
        this.selectedComponent.indexLayout
      ].childs[this.selectedComponent.indexColumn].childs[
        this.selectedComponent.indexCmp
      ].label = this.template.querySelector('[data-name="labelUpdate"]').value;

      //Update field mapping

      this.listScreen[this.selectedComponent.indexScreen].childs[
        this.selectedComponent.indexLayout
      ].childs[this.selectedComponent.indexColumn].childs[
        this.selectedComponent.indexCmp
      ].mapping = this.template.querySelector(
        '[data-name="fieldMapping"]'
      ).value;

      //check if current field is picklist field

      if (
        this.listScreen[this.selectedComponent.indexScreen].childs[
          this.selectedComponent.indexLayout
        ].childs[this.selectedComponent.indexColumn].childs[
          this.selectedComponent.indexCmp
        ].isPicklist ||
        this.listScreen[this.selectedComponent.indexScreen].childs[
          this.selectedComponent.indexLayout
        ].childs[this.selectedComponent.indexColumn].childs[
          this.selectedComponent.indexCmp
        ].isCheckbox
      ) {
        getPicklistValue({
          objectName: this.objectReference,
          fieldName:
            this.listScreen[this.selectedComponent.indexScreen].childs[
              this.selectedComponent.indexLayout
            ].childs[this.selectedComponent.indexColumn].childs[
              this.selectedComponent.indexCmp
            ].mapping
        }).then((result) => {
          this.error = undefined;
          if (result) {
            this.listScreen[this.selectedComponent.indexScreen].childs[
              this.selectedComponent.indexLayout
            ].childs[this.selectedComponent.indexColumn].childs[
              this.selectedComponent.indexCmp
            ].options = JSON.stringify(result);
          } else {
            return null;
          }
        });
      }

      console.log("Screens", this.listScreen);
    }
    //this.selectedComponent.cmptype = '';
  }

  changeDefaultValueOnCmp(event) {
    console.log(
      "query default element: " +
        this.template.querySelector('[data-name="defaultValue"]')
    );
    this.listScreen[this.selectedComponent.indexScreen].childs[
      this.selectedComponent.indexLayout
    ].childs[this.selectedComponent.indexColumn].childs[
      this.selectedComponent.indexCmp
    ].defaultValue = this.template.querySelector(
      '[data-name="defaultValue"]'
    ).value;
  }

  handleInputDateChange(event) {
    console.log("Do not things");
  }

  handleSectionToggle(event) {
    if (event.detail.openSections.indexOf("Fomulas") == -1) {
      return;
    }

    this.fomularCanUse = [];

    var sumfl = {};

    for (
      let screenindex = 0;
      screenindex < this.listScreen.length;
      screenindex++
    ) {
      for (
        let layoutindex = 0;
        layoutindex < this.listScreen[screenindex].childs.length;
        layoutindex++
      ) {
        for (
          let componentindex = 0;
          componentindex <
          this.listScreen[screenindex].childs[layoutindex].childs.length;
          componentindex++
        ) {
          for (
            let index = 0;
            index <
            this.listScreen[screenindex].childs[layoutindex].childs[
              componentindex
            ].childs.length;
            index++
          ) {
            var childComponent =
              this.listScreen[screenindex].childs[layoutindex].childs[
                componentindex
              ].childs[index];
            if (
              childComponent.isField == true ||
              childComponent.isPicklist == true
            ) {
              var fieldInfo = {};
              fieldInfo.mapping = childComponent.mapping;
              fieldInfo.description = childComponent.label;
              this.fomularCanUse.push(fieldInfo);
            }
          }
        }
      }
    }

    sumfl.mapping = "{!SumAmount}";
    sumfl.description = "Total amount";
    this.fomularCanUse.push(sumfl);
  }

  clearSelectedCmp() {
    console.log("==clearSelectedCmp==");
    this.template
      .querySelectorAll('[data-detail="detailcmp"]')
      .forEach((item) => {
        item.value = "";
        item.checked = false;
        item.disabled = true;
      });
    this.selectedComponent = {};
  }

  selectCmp(event) {
    console.log("==selectCmp==" + event.currentTarget.dataset.cmptype);

    this.template.querySelectorAll(".selected-cmp").forEach((cmpObj) => {
      if (cmpObj != event.target.closest('[data-name="cmpbuild"]')) {
        cmpObj.classList.remove("selected-cmp");
      }
    });

    event.target
      .closest('[data-name="cmpbuild"]')
      .classList.toggle("selected-cmp");

    if (
      event.target
        .closest('[data-name="cmpbuild"]')
        .classList.contains("selected-cmp")
    ) {
      this.template
        .querySelectorAll('[data-detail="detailcmp"]')
        .forEach((item) => {
          item.disabled = false;
        });

      this.selectedComponent.cmptype = event.currentTarget.dataset.cmptype;
      //console.log(event.currentTarget.dataset.cmptype);

      if (event.currentTarget.dataset.cmptype == "screen") {
        this.selectedComponent.indexScreen = parseInt(
          event.currentTarget.dataset.indexscreen
        );
        this.template.querySelector('[data-name="labelUpdate"]').value =
          this.listScreen[this.selectedComponent.indexScreen].label;
      } else if (event.currentTarget.dataset.cmptype == "layout") {
        this.selectedComponent.indexScreen = parseInt(
          event.currentTarget.dataset.indexscreen
        );
        this.selectedComponent.indexLayout = parseInt(
          event.currentTarget.dataset.indexlayout
        );
        this.template.querySelector('[data-name="labelUpdate"]').value =
          this.listScreen[this.selectedComponent.indexScreen].childs[
            this.selectedComponent.indexLayout
          ].label;
      } else if (event.currentTarget.dataset.cmptype) {
        if (event.currentTarget.dataset.indexscreen) {
          this.selectedComponent.indexScreen = parseInt(
            event.currentTarget.dataset.indexscreen
          );
        }

        if (event.currentTarget.dataset.indexlayout) {
          this.selectedComponent.indexLayout = parseInt(
            event.currentTarget.dataset.indexlayout
          );
        }

        if (event.currentTarget.dataset.indexcol) {
          this.selectedComponent.indexColumn = parseInt(
            event.currentTarget.dataset.indexcol
          );
        }

        if (event.currentTarget.dataset.index) {
          this.selectedComponent.indexCmp = parseInt(
            event.currentTarget.dataset.index
          );
        }

        let selectedObject =
          this.listScreen[this.selectedComponent.indexScreen].childs[
            this.selectedComponent.indexLayout
          ].childs[this.selectedComponent.indexColumn].childs[
            this.selectedComponent.indexCmp
          ];

        // if(selectedObject.type == 'Pick_List'){
        //   console.log(this.template.querySelector('[name="picklistData"]'));
        //   this.template.querySelector('[name="picklistData"]').options = JSON.parse(selectedObject.options);
        // } else if (selectedObject.type == 'checkbox') {
        //   console.log(456);
        //   this.template.querySelector('[name="checkboxData"]').options = JSON.parse(selectedObject.options);
        // }
        this.template.querySelector('[data-name="labelUpdate"]').value =
          selectedObject.label;
        this.template.querySelector('[data-name="fieldMapping"]').value =
          selectedObject.mapping;
        this.template.querySelector('[data-name="isrequiredcmp"]').checked =
          selectedObject.isRequired;
        //this.template.querySelector('[data-name="duplicatecmp"]').checked = selectedObject.isCheckDuplicate;
        this.template.querySelector('[data-name="isreceiptemailcmp"]').checked =
          selectedObject.isReceiptEmailField;
        this.template.querySelector('[data-name="ishiddenfieldcmp"]').checked =
          selectedObject.isHidden;
        this.template.querySelector('[data-name="defaultValue"]').value =
          selectedObject.defaultValue;
        this.template.querySelector('[data-name="doesitaddtoquery"]').checked =
        selectedObject.isAddFieldToQuery;
        console.log('selected object: ' + selectedObject);
      }
    } else {
      this.clearSelectedCmp();
      return;
    }
  }

  DragStart(event) {
    event.dataTransfer.setData("index", event.currentTarget.dataset.index);
    event.dataTransfer.setData("name", event.currentTarget.dataset.name);
    event.target.classList.add("drag");

    console.log(
      "index: ",
      event.dataTransfer.setData("index", event.currentTarget.dataset.index)
    );
    console.log(
      "name: ",
      event.dataTransfer.setData("name", event.currentTarget.dataset.name)
    );
    console.log("drag: ", event.target.classList.add("drag"));
  }

  DragOver(event) {
    event.preventDefault();
    return false;
  }

  DragEnter(event) {
    event.preventDefault();
    event.target.classList.add("drag-enter");
  }

  DragLeave(event) {
    event.preventDefault();
    event.target.classList.remove("drag-enter");
  }

  DragEnd(event) {
    event.target.classList.remove("drag");
  }

  Drop(event) {
    event.stopPropagation();

    var indexScreen = 0;
    var indexLayout = 0;
    var indexColumn = 0;

    var dragName = event.dataTransfer.getData("name");
    console.log("dragName: ", dragName);

    var dropIndexScreen = parseInt(event.currentTarget.dataset.indexscreen);
    if (dropIndexScreen) {
      indexScreen = dropIndexScreen;
    }
    console.log("==indexScreen==", indexScreen);

    var dropIndexLayout = parseInt(event.currentTarget.dataset.indexlayout);

    if (dropIndexLayout) {
      indexLayout = dropIndexLayout;
    }
    console.log("==indexLayout==", indexLayout);

    var dropIndexColumn = parseInt(event.currentTarget.dataset.indexcol);

    if (dropIndexColumn) {
      indexColumn = dropIndexColumn;
    }
    console.log("==indexColumn==", indexColumn);

    if (dragName === "textField") {
      var dropIndex = event.currentTarget.dataset.index;
      console.log("dropIndex", dropIndex);
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      console.log("dropIndex after If: ", dropIndex);
      var dropField = this.createField();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropField);
    } else if (dragName === "pickList") {
      // Drop PickList field
      var dropIndex = event.currentTarget.dataset.index;
      console.log("dropIndex PickList", dropIndex);
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      console.log("dropIndex PL after If: ", dropIndex);
      var dropField = this.createPickListField();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropField);
      console.log("drop pick list field: ", dropField);
    } else if (dragName === "checkbox") {
      var dropIndex = event.currentTarget.dataset.index;
      console.log("dropIndex checkbox: ", dropIndex);
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      console.log("dropIndex checkbox after If: ", dropIndex);
      var dropField = this.createCheckboxField();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropField);
      console.log("drop checkbox field: ", dropField);
    } else if (dragName === "paymentForm") {
      var dropIndex = event.currentTarget.dataset.index;
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      var dropForm = this.createPaymentForm();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropForm);
    } else if( dragName === 'promotionCmp') {
      var dropIndex = event.currentTarget.dataset.index;
      console.log('dropIndex: ' + dropIndex);
      if(!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      } 
      console.log('dropIndex: ' + dropIndex);
      var dropPromotionCmp = this.createPromotionCmp();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropPromotionCmp);
      console.log('hahaha: ', this.listScreen[indexScreen].childs[indexLayout].childs);
    } 
    else if (dragName === "productList") {
      var dropIndex = event.currentTarget.dataset.index;
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      var dropProductList = this.createProductList();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropProductList);
    } else if (dragName === "displayText") {
      var dropIndex = event.currentTarget.dataset.index;
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      var dropDisplayText = this.createDisplayText();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropDisplayText);
    } else if (dragName === "layout1Column") {
      var dropIndex = 0;
      if (!dropIndex) {
        dropIndex = this.listScreen[indexScreen].childs.length;
      }
      var dropLayout = this.createLayout(1);
      this.listScreen[indexScreen].childs.splice(dropIndex, 0, dropLayout);
    } else if (dragName === "layout2Column") {
      var dropIndex = 0;
      if (!dropIndex) {
        dropIndex = this.listScreen[indexScreen].childs.length;
      }
      var dropLayout = this.createLayout(2);
      this.listScreen[indexScreen].childs.splice(dropIndex, 0, dropLayout);
    } else if (dragName === "cmpbuild") {
      var dragIndex = event.dataTransfer.getData("index");
      var dropIndex = event.currentTarget.dataset.index;

      if (dragIndex === dropIndex) {
        return false;
      }
      Array.prototype.move = function (from, to) {
        this.splice(to, 0, this.splice(from, 1)[0]);
      };
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.move(dragIndex, dropIndex);
    } else if (dragName === "confirmCheckbox") {
      var dropIndex = event.currentTarget.dataset.index;
      console.log("dropIndex confirm: ", dropIndex);
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      // console.log("dropIndex confirm after If: ", dropIndex);
      var dropField = this.createConfirmField();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropField);
      console.log("drop confirm field: ", dropField);
    } else if (dragName === "radio") {
      var dropIndex = event.currentTarget.dataset.index;
      console.log("dropIndex radio: ", dropIndex);
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      // console.log("dropIndex radio after If: ", dropIndex);
      var dropField = this.createRadioGroup();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropField);
      console.log("drop radioGroup field: ", dropField);
    } else if (dragName === "input-date") {
      var dropIndex = event.currentTarget.dataset.index;
      console.log("dropIndex input-date: ", dropIndex);
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      console.log("dropIndex input-date after If: ", dropIndex);
      var dropField = this.createDateField();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropField);
      console.log("drop input-date field: ", dropField);
    } else if (dragName === "spacer") {
      // spacer
      var dropIndex = event.currentTarget.dataset.index;
      console.log("dropIndex spacer: ", dropIndex);
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      var dropField = this.createSpacer();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropField);
    } else if (dragName === "address") {
      var dropIndex = event.currentTarget.dataset.index;
      console.log("dropIndex address: ", dropIndex);
      if (!dropIndex) {
        dropIndex =
          this.listScreen[indexScreen].childs[indexLayout].childs[indexColumn]
            .childs.length;
      }
      console.log("dropIndex address after If: ", dropIndex);
      var dropField = this.createAddress();
      this.listScreen[indexScreen].childs[indexLayout].childs[
        indexColumn
      ].childs.splice(dropIndex, 0, dropField);
      console.log(dropField);
    }
  }

  changeDuplicateOption(event) {
    console.log("==changeDuplicateOption==");
    this.duplicateSelected = event.target.value;

    console.log(this.duplicateSelected);

    if (this.duplicateSelected == "allow") {
      this.isShowDuplicateFields = false;
    } else {
      this.isShowDuplicateFields = true;
    }
  }

  // Create components
  createScreen(label) {
    var screen = {};
    screen.key = "S-00001";
    screen.label = label;
    screen.type = "screen";
    screen.order = 1;
    screen.childs = [];
    return screen;
  }

  createLayout(numOfColumns) {
    var dropLayout = {};
    dropLayout.key = "A-00005";
    dropLayout.label = "Layout";
    dropLayout.type = "layout";
    dropLayout.order = 1;
    dropLayout.childs = [];

    for (let i = 0; i < numOfColumns; i++) {
      var dropColumn = {};
      dropColumn.type = "column";
      dropColumn.childs = [];
      dropColumn.columnSize = 12 / numOfColumns;
      dropLayout.childs.push(dropColumn);
    }

    return dropLayout;
  }

  createField() {
    var newfield = {};
    newfield.key = "B-00001";
    newfield.label = "Label";
    newfield.type = "Text";
    newfield.isField = true;
    newfield.isRequired = false;
    newfield.isReceiptEmailField = false;
    newfield.isHidden = false;
    newfield.mapping = "";
    newfield.defaultValue = "";
    newfield.variable = "";
    newfield.order = 1;
    newfield.isAddFieldToQuery = false;
    return newfield;
  }

  createPaymentForm() {
    var paymentForm = {};
    paymentForm.key = "D-00001";
    paymentForm.label = "Payment Form";
    paymentForm.type = "Payment_form";
    paymentForm.isPaymentForm = true;
    paymentForm.order = 1;
    return paymentForm;
  }

  createPromotionCmp() {
    var promotionCmp = {};
    promotionCmp.key = 'PRCMP-00001';
    promotionCmp.label = 'Promotion Cmp';
    promotionCmp.type = 'Promotion';
    promotionCmp.isPromotionCmp = true;
    return promotionCmp;
  }

  createProductList() {
    var productlist = {};
    productlist.key = "P-00001";
    productlist.label = "Products";
    productlist.type = "Product_List";
    productlist.isProductList = true;
    productlist.order = 1;
    return productlist;
  }

  createDisplayText() {
    var displayText = {};
    displayText.key = "DT-00001";
    displayText.label = "Display Text";
    displayText.type = "Display_Text";
    displayText.isDisplayText = true;
    displayText.value = "";
    displayText.order = 1;
    return displayText;
  }

  createPickListField() {
    var newPickList = {};
    newPickList.key = "PL-0001";
    newPickList.label = "Label";
    newPickList.type = "Pick_List";
    newPickList.isPicklist = true;
    newPickList.isRequired = false;
    newPickList.mapping = "";
    newPickList.variable = "";
    return newPickList;
  }

  createCheckboxField() {
    var newCheckbox = {};
    newCheckbox.key = "PL-0001";
    newCheckbox.label = "Label";
    newCheckbox.type = "checkbox";
    newCheckbox.isCheckbox = true;
    newCheckbox.isRequired = false;
    newCheckbox.isYesNoOption = false;
    newCheckbox.mapping = "";
    newCheckbox.variable = "";
    return newCheckbox;
  }

  createConfirmField() {
    console.log("createConfirmField");
    let newConfirmField = {};
    newConfirmField.key = "CF-0001";
    newConfirmField.label = "Add Content to field label";
    newConfirmField.isConfirmationCheckbox = true;
    newConfirmField.type = "confirmationsBox";
    newConfirmField.value = false;
    newConfirmField.isRequired = false;
    newConfirmField.mapping = "";
    return newConfirmField;
  }

  createRadioGroup() {
    console.log("createRadioGroupField");
    let newRadioGroup = {};
    newRadioGroup.key = "RG-0001";
    newRadioGroup.label = "Label";
    newRadioGroup.isRadioGroup = true;
    newRadioGroup.type = "radioGroup";
    newRadioGroup.value = false;
    newRadioGroup.isRequired = false;
    newRadioGroup.mapping = "";
    return newRadioGroup;
  }

  createDateField() {
    console.log("create-input-date-field");
    let newInputDate = {};
    newInputDate.key = "ID-0001";
    newInputDate.label = "Label";
    newInputDate.isInputDate = true;
    newInputDate.type = "inputDate";
    newInputDate.value = false;
    newInputDate.isRequired = false;
    newInputDate.mapping = "";
    return newInputDate;
  }

  createSpacer() {
    console.log("create-spacer-field");
    let newSpacer = {};
    newSpacer.key = "SP-0001";
    newSpacer.isSpacer = true;
    newSpacer.type = "spacer";
    return newSpacer;
  }

  createAddress() {
    console.log("Create address field");
    let newAddress = {};
    newAddress.key = "AD-0001";
    newAddress.isAddress = true;
    newAddress.isRequired = false;
    newAddress.type = "address";
    newAddress.label = "Address";
    return newAddress;
  }
}