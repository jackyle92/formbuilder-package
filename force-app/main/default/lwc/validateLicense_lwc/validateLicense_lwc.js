import { LightningElement, track } from 'lwc';
import validateLicense from '@salesforce/apex/ProductLicenseManagement.getActiveLicense';

export default class ValidateLicense_lwc extends LightningElement {

  @track isActive = false;
  @track isShowingAlert = false;
  @track isLicenseError = false;
  @track message;

  connectedCallback() {
    validateLicense().then(result => {
      const returnData = JSON.parse(result);
      if(returnData.statusCode == 200) {
        if(returnData.message.includes('Active')) {
          this.isActive = true;
          this.message = returnData.message;
          setTimeout(() => {
                  this.isActive = false;
                }, 2000)
        } else {
          this.isShowingAlert = true;
          this.message = returnData.message;
          setTimeout(() => {
                  this.isShowingAlert = false;
                }, 2000)
        }
      } else {
        this.isLicenseError = true;
        this.message = returnData.message;
      }
    })
    .catch((error) => {
      console.log(error);
    })
  }

}