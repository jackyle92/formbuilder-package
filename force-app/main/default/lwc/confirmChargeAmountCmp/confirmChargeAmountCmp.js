import { LightningElement, api } from 'lwc';

export default class ConfirmChargeAmountCmp extends LightningElement {
  @api totalAmount;
  @api sumAmountValue;
  @api merchantFee;

  get isTotalAmount() {
    if(this.totalAmount) return true;
    else return false;
  }
}