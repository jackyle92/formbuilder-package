import { LightningElement } from 'lwc';

export default class QuantityCounterElm extends LightningElement {
  quantity = 0;


  setDecrementCounter() {
    this.quantity--;
    if(this.quantity < 0) {
      this.quantity = 0;
    }
    this.updateQuantity();
  }

  setIncrementCounter() {
    this.quantity++;
    this.updateQuantity();
  }

  updateQuantity() {
    
    this.dispatchEvent(new CustomEvent('updatequantity', {detail: {
      currentQuantity: this.quantity,
      }
    }));
  }
}