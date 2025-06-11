class FareModel {
  final String fareId;
  final double price;
  final String currencyType;
  final int paymentMethod;
  final int transfers;
  final int transferDuration;
  final String agencyId;

  FareModel({
    required this.fareId,
    required this.price,
    required this.currencyType,
    required this.paymentMethod,
    required this.transfers,
    required this.transferDuration,
    required this.agencyId,
  });

  factory FareModel.fromJson(String fareId, Map<String, dynamic> json) {
    return FareModel(
      fareId: fareId,
      price: (json['price'] ?? 0.0).toDouble(),
      currencyType: json['currency_type'] ?? 'INR',
      paymentMethod: json['payment_method'] ?? 0,
      transfers: json['transfers'] ?? 0,
      transferDuration: json['transfer_duration'] ?? 0,
      agencyId: json['agency_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fare_id': fareId,
      'price': price,
      'currency_type': currencyType,
      'payment_method': paymentMethod,
      'transfers': transfers,
      'transfer_duration': transferDuration,
      'agency_id': agencyId,
    };
  }

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 0:
        return 'Pay on board';
      case 1:
        return 'Pre-paid ticket required';
      default:
        return 'Unknown';
    }
  }

  String get transfersDisplay {
    switch (transfers) {
      case 0:
        return 'No transfers permitted';
      case 1:
        return 'One transfer permitted';
      case 2:
        return 'Two transfers permitted';
      default:
        return 'Unlimited transfers';
    }
  }

  bool get allowsTransfers => transfers > 0;
  bool get requiresPrepaidTicket => paymentMethod == 1;
} 