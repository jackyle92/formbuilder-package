import { LightningElement, api, track } from "lwc";
import paymentLogos from "@salesforce/resourceUrl/PaymentLogos";
import initData from "@salesforce/apex/FormInitCtrl.initData";
import processPayment from "@salesforce/apex/FormInitCtrl.processPayment";
import { loadScript } from "lightning/platformResourceLoader";
import integraPay from "@salesforce/resourceUrl/IntegraPay_JS";
//Jacky
import submitForm from "@salesforce/apex/FormInitCtrl.submitForm";
import LightningAlert from "lightning/alert";
// import TotalAmount from "@salesforce/schema/Order.TotalAmount";
import getActiveLicense from "@salesforce/apex/ProductLicenseManagement.getActiveLicense";
import getNameSpacePrefix from "@salesforce/apex/FormBuilderHelper.getNameSpacePrefix";
import getMapPaymentFee from "@salesforce/apex/FormBuilderHelper.getMapPaymentFee";

export default class FormInit extends LightningElement {
  @api formid;
  @api getFormIdValue;
  @track listScreen = [];
  @track totalAmountEqualtoZero = true;
  @api logoName = "";
  formName = '';
  showSpinner = false;
  isPaymentError = false;
  isSubmitError = false;
  errorPaymentRequired = false;
  errorServiceMessage = false;
  isImportDataFailed = false;
  chargeOnCardHolder = false;

  errorMessage;

  isUseThankYouPage = false;
  showThankYouPage = false;
  thankYouPageContent;

  url_Visa = paymentLogos + "/Visa_Inc.-Logo.png";
  url_Master = paymentLogos + "/Mastercard-Logo.png";
  url_AmericanExpress = paymentLogos + "/American_Express-Logo.png";
  url_JCB = paymentLogos + "/jcb_Logo.png";
  isVisa = true;
  isMaster = true;
  isAMEX = true;
  isJCB = true;
  // isMaxQEqualto1 = false;

  paymentSetting = {};
  companyinfo = {};
  isRequiredPayment = false;
  subAmount  = 0;
  sumAmountStr = "{!SumAmount}";
  sumAmountValue = 0;
  mappingFieldValue = [];
  currencyCode = "AUD";
  isHaveLicense = true;
  namespacePrefix = "";

  requiredTooltipDisplay = {};
  hasLogo = false;

  // address
  address = {};
  // query payment fees
  paymentFeesData = {};
  currentPaymentFee;
  chargeFee;
  totalAmountIncludeFee = 0;

  // picklist -- Can not use it
  value;
  @track options = [];

  //Promotion 
  isShowingPromotion = true;
  promotionCode;
  discountString;

  // UI improvements
  @api backgroundColor;
  @api textColor;

  constructor() {
    super();
  }

  get tooltipStype() {
    return `font-size: 12px; color:#c23934`;
  }

  // get imgLogo() {
  //   if(this.logoName != null) {
  //     this.hasLogo = true;
  //     return images + "/images/" + this.logoName;
  //   } else return null;
  // }

  get backgroundStyle() {
    return `background-color:${this.backgroundColor};
              border: none,
              color: ${this.textColor};`;
  }

  connectedCallback() {
    console.log("form Id Value: ", this.getFormIdValue);

    if (!this.formid) {
      this.formid = this.getFormIdValue;
    }
    // getActiveLicense().then((result) => {
    //   const returnData = JSON.parse(result);
    //   console.log('asdfklakjga');
    //   if(returnData.statusCode == 200) {
    //     if(!returnData.message.includes('Active') && !returnData.message.includes('product package')){
    //       LightningAlert.open({
    //       message: returnData.message,
    //       theme: "warning",
    //       label: "Warning!"
    //     });
    //     }
    //   } else {
    //     LightningAlert.open({
    //       message: returnData.message,
    //       theme: "error",
    //       label: "License has been expired or no license apply for this product."
    //     });
    //     throw new Error(
    //         "No Active License. The FormBuilder's license has expired. Please contact support@crosscloudpartners.com to purchase and renew the license."
    //       );
    //     }
    // });

    // get namespacePrefix
    getNameSpacePrefix().then((result) => {
      if (result) {
        this.namespacePrefix = result + "__";
      } else {
        this.namespacePrefix = "";
      }
      console.log("Namespace prefix", this.namespacePrefix);
    });

    // get the payment fee and update to the paymentFees object
    getMapPaymentFee().then((result) => {
      if (result != null) {
        this.paymentFeesData = JSON.parse(result);
      }
    }).catch(err => {
      console.log('Get payment fee failed:', err);
    })

    Promise.all([loadScript(this, integraPay + "/jQuery3.2.1.js")])
      .then(() => {
        initData({
          formid: this.formid
        }).then((result) => {
          this.isHaveLicense = result.isHaveLicense;
          this.paymentSetting.endpoint = result.endpoint;
          this.paymentSetting.businesskey = result.businesskey;
          this.paymentSetting.linkobject = result.objectReference;
          this.paymentSetting.linkfield = result.fieldRelation;
          this.paymentSetting.priceBookId = result.priceBookId;
          if (!this.backgroundColor) {
            this.backgroundColor = result.brandColor;
          }
          const productList = [];
          JSON.parse(result.productList).forEach(product => {
            if(product.maxQuantityOfProduct > 0){
              productList.push(product);
            } 
          })
          this.paymentSetting.productList = productList;
          console.log("result.productList: ", JSON.stringify(productList));


          if (result.jsondata && result.jsondata != "null") {
            this.listScreen = JSON.parse(result.jsondata);
            this.resetUpScreen();
            this.listScreen[0].isShow = true;
          }

          const screenWidth = window.screen.availWidth;
          //hide all the message required fields
          this.listScreen.forEach((screen) => {
            // console.log(screen.childs.forEach);
            screen.childs.forEach((layout) => {
              layout.childs.forEach((column) => {
                // set size of column to adapt to screen size
                console.log("Width:", window.screen.availWidth);
                console.log("colmn size", column.columnSize);
                if (screenWidth < 430 && column.columnSize < 12) {
                  column.columnSize = 12;
                }
                column.childs.forEach((field) => {
                  field.requiredDisplayTooltip = "tooltip-hide";
                });
              });
            });
          });

          // console.log("jsonData: ", this.listScreen[0].childs[0].childs[0]);

          for (
            let layoutIndex = 0;
            layoutIndex < this.listScreen[0].childs.length;
            layoutIndex++
          ) {
            // console.log('Layout');
            for (
              let columnIndex = 0;
              columnIndex <
              this.listScreen[0].childs[layoutIndex].childs.length;
              columnIndex++
            ) {
              // console.log('Column');

              for (
                let compIndex = 0;
                compIndex <
                this.listScreen[0].childs[layoutIndex].childs[columnIndex]
                  .childs.length;
                compIndex++
              ) {
                let currentComp =
                  this.listScreen[0].childs[layoutIndex].childs[columnIndex]
                    .childs[compIndex];

                // check if current comp is hidden
                // console.log("current comp: ", currentComp);
                if (currentComp.isHidden) {
                  console.log("this is hidden component");
                }

                // assign the default value for value when rendering
                if (currentComp.defaultValue) {
                  currentComp.value = currentComp.defaultValue;
                }
                // console.log(currentComp);
                if (
                  currentComp.type == "checkbox" ||
                  currentComp.type == "Pick_List"
                ) {
                  for (let i = 0; i < currentComp.optionsValue.length; i++) {
                    let valueAtIndex = currentComp.optionsValue[i];
                    this.options.push({
                      label: valueAtIndex,
                      value: valueAtIndex
                    });
                  }
                  currentComp.listOptions = this.options;
                }

                if (currentComp.type == "radioGroup") {
                  this.options.push(
                    { label: "Yes", value: "true" },
                    { label: "No", value: "false" }
                  );
                  currentComp.listOptions = this.options;
                }
                //reset options
                this.options = [];
              }
            }
          }

          // if (result.brandColor && result.brandColor != "null") {
          //   var css = document.body.style;
          //   css.setProperty("--brandColor", result.brandColor);
          // }

          this.formName = result.formName;
          this.companyinfo = result.companyinfo;
          this.currencyCode = result.currencyCode;
          if (
            result.thankYouPageContent &&
            result.thankYouPageContent != "null"
          ) {
            this.thankYouPageContent = result.thankYouPageContent;
          }

          if (result.isUseThankYouPage && result.isUseThankYouPage != "null") {
            this.isUseThankYouPage = result.isUseThankYouPage;
          }

          // Init map field value
          if (this.paymentSetting.productList.length == 1) {
            this.paymentSetting.productList[0][
              this.namespacePrefix + "value__c".trim()
            ] = 1;
          }
          this.updateMapFieldValue(
            this.sumAmountStr,
            this.calculateSumAmount()
          );
        });
      })
      .catch((error) => {
        console.log("error in loading script: " + error);
        throw new Error("error in loading script: " + error);
      });
  }

  updateDataOnFields(event) {
    var cmpbuildEvent = event.target.closest('[data-name="cmpbuild"]');
    var currentField =
      this.listScreen[cmpbuildEvent.dataset.indexscreen].childs[
        cmpbuildEvent.dataset.indexlayout
      ].childs[cmpbuildEvent.dataset.indexcol].childs[
        cmpbuildEvent.dataset.index
      ];
    currentField.value = event.target.value;
    this.updateMapFieldValue(currentField.mapping, currentField.value);
    //public listScreendata
    this.publicListScreen = this.listScreen;
  }

  updateQuantity(event) {
    const currentQuantity = event.detail.currentQuantity;
    var productIndex = event.target.dataset.productindex;
    // console.log("=productIndex=" + productIndex);
    // console.log("=value=" + currentQuantity);
    this.paymentSetting.productList[productIndex]['value'] = currentQuantity;
    console.log('Product List: ', this.paymentSetting.productList);
    this.updateMapFieldValue(this.sumAmountStr, this.calculateSumAmount());
    this.showThankYouPage
  }

  // handlePickProduct(event) {
  //   // console.log('this.namespacePrefix: ' + this.namespacePrefix);
  //   var productIndex = event.target.dataset.productindex;
  //   if (event.target.checked == true) {
  //     this.paymentSetting.productList[productIndex]['value'] = 1;
  //   } else {
  //     this.paymentSetting.productList[productIndex]['value'] = 0;
  //   }
  //   this.updateMapFieldValue(this.sumAmountStr, this.calculateSumAmount());
  // }

  updateMapFieldValue(mapping, value) {
    var fieldInfo = {};
    fieldInfo.mapping = mapping;
    fieldInfo.value = value;
    var indexExisted = this.mappingFieldValue.findIndex(
      (x) => x.mapping === mapping
    );
    if (indexExisted == -1) {
      this.mappingFieldValue.push(fieldInfo);
    } else {
      this.mappingFieldValue[indexExisted].value = value;
    }
    this.replaceFieldFromMap();
  }

  calculateSumAmount() {
    this.sumAmountValue = 0;
    for (
      let lindex = 0;
      lindex < this.paymentSetting.productList.length;
      lindex++
    ) {
      this.sumAmountValue +=
        this.paymentSetting.productList[lindex]['value'] * this.paymentSetting.productList[lindex]['unitPrice'];
    }

    if (this.sumAmountValue) {
      console.log("sum amount value: ", this.sumAmountValue);
      this.totalAmountEqualtoZero = false;
    } else {
      this.totalAmountEqualtoZero = true;
    }
    return this.sumAmountValue;
  }

  recalculateSumAmount(currentFee) {
    this.chargeFee = Number((this.sumAmountValue * (this.currentPaymentFee / 100)).toFixed(2));
    this.totalAmountIncludeFee = this.sumAmountValue + this.chargeFee;
    // return this.totalAmountIncludeFee;
  }

  replaceFieldFromMap() {
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
            if (childComponent.isDisplayText == true) {
              var tempreplace = childComponent.value;
              for (
                let fieldindex = 0;
                fieldindex < this.mappingFieldValue.length;
                fieldindex++
              ) {
                tempreplace = tempreplace.replaceAll(
                  this.mappingFieldValue[fieldindex].mapping,
                  this.mappingFieldValue[fieldindex].value
                );
              }
              childComponent.valuereplaced = tempreplace;
              // console.log('childComponent.valuerepolaced: ', tempreplace);
            }
          }
        }
      }
    }
  }
  
  recalculateAmountByPromotionRate(promotionRate) {
    console.log('sum1: ', this.sumAmountValue);
    this.subAmount = this.sumAmountValue;
    this.discountString = promotionRate + ' %';
    this.sumAmountValue = this.sumAmountValue - (this.sumAmountValue * promotionRate) / 100

    console.log('sum after applied: ', this.sumAmountValue);
  }

  handlePromotionCode(event) {
    const promotionRate = event.detail.rate;
    this.promotionCode = event.detail.promotionCode;
    console.log('event.rate: ', promotionRate);
    console.log('promotion Code: ', event.detail.promotionCode);
    this.recalculateAmountByPromotionRate(promotionRate);
  }


  resetUpScreen() {
    for (let i = 0; i < this.listScreen.length; i++) {
      this.listScreen[i].isFinalScreen = false;
      this.listScreen[i].isOnlyOne = false;
      this.listScreen[i].isShow = false;
      this.listScreen[i].isStartScreen = false;
      this.listScreen[i].isMiddleScreen = true;
    }
    this.listScreen[0].isMiddleScreen = false;
    if (this.listScreen.length == 1) {
      this.listScreen[0].isOnlyOne = true;
    } else {
      this.listScreen[0].isOnlyOne = false;
      this.listScreen[0].isStartScreen = true;
      this.listScreen[0].isMiddleScreen = false;
      this.listScreen[this.listScreen.length - 1].isFinalScreen = true;
      this.listScreen[this.listScreen.length - 1].isMiddleScreen = false;
    }
  }

  get selectedValue() {}

  handleChange(event) {
    var cmpbuildEvent = event.target.closest('[data-name="cmpbuild"]');
    var currentField =
      this.listScreen[cmpbuildEvent.dataset.indexscreen].childs[
        cmpbuildEvent.dataset.indexlayout
      ].childs[cmpbuildEvent.dataset.indexcol].childs[
        cmpbuildEvent.dataset.index
      ];
    currentField.requiredDisplayTooltip = "tooltip-hide";

    var myTarget = JSON.parse(JSON.stringify(event.detail.value));
    currentField.value = myTarget.join(";");
    // console.log('Target: ', myTarget); // list value of multipicklist
    // console.log('current field: ', currentField);
    // console.log('multi select: ', currentField.value);
  }

  handleConfirmChange(event) {
    var cmpbuildEvent = event.target.closest('[data-name="cmpbuild"]');
    var currentField =
      this.listScreen[cmpbuildEvent.dataset.indexscreen].childs[
        cmpbuildEvent.dataset.indexlayout
      ].childs[cmpbuildEvent.dataset.indexcol].childs[
        cmpbuildEvent.dataset.index
      ];
    currentField.requiredDisplayTooltip = "tooltip-hide";
    console.log("confirm: ", event.target.checked);
    if (event.target.checked == true) {
      currentField.value = "true";
    } else currentField.value = "false";
    console.log("currentfield.value: ", currentField.value);
  }

  handleAddressChange(event) {
    var cmpbuildEvent = event.target.closest('[data-name="cmpbuild"]');
    var currentField =
      this.listScreen[cmpbuildEvent.dataset.indexscreen].childs[
        cmpbuildEvent.dataset.indexlayout
      ].childs[cmpbuildEvent.dataset.indexcol].childs[
        cmpbuildEvent.dataset.index
      ];
    this.address.street = event.target.street;
    this.address.city = event.target.city;
    this.address.province = event.target.province;
    this.address.country = event.target.country;
    this.address.postalCode = event.target.postalCode;
    console.log(JSON.stringify(this.address, null, 2)); // add address to current field
    currentField.address = JSON.stringify(this.address, null, 2);
    currentField.requiredDisplayTooltip = "tooltip-hide";
  }

  handleInputDateChange(event) {
    var cmpbuildEvent = event.target.closest('[data-name="cmpbuild"]');
    var currentField =
      this.listScreen[cmpbuildEvent.dataset.indexscreen].childs[
        cmpbuildEvent.dataset.indexlayout
      ].childs[cmpbuildEvent.dataset.indexcol].childs[
        cmpbuildEvent.dataset.index
      ];
    // currentField.requiredDisplayTooltip = 'tooltip-hide';
    currentField.value = event.target.value;
  }

  handleRadioChange(event) {
    var cmpbuildEvent = event.target.closest('[data-name="cmpbuild"]');
    var currentField =
      this.listScreen[cmpbuildEvent.dataset.indexscreen].childs[
        cmpbuildEvent.dataset.indexlayout
      ].childs[cmpbuildEvent.dataset.indexcol].childs[
        cmpbuildEvent.dataset.index
      ];
    if (event.target.value == true) {
      currentField.value = "true";
    } else currentField.value = "false";
    currentField.requiredDisplayTooltip = "tooltip-hide";
    console.log("currentField.value: ", currentField.value);
  }

  handleSelect(event) {
    var cmpbuildEvent = event.target.closest('[data-name="cmpbuild"]');
    var currentField =
      this.listScreen[cmpbuildEvent.dataset.indexscreen].childs[
        cmpbuildEvent.dataset.indexlayout
      ].childs[cmpbuildEvent.dataset.indexcol].childs[
        cmpbuildEvent.dataset.index
      ];
    currentField.value = event.target.value;
    currentField.requiredDisplayTooltip = "tooltip-hide";
    this.updateMapFieldValue(currentField.mapping, currentField.value);
    //public listScreendata
    this.publicListScreen = this.listScreen;
    // console.log('screen', this.publicListScreen);
  }

  handleErrorClose() {
    console.log("error close");
    this.isPaymentError = false;
    this.isSubmitError = false;
    this.isImportDataFailed = false;
    this.errorPaymentRequired = false;
  }

  handleClickNext() {
    var index = this.listScreen
      .map(function (e) {
        return e.isShow;
      })
      .indexOf(true);

    var isValid = this.validateFields(index);

    if (isValid == true) {
      for (let i = 0; i < this.listScreen.length; i++) {
        this.listScreen[i].isShow = false;
      }
      this.listScreen[index + 1].isShow = true;
    }
  }

  validateFields(screenIndex) {
    var validTilNow = true;
    this.template
      .querySelectorAll(
        '[data-indexscreen="' + screenIndex + '"] lightning-input'
      )
      .forEach((element) => {
        var temp = element.reportValidity();
        validTilNow = validTilNow && temp ? true : false;
      });

    //handle particularFields
    let isTooltipShow = false;
    this.listScreen.forEach((screen) => {
      screen.childs.forEach((layout) => {
        layout.childs.forEach((column) => {
          column.childs.forEach((field) => {
            field.requiredDisplayTooltip = "tooltip-hide";

            if (field.type == "Payment_Form" && field.value == null) {
              // do nothing
            } else if (field.isRequired && !field.isAddress && !field.value) {
              // console.log(field.type + ';' + field.value);
              field.requiredDisplayTooltip = "tooltip-text tooltip-show";
              isTooltipShow = true;
            }

            if ((field.type == "address") & field.isRequired) {
              console.log("address required here");
              const addr = JSON.parse(field.address);
              console.log("addr: ", addr);
              for (const property in addr) {
                console.log(`${property}: ${addr[property]}`);
                if (
                  (property == "street" ||
                    property == "city" ||
                    property == "province" ||
                    property == "postalCode") &&
                  !addr[property]
                ) {
                  field.requiredDisplayTooltip = "tooltip-text tooltip-show";
                  isTooltipShow = true;
                }
              }
            }

            if (field.type == "confirmationsBox" && field.isRequired) {
              console.log("12field.value: " + field.value);
              if (field.value == "false" || !field.value) {
                field.requiredDisplayTooltip = "tooltip-text tooltip-show";
                console.log(234);
                isTooltipShow = true;
              }
            }
            //check if payment is required for the form
            if (field.type == "Payment_Form") {
              console.log(234);
              console.log(this.sumAmountValue);
              if (field.isRequired == true && this.sumAmountValue == 0) {
                this.isRequiredPayment = true;
              }
            }
          });
        });
      });
    });

    if (validTilNow && !isTooltipShow) {
      return (validTilNow = true);
    } else {
      validTilNow = false;
      return validTilNow;
    }
  }

  handleClickBack() {
    var index = this.listScreen
      .map(function (e) {
        return e.isShow;
      })
      .indexOf(true);
    for (let i = 0; i < this.listScreen.length; i++) {
      this.listScreen[i].isShow = false;
    }
    this.listScreen[index - 1].isShow = true;
  }

  handleSubmitForm() {
    var index = this.listScreen
      .map(function (e) {
        return e.isShow;
      })
      .indexOf(true);

    var isValid = this.validateFields(index);
    console.log("123", this.isRequiredPayment);
    if (this.isRequiredPayment || !isValid) {
      this.showSpinner = false;
      if (this.isRequiredPayment) {
        this.errorPaymentRequired = true;
      }
      if (!isValid) {
        this.isSubmitError = true;
      }
      return null;
    } else {
      submitForm({
        jsonData: JSON.stringify(this.listScreen),
        linkobject: this.paymentSetting.linkobject,
        formName: this.formName,
      })
        .then((result) => {
          this.showSpinner = false;
          console.log("submit status: " + result);
          if (result == "Success Submission") {
            if (this.isUseThankYouPage == true) {
              for (let i = 0; i < this.listScreen.length; i++) {
                this.listScreen[i].isShow = false;
              }
              this.showThankYouPage = true;
              // Replace thanks content
              var tempreplace = this.thankYouPageContent;
              for (
                let fieldindex = 0;
                fieldindex < this.mappingFieldValue.length;
                fieldindex++
              ) {
                tempreplace = tempreplace.replaceAll(
                  this.mappingFieldValue[fieldindex].mapping,
                  this.mappingFieldValue[fieldindex].value
                );
              }

              this.thankYouPageContent = tempreplace;
            }
          } else {
            console.log("Error submit form: ==> ");
            this.isImportDataFailed = true;
          }
        })
        .catch((error) => {
          this.isSubmitError = true;
          console.log("error", error);
        });
    }
  }

  handleProcessPayment() {
    var index = this.listScreen
      .map(function (e) {
        return e.isShow;
      })
      .indexOf(true);

    var isValid = this.validateFields(index);
    if (!isValid) {
      this.showSpinner = false;
      if (!isValid) {
        this.isSubmitError = true;
      }
      return null;
    } else {
      this.IntegraPayProcessPayment();
    }
  }

  IntegraPayProcessPayment() {
    var btn = $(
      this.template.querySelector(
        'lightning-button[data-integrapay="SubmitButton"]'
      )
    );
    var backbtn = $(
      this.template.querySelector(
        'lightning-button[data-integrapay="BackButton"]'
      )
    );

    // Disable error <div>
    var errorsDiv = $(
      this.template.querySelector('div[data-integrapay="Errors"]')
    );
    errorsDiv.text("");
    errorsDiv.attr("id", "integrapay-ed");

    var cardName = this.template.querySelector('[data-integrapay="CardName"]');
    var cardNumber = this.template.querySelector(
      '[data-integrapay="CardNumber"]'
    );
    var cardCcv = this.template.querySelector('[data-integrapay="CardCcv"]');
    var cardExpiryMonth = this.template.querySelector(
      '[data-integrapay="CardExpiryMonth"]'
    );
    var cardExpiryYear = this.template.querySelector(
      '[data-integrapay="CardExpiryYear"]'
    );
    var deviceData = "";

    var cardDetails = {
      CardholderName: $(cardName).val(),
      CardNumber: $(cardNumber).val(),
      ExpiryMonth: $(cardExpiryMonth).val(),
      ExpiryYear: $(cardExpiryYear).val(),
      Ccv: $(cardCcv).val()
    };

    var tokenizeRequest = {
      Card: cardDetails,
      DeviceData: deviceData
    };

    

    if (!this.IntegraPayIsValidCardNumber($(cardNumber).val())) {
      cardNumber.setCustomValidity("Missing or invalid card number entered");
      cardNumber.reportValidity();
      return;
    } else {
      cardNumber.setCustomValidity("");
    }
    if (!this.IntegraPayIsValidCardName($(cardName).val())) {
      cardName.setCustomValidity(
        "Missing or invalid cardholder name entered (please enter letters and numbers only)"
      );
      cardName.reportValidity();
      return;
    } else {
      cardName.setCustomValidity("");
    }
    if (!this.IntegraPayIsValidCardCcv($(cardCcv).val())) {
      cardCcv.setCustomValidity("Missing or invalid card CCV entered");
      cardCcv.reportValidity();
      return;
    } else {
      cardCcv.setCustomValidity("");
    }
    if (!this.IntegraPayIsValidCardExpiryMonth($(cardExpiryMonth).val())) {
      cardExpiryMonth.setCustomValidity(
        "Missing or invalid expiry month selected"
      );
      cardExpiryMonth.reportValidity();
      return;
    } else {
      cardExpiryMonth.setCustomValidity("");
    }
    if (!this.IntegraPayIsValidCardExpiryYear($(cardExpiryYear).val())) {
      cardExpiryYear.setCustomValidity(
        "Missing or invalid expiry year selected"
      );
      cardExpiryYear.reportValidity();
      return;
    } else {
      cardExpiryYear.setCustomValidity("");
    }

    var expiryDate = new Date(
      $(cardExpiryYear).val(),
      $(cardExpiryMonth).val() - 1,
      1
    );
    console.log("Date", expiryDate);
    var dateCheck = new Date();
    dateCheck = new Date(dateCheck.getFullYear(), dateCheck.getMonth(), 1);
    if (expiryDate < dateCheck) {
      errorsDiv.text("Credit card is expired");
      return;
    }


    btn.prop("disabled", true);
    backbtn.prop("disabled", true);
    this.showSpinner = true;

    var apiUrl =
      this.paymentSetting.endpoint +
      "/businesses/" +
      this.paymentSetting.businesskey +
      "/services/tokenize-card";
    // console.log("apiUrl: ", apiUrl);
    const that = this;
    $.ajax({
      url: apiUrl,
      type: "POST",
      async: true,
      crossDomain: true,
      data: JSON.stringify(tokenizeRequest),
      dataType: "JSON",
      contentType: "application/json",
      success: function (dataSuccess) {
        var cardToken = dataSuccess.token;
        console.log("cardToken: ", dataSuccess.token);

        that.cardNumber =
          $(cardNumber)
            .val()
            .slice(0, $(cardNumber).val().length - 4)
            .replace(/./g, "*") +
          $(cardNumber)
            .val()
            .slice($(cardNumber).val().length - 4);
        $(cardNumber).val("");
        $(cardCcv).val("");
        cardDetails = null;
        tokenizeRequest = null;
        console.log("components: ", JSON.stringify(that.listScreen));
        console.log('Promotion Code: ', that.promotionCode);
        console.log('Product List String: ' , JSON.stringify(that.paymentSetting.productList));
        processPayment({
          jsonData: JSON.stringify(that.listScreen),
          linkobject: that.paymentSetting.linkobject,
          linkfield: that.paymentSetting.linkfield,
          cardToken: cardToken,
          productListStr: JSON.stringify(that.paymentSetting.productList),
          priceBookId: that.paymentSetting.priceBookId,
          deductedFromSettlement: !that.chargeOnCardHolder,
          promotionCode: that.promotionCode,
        })
          .then((result) => {
            console.log("status", result.Status);
            console.log("result", result);
            console.log("Message", result.Message);
            if (result.Status == "Success") {
              if (that.isUseThankYouPage == true) {
                for (let i = 0; i < that.listScreen.length; i++) {
                  that.listScreen[i].isShow = false;
                }
                that.showSpinner = false;
                that.showThankYouPage = true;
                // Replace thanks content
                var tempreplace = that.thankYouPageContent;
                for (
                  let fieldindex = 0;
                  fieldindex < that.mappingFieldValue.length;
                  fieldindex++
                ) {
                  tempreplace = tempreplace.replaceAll(
                    that.mappingFieldValue[fieldindex].mapping,
                    that.mappingFieldValue[fieldindex].value
                  );
                }

                that.thankYouPageContent = tempreplace;
              }
            } else {
              console.log('this.isPaymentError: ', that.isPaymentError);
              that.errorMessage = `Your payment is not completed due to error -- ${result.Message}, Please try again`;
              that.isPaymentError = true;
              btn.prop("disabled", false);
              backbtn.prop("disabled", false);
            }
            that.showSpinner = false;
          })
          .catch((error) => {
            that.showSpinner = false;
            that.isImportDataFailed = true;
            btn.prop("disabled", false);
            backbtn.prop("disabled", false);
          });
      },
      error: function (dataFail) {
        processingDiv.html("");
        that.errorServiceMessage = true;
        errorsDiv.text(
          "Service currently unavailable - sorry we were not able to process your payment"
        );
        btn.prop("disabled", false);
        backbtn.prop("disabled", false);
        that.showSpinner = false;
      }
    });
  }

  handleCardNumberChange(event) {
    let firstNumber = event.target.value;
    const firstString = firstNumber.substring(0, 1);
    if(this.paymentFeesData != null) {
      if(firstString === '3') {
        this.currentPaymentFee = this.paymentFeesData.Marchant_Fee_Amex;
      } else if(firstString === '4') {
        this.currentPaymentFee = this.paymentFeesData.Merchant_Fee_Visa;
      } else {
        this.currentPaymentFee = this.paymentFeesData.Marchant_Fee_Mastercard;
      }
    }
    this.recalculateSumAmount();
    // this.updateMapFieldValue(this.sumAmountStr, this.recalculateSumAmount(this.currentPaymentFee));
    this.checkCardNumber(event.target.value);
    console.log(this.currentPaymentFee);
  }

  checkCardNumber(value) {
    if (/^4[0-9]{6,}$/.test(value)) {
      this.isVisa = true;
      this.isMaster = false;
      this.isAMEX = false;
      this.isJCB = false;
    } else if (/^(?:2131|1800|35[0-9]{3})[0-9]{3,}$/.test(value)) {
      this.isVisa = false;
      this.isMaster = false;
      this.isAMEX = false;
      this.isJCB = true;
    } else if (/^3[47][0-9]{5,}$/.test(value)) {
      this.isVisa = false;
      this.isMaster = false;
      this.isAMEX = true;
      this.isJCB = false;
    } else if (
      /^5[1-5][0-9]{5,}|222[1-9][0-9]{3,}|22[3-9][0-9]{4,}|2[3-6][0-9]{5,}|27[01][0-9]{4,}|2720[0-9]{3,}$/.test(
        value
      )
    ) {
      this.isVisa = false;
      this.isMaster = true;
      this.isAMEX = false;
      this.isJCB = false;
    } else {
      this.isVisa = true;
      this.isMaster = true;
      this.isAMEX = true;
      this.isJCB = true;
    }
  }

  IntegraPayIsValidCardNumber(value) {
    if (/[^0-9]+/.test(value)) return false;

    if (value.length < 13 || value.length > 16) return false;

    var nCheck = 0,
      nDigit = 0,
      bEven = false;
    value = value.replace(/\D/g, "");

    for (var n = value.length - 1; n >= 0; n--) {
      var cDigit = value.charAt(n),
        nDigit = parseInt(cDigit, 10);

      if (bEven) {
        if ((nDigit *= 2) > 9) nDigit -= 9;
      }

      nCheck += nDigit;
      bEven = !bEven;
    }

    return nCheck % 10 == 0;
  }
  IntegraPayIsValidCardName(value) {
    if (/^([a-zA-Z0-9 '\-\.]{3,30})$/.test(value)) return true;
    else return false;
  }

  IntegraPayIsValidCardCcv(value) {
    if (/^(\d{3,4})$/.test(value)) return true;
    else return false;
  }

  IntegraPayIsValidCardExpiryYear(value) {
    if (/^(\d{4})$/.test(value)) return true;
    else return false;
  }

  IntegraPayIsValidCardExpiryMonth(value) {
    if (/^(\d{2})$/.test(value)) return true;
    else return false;
  }
}