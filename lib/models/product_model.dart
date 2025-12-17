class ProductModel {
  final String id;
  final String name;
  final int price;
  final String weight;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.weight,
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      name: data['name'],
      price: data['price'],
      weight: data['weight'],
    );
  }
}
