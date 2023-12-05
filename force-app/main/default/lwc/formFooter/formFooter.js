import { LightningElement } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import getCompanyInfo from "@salesforce/apex/FormFooterCtrl.getCompanyInfo";
import fonts from "@salesforce/resourceUrl/PaymentFont";
import getNameSpacePrefix from "@salesforce/apex/FormBuilderHelper.getNameSpacePrefix";

export default class FormFooter extends LightningElement {
  companyinfo = {};
  namespacePrefix;


  currentYear = new Date().getFullYear();


  get isMobile() {
    return window.screen.width < 768;
  }



  connectedCallback() {
    getNameSpacePrefix().then((result) => {
      console.log('namespace prefix: ', result);
      if(result) {
        this.namespacePrefix = result + '__';
      } else {
        this.namespacePrefix = '';
      }
    });
    loadStyle(this, fonts + "/css/all.min.css");
    getCompanyInfo().then((result) => {
      // result.Company_Name__c = result.ccpformbuilder__Company_Name__c;
      result.Company_Name__c = result[this.namespacePrefix + "Company_Name__c"];
      result.Email__c = result[this.namespacePrefix + "Email__c"];
      result.Facebook__c = result[this.namespacePrefix +"Facebook__c"];
      result.Instagram__c = result[this.namespacePrefix +"Instagram__c"];
      result.Phone__c = result[this.namespacePrefix +"Phone__c"];
      result.Physical_Address__c = result[this.namespacePrefix + "Physical_Address__c"];
      result.Terms_Conditions__c = result[this.namespacePrefix + "Terms_Conditions__c"];
      result.Twitter__c = result[this.namespacePrefix + "Twitter__c"];

      this.companyinfo = result;
    });
  }
}