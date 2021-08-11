import 'package:flutter/widgets.dart';

import '../../generated/l10n.dart';

class PaymentMethod {
  String id;
  String name;
  String description;
  String logo;
  String route;
  bool isDefault;
  bool selected;

  PaymentMethod(this.id, this.name, this.description, this.route, this.logo, {this.isDefault = false, this.selected = false});
}

class PaymentMethodList {
  List<PaymentMethod> _paymentsList;
  List<PaymentMethod> _cashList;
  List<PaymentMethod> _pickupList;

  PaymentMethodList(BuildContext _context) {
    this._paymentsList = [
      new PaymentMethod("visacard", AppLocalization.of(_context).visa_card, AppLocalization.of(_context).click_to_pay_with_your_visa_card, "/Checkout", "assets/img/visacard.png",
          isDefault: true),
      new PaymentMethod("mastercard", AppLocalization.of(_context).mastercard, AppLocalization.of(_context).click_to_pay_with_your_mastercard, "/Checkout", "assets/img/mastercard.png"),
      new PaymentMethod("razorpay", AppLocalization.of(_context).razorpay, AppLocalization.of(_context).clickToPayWithRazorpayMethod, "/RazorPay", "assets/img/razorpay.png"),
      new PaymentMethod("paypal", AppLocalization.of(_context).paypal, AppLocalization.of(_context).click_to_pay_with_your_paypal_account, "/PayPal", "assets/img/paypal.png"),
    ];
    this._cashList = [
      new PaymentMethod("cod", AppLocalization.of(_context).cash_on_delivery, AppLocalization.of(_context).click_to_pay_cash_on_delivery, "/CashOnDelivery", "assets/img/cash.png"),
    ];
    this._pickupList = [
      new PaymentMethod("pop", AppLocalization.of(_context).pay_on_pickup, AppLocalization.of(_context).click_to_pay_on_pickup, "/PayOnPickup", "assets/img/pay_pickup.png"),
      new PaymentMethod("delivery", AppLocalization.of(_context).delivery_address, AppLocalization.of(_context).click_to_pay_on_pickup, "/PaymentMethod", "assets/img/pay_pickup.png"),
    ];
  }

  List<PaymentMethod> get paymentsList => _paymentsList;
  List<PaymentMethod> get cashList => _cashList;
  List<PaymentMethod> get pickupList => _pickupList;
}
