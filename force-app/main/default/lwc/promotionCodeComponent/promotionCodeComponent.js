import { LightningElement, track, api } from 'lwc';
import getRateFromPromtionCode from '@salesforce/apex/Promotion_Code_Controller.getRateFromPromtionCode';

export default class PromotionCodeComponent extends LightningElement {
  @track promotionValue = '';
  @api formId;
  errorCode = false;
  rate;

  handlePromoInputChange(event) {
    this.errorCode = false;
    this.promotionValue = event.target.value;
  }


  handleApplyPromoCode() {
    if(!this.promotionValue) return;
    if(this.promotionValue.length > 0) {
      getRateFromPromtionCode({
        proCode : this.promotionValue,
        formId : this.formId
      }).then(result => {
        if(result != null) {
          // disable promotion
          this.template.querySelector('input').disabled = true;
          this.template.querySelector('button').disabled = true;
          this.rate = result;
          this.dispatchEvent(new CustomEvent('applycode', {detail: {
              rate: this.rate,
              promotionCode: this.promotionValue,
            }
          }));
        } else {
          this.errorCode = true;
        }
      }).catch(error => {
        console.log(error);
        throw new Error('Error when trying to get promotion code from apex');
      })
      //Calculate the total amount based on the promotion code
    }
  }
}