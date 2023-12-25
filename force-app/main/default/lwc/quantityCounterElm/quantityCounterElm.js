import { LightningElement, api } from 'lwc';

export default class QuantityCounterElm extends LightningElement {
  quantity = 0;
  @api maxQuantityOfProduct;


  setDecrementCounter() {
    this.quantity--;
    if(this.quantity < 0) {
      this.quantity = 0;
    }
    this.updateQuantity();
  }

  setIncrementCounter() {
    this.quantity++;
    if(this.quantity > this.maxQuantityOfProduct) {
      this.quantity = this.maxQuantityOfProduct;
    }
    this.updateQuantity();
  }

  updateQuantity() {
    
    this.dispatchEvent(new CustomEvent('updatequantity', {detail: {
      currentQuantity: this.quantity,
      }
    }));
  }
}