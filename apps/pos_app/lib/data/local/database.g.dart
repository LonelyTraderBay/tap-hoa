// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isWeightedMeta = const VerificationMeta(
    'isWeighted',
  );
  @override
  late final GeneratedColumn<bool> isWeighted = GeneratedColumn<bool>(
    'is_weighted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_weighted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _basePriceVndMeta = const VerificationMeta(
    'basePriceVnd',
  );
  @override
  late final GeneratedColumn<int> basePriceVnd = GeneratedColumn<int>(
    'base_price_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costVndMeta = const VerificationMeta(
    'costVnd',
  );
  @override
  late final GeneratedColumn<int> costVnd = GeneratedColumn<int>(
    'cost_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sku,
    barcode,
    name,
    unit,
    isWeighted,
    basePriceVnd,
    costVnd,
    active,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('is_weighted')) {
      context.handle(
        _isWeightedMeta,
        isWeighted.isAcceptableOrUnknown(data['is_weighted']!, _isWeightedMeta),
      );
    }
    if (data.containsKey('base_price_vnd')) {
      context.handle(
        _basePriceVndMeta,
        basePriceVnd.isAcceptableOrUnknown(
          data['base_price_vnd']!,
          _basePriceVndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_basePriceVndMeta);
    }
    if (data.containsKey('cost_vnd')) {
      context.handle(
        _costVndMeta,
        costVnd.isAcceptableOrUnknown(data['cost_vnd']!, _costVndMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      isWeighted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_weighted'],
      )!,
      basePriceVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_price_vnd'],
      )!,
      costVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_vnd'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String sku;
  final String? barcode;
  final String name;
  final String unit;
  final bool isWeighted;
  final int basePriceVnd;
  final int costVnd;
  final bool active;
  final DateTime updatedAt;
  const Product({
    required this.id,
    required this.sku,
    this.barcode,
    required this.name,
    required this.unit,
    required this.isWeighted,
    required this.basePriceVnd,
    required this.costVnd,
    required this.active,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sku'] = Variable<String>(sku);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['is_weighted'] = Variable<bool>(isWeighted);
    map['base_price_vnd'] = Variable<int>(basePriceVnd);
    map['cost_vnd'] = Variable<int>(costVnd);
    map['active'] = Variable<bool>(active);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      sku: Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      name: Value(name),
      unit: Value(unit),
      isWeighted: Value(isWeighted),
      basePriceVnd: Value(basePriceVnd),
      costVnd: Value(costVnd),
      active: Value(active),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      isWeighted: serializer.fromJson<bool>(json['isWeighted']),
      basePriceVnd: serializer.fromJson<int>(json['basePriceVnd']),
      costVnd: serializer.fromJson<int>(json['costVnd']),
      active: serializer.fromJson<bool>(json['active']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sku': serializer.toJson<String>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'isWeighted': serializer.toJson<bool>(isWeighted),
      'basePriceVnd': serializer.toJson<int>(basePriceVnd),
      'costVnd': serializer.toJson<int>(costVnd),
      'active': serializer.toJson<bool>(active),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith({
    String? id,
    String? sku,
    Value<String?> barcode = const Value.absent(),
    String? name,
    String? unit,
    bool? isWeighted,
    int? basePriceVnd,
    int? costVnd,
    bool? active,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    sku: sku ?? this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    isWeighted: isWeighted ?? this.isWeighted,
    basePriceVnd: basePriceVnd ?? this.basePriceVnd,
    costVnd: costVnd ?? this.costVnd,
    active: active ?? this.active,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      isWeighted: data.isWeighted.present
          ? data.isWeighted.value
          : this.isWeighted,
      basePriceVnd: data.basePriceVnd.present
          ? data.basePriceVnd.value
          : this.basePriceVnd,
      costVnd: data.costVnd.present ? data.costVnd.value : this.costVnd,
      active: data.active.present ? data.active.value : this.active,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('isWeighted: $isWeighted, ')
          ..write('basePriceVnd: $basePriceVnd, ')
          ..write('costVnd: $costVnd, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sku,
    barcode,
    name,
    unit,
    isWeighted,
    basePriceVnd,
    costVnd,
    active,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.isWeighted == this.isWeighted &&
          other.basePriceVnd == this.basePriceVnd &&
          other.costVnd == this.costVnd &&
          other.active == this.active &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> sku;
  final Value<String?> barcode;
  final Value<String> name;
  final Value<String> unit;
  final Value<bool> isWeighted;
  final Value<int> basePriceVnd;
  final Value<int> costVnd;
  final Value<bool> active;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.isWeighted = const Value.absent(),
    this.basePriceVnd = const Value.absent(),
    this.costVnd = const Value.absent(),
    this.active = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String sku,
    this.barcode = const Value.absent(),
    required String name,
    required String unit,
    this.isWeighted = const Value.absent(),
    required int basePriceVnd,
    this.costVnd = const Value.absent(),
    this.active = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sku = Value(sku),
       name = Value(name),
       unit = Value(unit),
       basePriceVnd = Value(basePriceVnd),
       updatedAt = Value(updatedAt);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<bool>? isWeighted,
    Expression<int>? basePriceVnd,
    Expression<int>? costVnd,
    Expression<bool>? active,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (isWeighted != null) 'is_weighted': isWeighted,
      if (basePriceVnd != null) 'base_price_vnd': basePriceVnd,
      if (costVnd != null) 'cost_vnd': costVnd,
      if (active != null) 'active': active,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? sku,
    Value<String?>? barcode,
    Value<String>? name,
    Value<String>? unit,
    Value<bool>? isWeighted,
    Value<int>? basePriceVnd,
    Value<int>? costVnd,
    Value<bool>? active,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      isWeighted: isWeighted ?? this.isWeighted,
      basePriceVnd: basePriceVnd ?? this.basePriceVnd,
      costVnd: costVnd ?? this.costVnd,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isWeighted.present) {
      map['is_weighted'] = Variable<bool>(isWeighted.value);
    }
    if (basePriceVnd.present) {
      map['base_price_vnd'] = Variable<int>(basePriceVnd.value);
    }
    if (costVnd.present) {
      map['cost_vnd'] = Variable<int>(costVnd.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('isWeighted: $isWeighted, ')
          ..write('basePriceVnd: $basePriceVnd, ')
          ..write('costVnd: $costVnd, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductStocksTable extends ProductStocks
    with TableInfo<$ProductStocksTable, ProductStock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductStocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<String> qty = GeneratedColumn<String>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minQtyMeta = const VerificationMeta('minQty');
  @override
  late final GeneratedColumn<String> minQty = GeneratedColumn<String>(
    'min_qty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    storeId,
    qty,
    minQty,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_stocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductStock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('min_qty')) {
      context.handle(
        _minQtyMeta,
        minQty.isAcceptableOrUnknown(data['min_qty']!, _minQtyMeta),
      );
    } else if (isInserting) {
      context.missing(_minQtyMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId, storeId};
  @override
  ProductStock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductStock(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qty'],
      )!,
      minQty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}min_qty'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductStocksTable createAlias(String alias) {
    return $ProductStocksTable(attachedDatabase, alias);
  }
}

class ProductStock extends DataClass implements Insertable<ProductStock> {
  final String productId;
  final String storeId;
  final String qty;
  final String minQty;
  final DateTime updatedAt;
  const ProductStock({
    required this.productId,
    required this.storeId,
    required this.qty,
    required this.minQty,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['store_id'] = Variable<String>(storeId);
    map['qty'] = Variable<String>(qty);
    map['min_qty'] = Variable<String>(minQty);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductStocksCompanion toCompanion(bool nullToAbsent) {
    return ProductStocksCompanion(
      productId: Value(productId),
      storeId: Value(storeId),
      qty: Value(qty),
      minQty: Value(minQty),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductStock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductStock(
      productId: serializer.fromJson<String>(json['productId']),
      storeId: serializer.fromJson<String>(json['storeId']),
      qty: serializer.fromJson<String>(json['qty']),
      minQty: serializer.fromJson<String>(json['minQty']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'storeId': serializer.toJson<String>(storeId),
      'qty': serializer.toJson<String>(qty),
      'minQty': serializer.toJson<String>(minQty),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductStock copyWith({
    String? productId,
    String? storeId,
    String? qty,
    String? minQty,
    DateTime? updatedAt,
  }) => ProductStock(
    productId: productId ?? this.productId,
    storeId: storeId ?? this.storeId,
    qty: qty ?? this.qty,
    minQty: minQty ?? this.minQty,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductStock copyWithCompanion(ProductStocksCompanion data) {
    return ProductStock(
      productId: data.productId.present ? data.productId.value : this.productId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      qty: data.qty.present ? data.qty.value : this.qty,
      minQty: data.minQty.present ? data.minQty.value : this.minQty,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductStock(')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('qty: $qty, ')
          ..write('minQty: $minQty, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, storeId, qty, minQty, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductStock &&
          other.productId == this.productId &&
          other.storeId == this.storeId &&
          other.qty == this.qty &&
          other.minQty == this.minQty &&
          other.updatedAt == this.updatedAt);
}

class ProductStocksCompanion extends UpdateCompanion<ProductStock> {
  final Value<String> productId;
  final Value<String> storeId;
  final Value<String> qty;
  final Value<String> minQty;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductStocksCompanion({
    this.productId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.qty = const Value.absent(),
    this.minQty = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductStocksCompanion.insert({
    required String productId,
    required String storeId,
    required String qty,
    required String minQty,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       storeId = Value(storeId),
       qty = Value(qty),
       minQty = Value(minQty),
       updatedAt = Value(updatedAt);
  static Insertable<ProductStock> custom({
    Expression<String>? productId,
    Expression<String>? storeId,
    Expression<String>? qty,
    Expression<String>? minQty,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (storeId != null) 'store_id': storeId,
      if (qty != null) 'qty': qty,
      if (minQty != null) 'min_qty': minQty,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductStocksCompanion copyWith({
    Value<String>? productId,
    Value<String>? storeId,
    Value<String>? qty,
    Value<String>? minQty,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductStocksCompanion(
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      qty: qty ?? this.qty,
      minQty: minQty ?? this.minQty,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<String>(qty.value);
    }
    if (minQty.present) {
      map['min_qty'] = Variable<String>(minQty.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductStocksCompanion(')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('qty: $qty, ')
          ..write('minQty: $minQty, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () =>
        const CustomExpression<bool>("status IN ('pending', 'error', 'done')"),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    payloadJson,
    createdAt,
    status,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  final String id;
  final String entityType;
  final String payloadJson;
  final DateTime createdAt;
  final String status;
  final String? lastError;
  const OutboxEntry({
    required this.id,
    required this.entityType,
    required this.payloadJson,
    required this.createdAt,
    required this.status,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      entityType: Value(entityType),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxEntry copyWith({
    String? id,
    String? entityType,
    String? payloadJson,
    DateTime? createdAt,
    String? status,
    Value<String?> lastError = const Value.absent(),
  }) => OutboxEntry(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityType, payloadJson, createdAt, status, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.lastError == this.lastError);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<int> rowid;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    required String id,
    required String entityType,
    required String payloadJson,
    required DateTime createdAt,
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<OutboxEntry> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesLocalTable extends SalesLocal
    with TableInfo<$SalesLocalTable, SalesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalVndMeta = const VerificationMeta(
    'totalVnd',
  );
  @override
  late final GeneratedColumn<int> totalVnd = GeneratedColumn<int>(
    'total_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashAmountMeta = const VerificationMeta(
    'cashAmount',
  );
  @override
  late final GeneratedColumn<int> cashAmount = GeneratedColumn<int>(
    'cash_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferAmountMeta = const VerificationMeta(
    'transferAmount',
  );
  @override
  late final GeneratedColumn<int> transferAmount = GeneratedColumn<int>(
    'transfer_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debtAmountMeta = const VerificationMeta(
    'debtAmount',
  );
  @override
  late final GeneratedColumn<int> debtAmount = GeneratedColumn<int>(
    'debt_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientCreatedAtMeta = const VerificationMeta(
    'clientCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientCreatedAt =
      GeneratedColumn<DateTime>(
        'client_created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    shiftId,
    paymentMethod,
    totalVnd,
    cashAmount,
    transferAmount,
    debtAmount,
    customerId,
    clientCreatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('total_vnd')) {
      context.handle(
        _totalVndMeta,
        totalVnd.isAcceptableOrUnknown(data['total_vnd']!, _totalVndMeta),
      );
    } else if (isInserting) {
      context.missing(_totalVndMeta);
    }
    if (data.containsKey('cash_amount')) {
      context.handle(
        _cashAmountMeta,
        cashAmount.isAcceptableOrUnknown(data['cash_amount']!, _cashAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_cashAmountMeta);
    }
    if (data.containsKey('transfer_amount')) {
      context.handle(
        _transferAmountMeta,
        transferAmount.isAcceptableOrUnknown(
          data['transfer_amount']!,
          _transferAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferAmountMeta);
    }
    if (data.containsKey('debt_amount')) {
      context.handle(
        _debtAmountMeta,
        debtAmount.isAcceptableOrUnknown(data['debt_amount']!, _debtAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_debtAmountMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('client_created_at')) {
      context.handle(
        _clientCreatedAtMeta,
        clientCreatedAt.isAcceptableOrUnknown(
          data['client_created_at']!,
          _clientCreatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientCreatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalesLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      totalVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_vnd'],
      )!,
      cashAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_amount'],
      )!,
      transferAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transfer_amount'],
      )!,
      debtAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}debt_amount'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      clientCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $SalesLocalTable createAlias(String alias) {
    return $SalesLocalTable(attachedDatabase, alias);
  }
}

class SalesLocalData extends DataClass implements Insertable<SalesLocalData> {
  final String id;
  final String storeId;
  final String shiftId;
  final String paymentMethod;
  final int totalVnd;
  final int cashAmount;
  final int transferAmount;
  final int debtAmount;
  final String? customerId;
  final DateTime clientCreatedAt;
  final DateTime? syncedAt;
  const SalesLocalData({
    required this.id,
    required this.storeId,
    required this.shiftId,
    required this.paymentMethod,
    required this.totalVnd,
    required this.cashAmount,
    required this.transferAmount,
    required this.debtAmount,
    this.customerId,
    required this.clientCreatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['shift_id'] = Variable<String>(shiftId);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['total_vnd'] = Variable<int>(totalVnd);
    map['cash_amount'] = Variable<int>(cashAmount);
    map['transfer_amount'] = Variable<int>(transferAmount);
    map['debt_amount'] = Variable<int>(debtAmount);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SalesLocalCompanion toCompanion(bool nullToAbsent) {
    return SalesLocalCompanion(
      id: Value(id),
      storeId: Value(storeId),
      shiftId: Value(shiftId),
      paymentMethod: Value(paymentMethod),
      totalVnd: Value(totalVnd),
      cashAmount: Value(cashAmount),
      transferAmount: Value(transferAmount),
      debtAmount: Value(debtAmount),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      clientCreatedAt: Value(clientCreatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SalesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesLocalData(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      totalVnd: serializer.fromJson<int>(json['totalVnd']),
      cashAmount: serializer.fromJson<int>(json['cashAmount']),
      transferAmount: serializer.fromJson<int>(json['transferAmount']),
      debtAmount: serializer.fromJson<int>(json['debtAmount']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      clientCreatedAt: serializer.fromJson<DateTime>(json['clientCreatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'shiftId': serializer.toJson<String>(shiftId),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'totalVnd': serializer.toJson<int>(totalVnd),
      'cashAmount': serializer.toJson<int>(cashAmount),
      'transferAmount': serializer.toJson<int>(transferAmount),
      'debtAmount': serializer.toJson<int>(debtAmount),
      'customerId': serializer.toJson<String?>(customerId),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SalesLocalData copyWith({
    String? id,
    String? storeId,
    String? shiftId,
    String? paymentMethod,
    int? totalVnd,
    int? cashAmount,
    int? transferAmount,
    int? debtAmount,
    Value<String?> customerId = const Value.absent(),
    DateTime? clientCreatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => SalesLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    shiftId: shiftId ?? this.shiftId,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    totalVnd: totalVnd ?? this.totalVnd,
    cashAmount: cashAmount ?? this.cashAmount,
    transferAmount: transferAmount ?? this.transferAmount,
    debtAmount: debtAmount ?? this.debtAmount,
    customerId: customerId.present ? customerId.value : this.customerId,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  SalesLocalData copyWithCompanion(SalesLocalCompanion data) {
    return SalesLocalData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      totalVnd: data.totalVnd.present ? data.totalVnd.value : this.totalVnd,
      cashAmount: data.cashAmount.present
          ? data.cashAmount.value
          : this.cashAmount,
      transferAmount: data.transferAmount.present
          ? data.transferAmount.value
          : this.transferAmount,
      debtAmount: data.debtAmount.present
          ? data.debtAmount.value
          : this.debtAmount,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesLocalData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('shiftId: $shiftId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('totalVnd: $totalVnd, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('transferAmount: $transferAmount, ')
          ..write('debtAmount: $debtAmount, ')
          ..write('customerId: $customerId, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    shiftId,
    paymentMethod,
    totalVnd,
    cashAmount,
    transferAmount,
    debtAmount,
    customerId,
    clientCreatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesLocalData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.shiftId == this.shiftId &&
          other.paymentMethod == this.paymentMethod &&
          other.totalVnd == this.totalVnd &&
          other.cashAmount == this.cashAmount &&
          other.transferAmount == this.transferAmount &&
          other.debtAmount == this.debtAmount &&
          other.customerId == this.customerId &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.syncedAt == this.syncedAt);
}

class SalesLocalCompanion extends UpdateCompanion<SalesLocalData> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> shiftId;
  final Value<String> paymentMethod;
  final Value<int> totalVnd;
  final Value<int> cashAmount;
  final Value<int> transferAmount;
  final Value<int> debtAmount;
  final Value<String?> customerId;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const SalesLocalCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.totalVnd = const Value.absent(),
    this.cashAmount = const Value.absent(),
    this.transferAmount = const Value.absent(),
    this.debtAmount = const Value.absent(),
    this.customerId = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesLocalCompanion.insert({
    required String id,
    required String storeId,
    required String shiftId,
    required String paymentMethod,
    required int totalVnd,
    required int cashAmount,
    required int transferAmount,
    required int debtAmount,
    this.customerId = const Value.absent(),
    required DateTime clientCreatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       shiftId = Value(shiftId),
       paymentMethod = Value(paymentMethod),
       totalVnd = Value(totalVnd),
       cashAmount = Value(cashAmount),
       transferAmount = Value(transferAmount),
       debtAmount = Value(debtAmount),
       clientCreatedAt = Value(clientCreatedAt);
  static Insertable<SalesLocalData> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? shiftId,
    Expression<String>? paymentMethod,
    Expression<int>? totalVnd,
    Expression<int>? cashAmount,
    Expression<int>? transferAmount,
    Expression<int>? debtAmount,
    Expression<String>? customerId,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (shiftId != null) 'shift_id': shiftId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (totalVnd != null) 'total_vnd': totalVnd,
      if (cashAmount != null) 'cash_amount': cashAmount,
      if (transferAmount != null) 'transfer_amount': transferAmount,
      if (debtAmount != null) 'debt_amount': debtAmount,
      if (customerId != null) 'customer_id': customerId,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? shiftId,
    Value<String>? paymentMethod,
    Value<int>? totalVnd,
    Value<int>? cashAmount,
    Value<int>? transferAmount,
    Value<int>? debtAmount,
    Value<String?>? customerId,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return SalesLocalCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      shiftId: shiftId ?? this.shiftId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalVnd: totalVnd ?? this.totalVnd,
      cashAmount: cashAmount ?? this.cashAmount,
      transferAmount: transferAmount ?? this.transferAmount,
      debtAmount: debtAmount ?? this.debtAmount,
      customerId: customerId ?? this.customerId,
      clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (totalVnd.present) {
      map['total_vnd'] = Variable<int>(totalVnd.value);
    }
    if (cashAmount.present) {
      map['cash_amount'] = Variable<int>(cashAmount.value);
    }
    if (transferAmount.present) {
      map['transfer_amount'] = Variable<int>(transferAmount.value);
    }
    if (debtAmount.present) {
      map['debt_amount'] = Variable<int>(debtAmount.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (clientCreatedAt.present) {
      map['client_created_at'] = Variable<DateTime>(clientCreatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesLocalCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('shiftId: $shiftId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('totalVnd: $totalVnd, ')
          ..write('cashAmount: $cashAmount, ')
          ..write('transferAmount: $transferAmount, ')
          ..write('debtAmount: $debtAmount, ')
          ..write('customerId: $customerId, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleLinesLocalTable extends SaleLinesLocal
    with TableInfo<$SaleLinesLocalTable, SaleLinesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleLinesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<String> qty = GeneratedColumn<String>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<int> lineTotal = GeneratedColumn<int>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleId,
    productId,
    qty,
    unitPrice,
    lineTotal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_lines_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleLinesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleLinesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleLinesLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qty'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_total'],
      )!,
    );
  }

  @override
  $SaleLinesLocalTable createAlias(String alias) {
    return $SaleLinesLocalTable(attachedDatabase, alias);
  }
}

class SaleLinesLocalData extends DataClass
    implements Insertable<SaleLinesLocalData> {
  final String id;
  final String saleId;
  final String productId;
  final String qty;
  final int unitPrice;
  final int lineTotal;
  const SaleLinesLocalData({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sale_id'] = Variable<String>(saleId);
    map['product_id'] = Variable<String>(productId);
    map['qty'] = Variable<String>(qty);
    map['unit_price'] = Variable<int>(unitPrice);
    map['line_total'] = Variable<int>(lineTotal);
    return map;
  }

  SaleLinesLocalCompanion toCompanion(bool nullToAbsent) {
    return SaleLinesLocalCompanion(
      id: Value(id),
      saleId: Value(saleId),
      productId: Value(productId),
      qty: Value(qty),
      unitPrice: Value(unitPrice),
      lineTotal: Value(lineTotal),
    );
  }

  factory SaleLinesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleLinesLocalData(
      id: serializer.fromJson<String>(json['id']),
      saleId: serializer.fromJson<String>(json['saleId']),
      productId: serializer.fromJson<String>(json['productId']),
      qty: serializer.fromJson<String>(json['qty']),
      unitPrice: serializer.fromJson<int>(json['unitPrice']),
      lineTotal: serializer.fromJson<int>(json['lineTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'saleId': serializer.toJson<String>(saleId),
      'productId': serializer.toJson<String>(productId),
      'qty': serializer.toJson<String>(qty),
      'unitPrice': serializer.toJson<int>(unitPrice),
      'lineTotal': serializer.toJson<int>(lineTotal),
    };
  }

  SaleLinesLocalData copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? qty,
    int? unitPrice,
    int? lineTotal,
  }) => SaleLinesLocalData(
    id: id ?? this.id,
    saleId: saleId ?? this.saleId,
    productId: productId ?? this.productId,
    qty: qty ?? this.qty,
    unitPrice: unitPrice ?? this.unitPrice,
    lineTotal: lineTotal ?? this.lineTotal,
  );
  SaleLinesLocalData copyWithCompanion(SaleLinesLocalCompanion data) {
    return SaleLinesLocalData(
      id: data.id.present ? data.id.value : this.id,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleLinesLocalData(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('lineTotal: $lineTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, saleId, productId, qty, unitPrice, lineTotal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleLinesLocalData &&
          other.id == this.id &&
          other.saleId == this.saleId &&
          other.productId == this.productId &&
          other.qty == this.qty &&
          other.unitPrice == this.unitPrice &&
          other.lineTotal == this.lineTotal);
}

class SaleLinesLocalCompanion extends UpdateCompanion<SaleLinesLocalData> {
  final Value<String> id;
  final Value<String> saleId;
  final Value<String> productId;
  final Value<String> qty;
  final Value<int> unitPrice;
  final Value<int> lineTotal;
  final Value<int> rowid;
  const SaleLinesLocalCompanion({
    this.id = const Value.absent(),
    this.saleId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SaleLinesLocalCompanion.insert({
    required String id,
    required String saleId,
    required String productId,
    required String qty,
    required int unitPrice,
    required int lineTotal,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       saleId = Value(saleId),
       productId = Value(productId),
       qty = Value(qty),
       unitPrice = Value(unitPrice),
       lineTotal = Value(lineTotal);
  static Insertable<SaleLinesLocalData> custom({
    Expression<String>? id,
    Expression<String>? saleId,
    Expression<String>? productId,
    Expression<String>? qty,
    Expression<int>? unitPrice,
    Expression<int>? lineTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (lineTotal != null) 'line_total': lineTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SaleLinesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? saleId,
    Value<String>? productId,
    Value<String>? qty,
    Value<int>? unitPrice,
    Value<int>? lineTotal,
    Value<int>? rowid,
  }) {
    return SaleLinesLocalCompanion(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<String>(qty.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<int>(lineTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleLinesLocalCompanion(')
          ..write('id: $id, ')
          ..write('saleId: $saleId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftsLocalTable extends ShiftsLocal
    with TableInfo<$ShiftsLocalTable, ShiftsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openingCashMeta = const VerificationMeta(
    'openingCash',
  );
  @override
  late final GeneratedColumn<int> openingCash = GeneratedColumn<int>(
    'opening_cash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closingCashMeta = const VerificationMeta(
    'closingCash',
  );
  @override
  late final GeneratedColumn<int> closingCash = GeneratedColumn<int>(
    'closing_cash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    userId,
    openedAt,
    closedAt,
    openingCash,
    closingCash,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftsLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('opening_cash')) {
      context.handle(
        _openingCashMeta,
        openingCash.isAcceptableOrUnknown(
          data['opening_cash']!,
          _openingCashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingCashMeta);
    }
    if (data.containsKey('closing_cash')) {
      context.handle(
        _closingCashMeta,
        closingCash.isAcceptableOrUnknown(
          data['closing_cash']!,
          _closingCashMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftsLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      openingCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_cash'],
      )!,
      closingCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closing_cash'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $ShiftsLocalTable createAlias(String alias) {
    return $ShiftsLocalTable(attachedDatabase, alias);
  }
}

class ShiftsLocalData extends DataClass implements Insertable<ShiftsLocalData> {
  final String id;
  final String storeId;
  final String userId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int openingCash;
  final int? closingCash;
  final String? note;
  const ShiftsLocalData({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['user_id'] = Variable<String>(userId);
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    map['opening_cash'] = Variable<int>(openingCash);
    if (!nullToAbsent || closingCash != null) {
      map['closing_cash'] = Variable<int>(closingCash);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  ShiftsLocalCompanion toCompanion(bool nullToAbsent) {
    return ShiftsLocalCompanion(
      id: Value(id),
      storeId: Value(storeId),
      userId: Value(userId),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      openingCash: Value(openingCash),
      closingCash: closingCash == null && nullToAbsent
          ? const Value.absent()
          : Value(closingCash),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory ShiftsLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftsLocalData(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      userId: serializer.fromJson<String>(json['userId']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      openingCash: serializer.fromJson<int>(json['openingCash']),
      closingCash: serializer.fromJson<int?>(json['closingCash']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'userId': serializer.toJson<String>(userId),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'openingCash': serializer.toJson<int>(openingCash),
      'closingCash': serializer.toJson<int?>(closingCash),
      'note': serializer.toJson<String?>(note),
    };
  }

  ShiftsLocalData copyWith({
    String? id,
    String? storeId,
    String? userId,
    DateTime? openedAt,
    Value<DateTime?> closedAt = const Value.absent(),
    int? openingCash,
    Value<int?> closingCash = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => ShiftsLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    userId: userId ?? this.userId,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    openingCash: openingCash ?? this.openingCash,
    closingCash: closingCash.present ? closingCash.value : this.closingCash,
    note: note.present ? note.value : this.note,
  );
  ShiftsLocalData copyWithCompanion(ShiftsLocalCompanion data) {
    return ShiftsLocalData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      userId: data.userId.present ? data.userId.value : this.userId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      openingCash: data.openingCash.present
          ? data.openingCash.value
          : this.openingCash,
      closingCash: data.closingCash.present
          ? data.closingCash.value
          : this.closingCash,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsLocalData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('userId: $userId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('openingCash: $openingCash, ')
          ..write('closingCash: $closingCash, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    userId,
    openedAt,
    closedAt,
    openingCash,
    closingCash,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftsLocalData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.userId == this.userId &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.openingCash == this.openingCash &&
          other.closingCash == this.closingCash &&
          other.note == this.note);
}

class ShiftsLocalCompanion extends UpdateCompanion<ShiftsLocalData> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> userId;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  final Value<int> openingCash;
  final Value<int?> closingCash;
  final Value<String?> note;
  final Value<int> rowid;
  const ShiftsLocalCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.userId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.closingCash = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShiftsLocalCompanion.insert({
    required String id,
    required String storeId,
    required String userId,
    required DateTime openedAt,
    this.closedAt = const Value.absent(),
    required int openingCash,
    this.closingCash = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       userId = Value(userId),
       openedAt = Value(openedAt),
       openingCash = Value(openingCash);
  static Insertable<ShiftsLocalData> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? userId,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<int>? openingCash,
    Expression<int>? closingCash,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (userId != null) 'user_id': userId,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (openingCash != null) 'opening_cash': openingCash,
      if (closingCash != null) 'closing_cash': closingCash,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShiftsLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? userId,
    Value<DateTime>? openedAt,
    Value<DateTime?>? closedAt,
    Value<int>? openingCash,
    Value<int?>? closingCash,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return ShiftsLocalCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      userId: userId ?? this.userId,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      openingCash: openingCash ?? this.openingCash,
      closingCash: closingCash ?? this.closingCash,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (openingCash.present) {
      map['opening_cash'] = Variable<int>(openingCash.value);
    }
    if (closingCash.present) {
      map['closing_cash'] = Variable<int>(closingCash.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsLocalCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('userId: $userId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('openingCash: $openingCash, ')
          ..write('closingCash: $closingCash, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoresLocalTable extends StoresLocal
    with TableInfo<$StoresLocalTable, StoresLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoresLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, code, name, active, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stores_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoresLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoresLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoresLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoresLocalTable createAlias(String alias) {
    return $StoresLocalTable(attachedDatabase, alias);
  }
}

class StoresLocalData extends DataClass implements Insertable<StoresLocalData> {
  final String id;
  final String code;
  final String name;
  final bool active;
  final DateTime updatedAt;
  const StoresLocalData({
    required this.id,
    required this.code,
    required this.name,
    required this.active,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['active'] = Variable<bool>(active);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoresLocalCompanion toCompanion(bool nullToAbsent) {
    return StoresLocalCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      active: Value(active),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoresLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoresLocalData(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      active: serializer.fromJson<bool>(json['active']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'active': serializer.toJson<bool>(active),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoresLocalData copyWith({
    String? id,
    String? code,
    String? name,
    bool? active,
    DateTime? updatedAt,
  }) => StoresLocalData(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    active: active ?? this.active,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoresLocalData copyWithCompanion(StoresLocalCompanion data) {
    return StoresLocalData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      active: data.active.present ? data.active.value : this.active,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoresLocalData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, active, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoresLocalData &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.active == this.active &&
          other.updatedAt == this.updatedAt);
}

class StoresLocalCompanion extends UpdateCompanion<StoresLocalData> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<bool> active;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StoresLocalCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.active = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoresLocalCompanion.insert({
    required String id,
    required String code,
    required String name,
    this.active = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<StoresLocalData> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? active,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoresLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<bool>? active,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StoresLocalCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoresLocalCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaLocalTable extends MetaLocal
    with TableInfo<$MetaLocalTable, MetaLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetaLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaLocalData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MetaLocalTable createAlias(String alias) {
    return $MetaLocalTable(attachedDatabase, alias);
  }
}

class MetaLocalData extends DataClass implements Insertable<MetaLocalData> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const MetaLocalData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MetaLocalCompanion toCompanion(bool nullToAbsent) {
    return MetaLocalCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory MetaLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaLocalData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MetaLocalData copyWith({String? key, String? value, DateTime? updatedAt}) =>
      MetaLocalData(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MetaLocalData copyWithCompanion(MetaLocalCompanion data) {
    return MetaLocalData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaLocalData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaLocalData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class MetaLocalCompanion extends UpdateCompanion<MetaLocalData> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MetaLocalCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaLocalCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaLocalData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaLocalCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MetaLocalCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaLocalCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersLocalTable extends CustomersLocal
    with TableInfo<$CustomersLocalTable, CustomersLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceVndMeta = const VerificationMeta(
    'balanceVnd',
  );
  @override
  late final GeneratedColumn<int> balanceVnd = GeneratedColumn<int>(
    'balance_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creditLimitVndMeta = const VerificationMeta(
    'creditLimitVnd',
  );
  @override
  late final GeneratedColumn<int> creditLimitVnd = GeneratedColumn<int>(
    'credit_limit_vnd',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    balanceVnd,
    creditLimitVnd,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomersLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('balance_vnd')) {
      context.handle(
        _balanceVndMeta,
        balanceVnd.isAcceptableOrUnknown(data['balance_vnd']!, _balanceVndMeta),
      );
    }
    if (data.containsKey('credit_limit_vnd')) {
      context.handle(
        _creditLimitVndMeta,
        creditLimitVnd.isAcceptableOrUnknown(
          data['credit_limit_vnd']!,
          _creditLimitVndMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomersLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomersLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      balanceVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_vnd'],
      )!,
      creditLimitVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit_vnd'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomersLocalTable createAlias(String alias) {
    return $CustomersLocalTable(attachedDatabase, alias);
  }
}

class CustomersLocalData extends DataClass
    implements Insertable<CustomersLocalData> {
  final String id;
  final String name;
  final String? phone;
  final int balanceVnd;
  final int? creditLimitVnd;
  final DateTime updatedAt;
  const CustomersLocalData({
    required this.id,
    required this.name,
    this.phone,
    required this.balanceVnd,
    this.creditLimitVnd,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['balance_vnd'] = Variable<int>(balanceVnd);
    if (!nullToAbsent || creditLimitVnd != null) {
      map['credit_limit_vnd'] = Variable<int>(creditLimitVnd);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CustomersLocalCompanion toCompanion(bool nullToAbsent) {
    return CustomersLocalCompanion(
      id: Value(id),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      balanceVnd: Value(balanceVnd),
      creditLimitVnd: creditLimitVnd == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimitVnd),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomersLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomersLocalData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      balanceVnd: serializer.fromJson<int>(json['balanceVnd']),
      creditLimitVnd: serializer.fromJson<int?>(json['creditLimitVnd']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'balanceVnd': serializer.toJson<int>(balanceVnd),
      'creditLimitVnd': serializer.toJson<int?>(creditLimitVnd),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CustomersLocalData copyWith({
    String? id,
    String? name,
    Value<String?> phone = const Value.absent(),
    int? balanceVnd,
    Value<int?> creditLimitVnd = const Value.absent(),
    DateTime? updatedAt,
  }) => CustomersLocalData(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    balanceVnd: balanceVnd ?? this.balanceVnd,
    creditLimitVnd: creditLimitVnd.present
        ? creditLimitVnd.value
        : this.creditLimitVnd,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomersLocalData copyWithCompanion(CustomersLocalCompanion data) {
    return CustomersLocalData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      balanceVnd: data.balanceVnd.present
          ? data.balanceVnd.value
          : this.balanceVnd,
      creditLimitVnd: data.creditLimitVnd.present
          ? data.creditLimitVnd.value
          : this.creditLimitVnd,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomersLocalData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('balanceVnd: $balanceVnd, ')
          ..write('creditLimitVnd: $creditLimitVnd, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, balanceVnd, creditLimitVnd, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomersLocalData &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.balanceVnd == this.balanceVnd &&
          other.creditLimitVnd == this.creditLimitVnd &&
          other.updatedAt == this.updatedAt);
}

class CustomersLocalCompanion extends UpdateCompanion<CustomersLocalData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<int> balanceVnd;
  final Value<int?> creditLimitVnd;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CustomersLocalCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.balanceVnd = const Value.absent(),
    this.creditLimitVnd = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersLocalCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.balanceVnd = const Value.absent(),
    this.creditLimitVnd = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<CustomersLocalData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<int>? balanceVnd,
    Expression<int>? creditLimitVnd,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (balanceVnd != null) 'balance_vnd': balanceVnd,
      if (creditLimitVnd != null) 'credit_limit_vnd': creditLimitVnd,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? phone,
    Value<int>? balanceVnd,
    Value<int?>? creditLimitVnd,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CustomersLocalCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balanceVnd: balanceVnd ?? this.balanceVnd,
      creditLimitVnd: creditLimitVnd ?? this.creditLimitVnd,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (balanceVnd.present) {
      map['balance_vnd'] = Variable<int>(balanceVnd.value);
    }
    if (creditLimitVnd.present) {
      map['credit_limit_vnd'] = Variable<int>(creditLimitVnd.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersLocalCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('balanceVnd: $balanceVnd, ')
          ..write('creditLimitVnd: $creditLimitVnd, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtLedgerLocalTable extends DebtLedgerLocal
    with TableInfo<$DebtLedgerLocalTable, DebtLedgerLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtLedgerLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountVndMeta = const VerificationMeta(
    'amountVnd',
  );
  @override
  late final GeneratedColumn<int> amountVnd = GeneratedColumn<int>(
    'amount_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceAfterVndMeta = const VerificationMeta(
    'balanceAfterVnd',
  );
  @override
  late final GeneratedColumn<int> balanceAfterVnd = GeneratedColumn<int>(
    'balance_after_vnd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedByIdMeta = const VerificationMeta(
    'recordedById',
  );
  @override
  late final GeneratedColumn<String> recordedById = GeneratedColumn<String>(
    'recorded_by_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientCreatedAtMeta = const VerificationMeta(
    'clientCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientCreatedAt =
      GeneratedColumn<DateTime>(
        'client_created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    customerId,
    type,
    amountVnd,
    balanceAfterVnd,
    saleId,
    shiftId,
    recordedById,
    paymentMethod,
    note,
    clientCreatedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_ledger_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtLedgerLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_vnd')) {
      context.handle(
        _amountVndMeta,
        amountVnd.isAcceptableOrUnknown(data['amount_vnd']!, _amountVndMeta),
      );
    } else if (isInserting) {
      context.missing(_amountVndMeta);
    }
    if (data.containsKey('balance_after_vnd')) {
      context.handle(
        _balanceAfterVndMeta,
        balanceAfterVnd.isAcceptableOrUnknown(
          data['balance_after_vnd']!,
          _balanceAfterVndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceAfterVndMeta);
    }
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    }
    if (data.containsKey('recorded_by_id')) {
      context.handle(
        _recordedByIdMeta,
        recordedById.isAcceptableOrUnknown(
          data['recorded_by_id']!,
          _recordedByIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedByIdMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('client_created_at')) {
      context.handle(
        _clientCreatedAtMeta,
        clientCreatedAt.isAcceptableOrUnknown(
          data['client_created_at']!,
          _clientCreatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientCreatedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtLedgerLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtLedgerLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_vnd'],
      )!,
      balanceAfterVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_after_vnd'],
      )!,
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      ),
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      ),
      recordedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_id'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      clientCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DebtLedgerLocalTable createAlias(String alias) {
    return $DebtLedgerLocalTable(attachedDatabase, alias);
  }
}

class DebtLedgerLocalData extends DataClass
    implements Insertable<DebtLedgerLocalData> {
  final String id;
  final String storeId;
  final String customerId;
  final String type;
  final int amountVnd;
  final int balanceAfterVnd;
  final String? saleId;
  final String? shiftId;
  final String recordedById;
  final String? paymentMethod;
  final String? note;
  final DateTime clientCreatedAt;
  final DateTime updatedAt;
  const DebtLedgerLocalData({
    required this.id,
    required this.storeId,
    required this.customerId,
    required this.type,
    required this.amountVnd,
    required this.balanceAfterVnd,
    this.saleId,
    this.shiftId,
    required this.recordedById,
    this.paymentMethod,
    this.note,
    required this.clientCreatedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['customer_id'] = Variable<String>(customerId);
    map['type'] = Variable<String>(type);
    map['amount_vnd'] = Variable<int>(amountVnd);
    map['balance_after_vnd'] = Variable<int>(balanceAfterVnd);
    if (!nullToAbsent || saleId != null) {
      map['sale_id'] = Variable<String>(saleId);
    }
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<String>(shiftId);
    }
    map['recorded_by_id'] = Variable<String>(recordedById);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DebtLedgerLocalCompanion toCompanion(bool nullToAbsent) {
    return DebtLedgerLocalCompanion(
      id: Value(id),
      storeId: Value(storeId),
      customerId: Value(customerId),
      type: Value(type),
      amountVnd: Value(amountVnd),
      balanceAfterVnd: Value(balanceAfterVnd),
      saleId: saleId == null && nullToAbsent
          ? const Value.absent()
          : Value(saleId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      recordedById: Value(recordedById),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clientCreatedAt: Value(clientCreatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DebtLedgerLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtLedgerLocalData(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      customerId: serializer.fromJson<String>(json['customerId']),
      type: serializer.fromJson<String>(json['type']),
      amountVnd: serializer.fromJson<int>(json['amountVnd']),
      balanceAfterVnd: serializer.fromJson<int>(json['balanceAfterVnd']),
      saleId: serializer.fromJson<String?>(json['saleId']),
      shiftId: serializer.fromJson<String?>(json['shiftId']),
      recordedById: serializer.fromJson<String>(json['recordedById']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      note: serializer.fromJson<String?>(json['note']),
      clientCreatedAt: serializer.fromJson<DateTime>(json['clientCreatedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String>(storeId),
      'customerId': serializer.toJson<String>(customerId),
      'type': serializer.toJson<String>(type),
      'amountVnd': serializer.toJson<int>(amountVnd),
      'balanceAfterVnd': serializer.toJson<int>(balanceAfterVnd),
      'saleId': serializer.toJson<String?>(saleId),
      'shiftId': serializer.toJson<String?>(shiftId),
      'recordedById': serializer.toJson<String>(recordedById),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'note': serializer.toJson<String?>(note),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DebtLedgerLocalData copyWith({
    String? id,
    String? storeId,
    String? customerId,
    String? type,
    int? amountVnd,
    int? balanceAfterVnd,
    Value<String?> saleId = const Value.absent(),
    Value<String?> shiftId = const Value.absent(),
    String? recordedById,
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? clientCreatedAt,
    DateTime? updatedAt,
  }) => DebtLedgerLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    customerId: customerId ?? this.customerId,
    type: type ?? this.type,
    amountVnd: amountVnd ?? this.amountVnd,
    balanceAfterVnd: balanceAfterVnd ?? this.balanceAfterVnd,
    saleId: saleId.present ? saleId.value : this.saleId,
    shiftId: shiftId.present ? shiftId.value : this.shiftId,
    recordedById: recordedById ?? this.recordedById,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    note: note.present ? note.value : this.note,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DebtLedgerLocalData copyWithCompanion(DebtLedgerLocalCompanion data) {
    return DebtLedgerLocalData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      type: data.type.present ? data.type.value : this.type,
      amountVnd: data.amountVnd.present ? data.amountVnd.value : this.amountVnd,
      balanceAfterVnd: data.balanceAfterVnd.present
          ? data.balanceAfterVnd.value
          : this.balanceAfterVnd,
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      recordedById: data.recordedById.present
          ? data.recordedById.value
          : this.recordedById,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      note: data.note.present ? data.note.value : this.note,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtLedgerLocalData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('customerId: $customerId, ')
          ..write('type: $type, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('balanceAfterVnd: $balanceAfterVnd, ')
          ..write('saleId: $saleId, ')
          ..write('shiftId: $shiftId, ')
          ..write('recordedById: $recordedById, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('note: $note, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    customerId,
    type,
    amountVnd,
    balanceAfterVnd,
    saleId,
    shiftId,
    recordedById,
    paymentMethod,
    note,
    clientCreatedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtLedgerLocalData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.customerId == this.customerId &&
          other.type == this.type &&
          other.amountVnd == this.amountVnd &&
          other.balanceAfterVnd == this.balanceAfterVnd &&
          other.saleId == this.saleId &&
          other.shiftId == this.shiftId &&
          other.recordedById == this.recordedById &&
          other.paymentMethod == this.paymentMethod &&
          other.note == this.note &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.updatedAt == this.updatedAt);
}

class DebtLedgerLocalCompanion extends UpdateCompanion<DebtLedgerLocalData> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> customerId;
  final Value<String> type;
  final Value<int> amountVnd;
  final Value<int> balanceAfterVnd;
  final Value<String?> saleId;
  final Value<String?> shiftId;
  final Value<String> recordedById;
  final Value<String?> paymentMethod;
  final Value<String?> note;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DebtLedgerLocalCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.type = const Value.absent(),
    this.amountVnd = const Value.absent(),
    this.balanceAfterVnd = const Value.absent(),
    this.saleId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.recordedById = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.note = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtLedgerLocalCompanion.insert({
    required String id,
    required String storeId,
    required String customerId,
    required String type,
    required int amountVnd,
    required int balanceAfterVnd,
    this.saleId = const Value.absent(),
    this.shiftId = const Value.absent(),
    required String recordedById,
    this.paymentMethod = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime clientCreatedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       customerId = Value(customerId),
       type = Value(type),
       amountVnd = Value(amountVnd),
       balanceAfterVnd = Value(balanceAfterVnd),
       recordedById = Value(recordedById),
       clientCreatedAt = Value(clientCreatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<DebtLedgerLocalData> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? customerId,
    Expression<String>? type,
    Expression<int>? amountVnd,
    Expression<int>? balanceAfterVnd,
    Expression<String>? saleId,
    Expression<String>? shiftId,
    Expression<String>? recordedById,
    Expression<String>? paymentMethod,
    Expression<String>? note,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (customerId != null) 'customer_id': customerId,
      if (type != null) 'type': type,
      if (amountVnd != null) 'amount_vnd': amountVnd,
      if (balanceAfterVnd != null) 'balance_after_vnd': balanceAfterVnd,
      if (saleId != null) 'sale_id': saleId,
      if (shiftId != null) 'shift_id': shiftId,
      if (recordedById != null) 'recorded_by_id': recordedById,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (note != null) 'note': note,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtLedgerLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? customerId,
    Value<String>? type,
    Value<int>? amountVnd,
    Value<int>? balanceAfterVnd,
    Value<String?>? saleId,
    Value<String?>? shiftId,
    Value<String>? recordedById,
    Value<String?>? paymentMethod,
    Value<String?>? note,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DebtLedgerLocalCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      amountVnd: amountVnd ?? this.amountVnd,
      balanceAfterVnd: balanceAfterVnd ?? this.balanceAfterVnd,
      saleId: saleId ?? this.saleId,
      shiftId: shiftId ?? this.shiftId,
      recordedById: recordedById ?? this.recordedById,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountVnd.present) {
      map['amount_vnd'] = Variable<int>(amountVnd.value);
    }
    if (balanceAfterVnd.present) {
      map['balance_after_vnd'] = Variable<int>(balanceAfterVnd.value);
    }
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (recordedById.present) {
      map['recorded_by_id'] = Variable<String>(recordedById.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (clientCreatedAt.present) {
      map['client_created_at'] = Variable<DateTime>(clientCreatedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtLedgerLocalCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('customerId: $customerId, ')
          ..write('type: $type, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('balanceAfterVnd: $balanceAfterVnd, ')
          ..write('saleId: $saleId, ')
          ..write('shiftId: $shiftId, ')
          ..write('recordedById: $recordedById, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('note: $note, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductStocksTable productStocks = $ProductStocksTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  late final $SalesLocalTable salesLocal = $SalesLocalTable(this);
  late final $SaleLinesLocalTable saleLinesLocal = $SaleLinesLocalTable(this);
  late final $ShiftsLocalTable shiftsLocal = $ShiftsLocalTable(this);
  late final $StoresLocalTable storesLocal = $StoresLocalTable(this);
  late final $MetaLocalTable metaLocal = $MetaLocalTable(this);
  late final $CustomersLocalTable customersLocal = $CustomersLocalTable(this);
  late final $DebtLedgerLocalTable debtLedgerLocal = $DebtLedgerLocalTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    products,
    productStocks,
    outboxEntries,
    salesLocal,
    saleLinesLocal,
    shiftsLocal,
    storesLocal,
    metaLocal,
    customersLocal,
    debtLedgerLocal,
  ];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String sku,
      Value<String?> barcode,
      required String name,
      required String unit,
      Value<bool> isWeighted,
      required int basePriceVnd,
      Value<int> costVnd,
      Value<bool> active,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> sku,
      Value<String?> barcode,
      Value<String> name,
      Value<String> unit,
      Value<bool> isWeighted,
      Value<int> basePriceVnd,
      Value<int> costVnd,
      Value<bool> active,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get basePriceVnd => $composableBuilder(
    column: $table.basePriceVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costVnd => $composableBuilder(
    column: $table.costVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get basePriceVnd => $composableBuilder(
    column: $table.basePriceVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costVnd => $composableBuilder(
    column: $table.costVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isWeighted => $composableBuilder(
    column: $table.isWeighted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get basePriceVnd => $composableBuilder(
    column: $table.basePriceVnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costVnd =>
      $composableBuilder(column: $table.costVnd, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> isWeighted = const Value.absent(),
                Value<int> basePriceVnd = const Value.absent(),
                Value<int> costVnd = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                sku: sku,
                barcode: barcode,
                name: name,
                unit: unit,
                isWeighted: isWeighted,
                basePriceVnd: basePriceVnd,
                costVnd: costVnd,
                active: active,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sku,
                Value<String?> barcode = const Value.absent(),
                required String name,
                required String unit,
                Value<bool> isWeighted = const Value.absent(),
                required int basePriceVnd,
                Value<int> costVnd = const Value.absent(),
                Value<bool> active = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                sku: sku,
                barcode: barcode,
                name: name,
                unit: unit,
                isWeighted: isWeighted,
                basePriceVnd: basePriceVnd,
                costVnd: costVnd,
                active: active,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$ProductStocksTableCreateCompanionBuilder =
    ProductStocksCompanion Function({
      required String productId,
      required String storeId,
      required String qty,
      required String minQty,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProductStocksTableUpdateCompanionBuilder =
    ProductStocksCompanion Function({
      Value<String> productId,
      Value<String> storeId,
      Value<String> qty,
      Value<String> minQty,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProductStocksTableFilterComposer
    extends Composer<_$AppDatabase, $ProductStocksTable> {
  $$ProductStocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get minQty => $composableBuilder(
    column: $table.minQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductStocksTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductStocksTable> {
  $$ProductStocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get minQty => $composableBuilder(
    column: $table.minQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductStocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductStocksTable> {
  $$ProductStocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get minQty =>
      $composableBuilder(column: $table.minQty, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductStocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductStocksTable,
          ProductStock,
          $$ProductStocksTableFilterComposer,
          $$ProductStocksTableOrderingComposer,
          $$ProductStocksTableAnnotationComposer,
          $$ProductStocksTableCreateCompanionBuilder,
          $$ProductStocksTableUpdateCompanionBuilder,
          (
            ProductStock,
            BaseReferences<_$AppDatabase, $ProductStocksTable, ProductStock>,
          ),
          ProductStock,
          PrefetchHooks Function()
        > {
  $$ProductStocksTableTableManager(_$AppDatabase db, $ProductStocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductStocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductStocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductStocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> qty = const Value.absent(),
                Value<String> minQty = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductStocksCompanion(
                productId: productId,
                storeId: storeId,
                qty: qty,
                minQty: minQty,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required String storeId,
                required String qty,
                required String minQty,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductStocksCompanion.insert(
                productId: productId,
                storeId: storeId,
                qty: qty,
                minQty: minQty,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductStocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductStocksTable,
      ProductStock,
      $$ProductStocksTableFilterComposer,
      $$ProductStocksTableOrderingComposer,
      $$ProductStocksTableAnnotationComposer,
      $$ProductStocksTableCreateCompanionBuilder,
      $$ProductStocksTableUpdateCompanionBuilder,
      (
        ProductStock,
        BaseReferences<_$AppDatabase, $ProductStocksTable, ProductStock>,
      ),
      ProductStock,
      PrefetchHooks Function()
    >;
typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      required String id,
      required String entityType,
      required String payloadJson,
      required DateTime createdAt,
      Value<String> status,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEntriesTable,
          OutboxEntry,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(_$AppDatabase db, $OutboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion(
                id: id,
                entityType: entityType,
                payloadJson: payloadJson,
                createdAt: createdAt,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String payloadJson,
                required DateTime createdAt,
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion.insert(
                id: id,
                entityType: entityType,
                payloadJson: payloadJson,
                createdAt: createdAt,
                status: status,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEntriesTable,
      OutboxEntry,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (
        OutboxEntry,
        BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>,
      ),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$SalesLocalTableCreateCompanionBuilder =
    SalesLocalCompanion Function({
      required String id,
      required String storeId,
      required String shiftId,
      required String paymentMethod,
      required int totalVnd,
      required int cashAmount,
      required int transferAmount,
      required int debtAmount,
      Value<String?> customerId,
      required DateTime clientCreatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$SalesLocalTableUpdateCompanionBuilder =
    SalesLocalCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> shiftId,
      Value<String> paymentMethod,
      Value<int> totalVnd,
      Value<int> cashAmount,
      Value<int> transferAmount,
      Value<int> debtAmount,
      Value<String?> customerId,
      Value<DateTime> clientCreatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$SalesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $SalesLocalTable> {
  $$SalesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalVnd => $composableBuilder(
    column: $table.totalVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transferAmount => $composableBuilder(
    column: $table.transferAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get debtAmount => $composableBuilder(
    column: $table.debtAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SalesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesLocalTable> {
  $$SalesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalVnd => $composableBuilder(
    column: $table.totalVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transferAmount => $composableBuilder(
    column: $table.transferAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get debtAmount => $composableBuilder(
    column: $table.debtAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SalesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesLocalTable> {
  $$SalesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalVnd =>
      $composableBuilder(column: $table.totalVnd, builder: (column) => column);

  GeneratedColumn<int> get cashAmount => $composableBuilder(
    column: $table.cashAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transferAmount => $composableBuilder(
    column: $table.transferAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get debtAmount => $composableBuilder(
    column: $table.debtAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$SalesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesLocalTable,
          SalesLocalData,
          $$SalesLocalTableFilterComposer,
          $$SalesLocalTableOrderingComposer,
          $$SalesLocalTableAnnotationComposer,
          $$SalesLocalTableCreateCompanionBuilder,
          $$SalesLocalTableUpdateCompanionBuilder,
          (
            SalesLocalData,
            BaseReferences<_$AppDatabase, $SalesLocalTable, SalesLocalData>,
          ),
          SalesLocalData,
          PrefetchHooks Function()
        > {
  $$SalesLocalTableTableManager(_$AppDatabase db, $SalesLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<int> totalVnd = const Value.absent(),
                Value<int> cashAmount = const Value.absent(),
                Value<int> transferAmount = const Value.absent(),
                Value<int> debtAmount = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesLocalCompanion(
                id: id,
                storeId: storeId,
                shiftId: shiftId,
                paymentMethod: paymentMethod,
                totalVnd: totalVnd,
                cashAmount: cashAmount,
                transferAmount: transferAmount,
                debtAmount: debtAmount,
                customerId: customerId,
                clientCreatedAt: clientCreatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String shiftId,
                required String paymentMethod,
                required int totalVnd,
                required int cashAmount,
                required int transferAmount,
                required int debtAmount,
                Value<String?> customerId = const Value.absent(),
                required DateTime clientCreatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesLocalCompanion.insert(
                id: id,
                storeId: storeId,
                shiftId: shiftId,
                paymentMethod: paymentMethod,
                totalVnd: totalVnd,
                cashAmount: cashAmount,
                transferAmount: transferAmount,
                debtAmount: debtAmount,
                customerId: customerId,
                clientCreatedAt: clientCreatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SalesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesLocalTable,
      SalesLocalData,
      $$SalesLocalTableFilterComposer,
      $$SalesLocalTableOrderingComposer,
      $$SalesLocalTableAnnotationComposer,
      $$SalesLocalTableCreateCompanionBuilder,
      $$SalesLocalTableUpdateCompanionBuilder,
      (
        SalesLocalData,
        BaseReferences<_$AppDatabase, $SalesLocalTable, SalesLocalData>,
      ),
      SalesLocalData,
      PrefetchHooks Function()
    >;
typedef $$SaleLinesLocalTableCreateCompanionBuilder =
    SaleLinesLocalCompanion Function({
      required String id,
      required String saleId,
      required String productId,
      required String qty,
      required int unitPrice,
      required int lineTotal,
      Value<int> rowid,
    });
typedef $$SaleLinesLocalTableUpdateCompanionBuilder =
    SaleLinesLocalCompanion Function({
      Value<String> id,
      Value<String> saleId,
      Value<String> productId,
      Value<String> qty,
      Value<int> unitPrice,
      Value<int> lineTotal,
      Value<int> rowid,
    });

class $$SaleLinesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $SaleLinesLocalTable> {
  $$SaleLinesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SaleLinesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleLinesLocalTable> {
  $$SaleLinesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SaleLinesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleLinesLocalTable> {
  $$SaleLinesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<int> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);
}

class $$SaleLinesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleLinesLocalTable,
          SaleLinesLocalData,
          $$SaleLinesLocalTableFilterComposer,
          $$SaleLinesLocalTableOrderingComposer,
          $$SaleLinesLocalTableAnnotationComposer,
          $$SaleLinesLocalTableCreateCompanionBuilder,
          $$SaleLinesLocalTableUpdateCompanionBuilder,
          (
            SaleLinesLocalData,
            BaseReferences<
              _$AppDatabase,
              $SaleLinesLocalTable,
              SaleLinesLocalData
            >,
          ),
          SaleLinesLocalData,
          PrefetchHooks Function()
        > {
  $$SaleLinesLocalTableTableManager(
    _$AppDatabase db,
    $SaleLinesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleLinesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleLinesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleLinesLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> saleId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> qty = const Value.absent(),
                Value<int> unitPrice = const Value.absent(),
                Value<int> lineTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SaleLinesLocalCompanion(
                id: id,
                saleId: saleId,
                productId: productId,
                qty: qty,
                unitPrice: unitPrice,
                lineTotal: lineTotal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String saleId,
                required String productId,
                required String qty,
                required int unitPrice,
                required int lineTotal,
                Value<int> rowid = const Value.absent(),
              }) => SaleLinesLocalCompanion.insert(
                id: id,
                saleId: saleId,
                productId: productId,
                qty: qty,
                unitPrice: unitPrice,
                lineTotal: lineTotal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SaleLinesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleLinesLocalTable,
      SaleLinesLocalData,
      $$SaleLinesLocalTableFilterComposer,
      $$SaleLinesLocalTableOrderingComposer,
      $$SaleLinesLocalTableAnnotationComposer,
      $$SaleLinesLocalTableCreateCompanionBuilder,
      $$SaleLinesLocalTableUpdateCompanionBuilder,
      (
        SaleLinesLocalData,
        BaseReferences<_$AppDatabase, $SaleLinesLocalTable, SaleLinesLocalData>,
      ),
      SaleLinesLocalData,
      PrefetchHooks Function()
    >;
typedef $$ShiftsLocalTableCreateCompanionBuilder =
    ShiftsLocalCompanion Function({
      required String id,
      required String storeId,
      required String userId,
      required DateTime openedAt,
      Value<DateTime?> closedAt,
      required int openingCash,
      Value<int?> closingCash,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$ShiftsLocalTableUpdateCompanionBuilder =
    ShiftsLocalCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> userId,
      Value<DateTime> openedAt,
      Value<DateTime?> closedAt,
      Value<int> openingCash,
      Value<int?> closingCash,
      Value<String?> note,
      Value<int> rowid,
    });

class $$ShiftsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftsLocalTable> {
  $$ShiftsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closingCash => $composableBuilder(
    column: $table.closingCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShiftsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftsLocalTable> {
  $$ShiftsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closingCash => $composableBuilder(
    column: $table.closingCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShiftsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftsLocalTable> {
  $$ShiftsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closingCash => $composableBuilder(
    column: $table.closingCash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$ShiftsLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftsLocalTable,
          ShiftsLocalData,
          $$ShiftsLocalTableFilterComposer,
          $$ShiftsLocalTableOrderingComposer,
          $$ShiftsLocalTableAnnotationComposer,
          $$ShiftsLocalTableCreateCompanionBuilder,
          $$ShiftsLocalTableUpdateCompanionBuilder,
          (
            ShiftsLocalData,
            BaseReferences<_$AppDatabase, $ShiftsLocalTable, ShiftsLocalData>,
          ),
          ShiftsLocalData,
          PrefetchHooks Function()
        > {
  $$ShiftsLocalTableTableManager(_$AppDatabase db, $ShiftsLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> openingCash = const Value.absent(),
                Value<int?> closingCash = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftsLocalCompanion(
                id: id,
                storeId: storeId,
                userId: userId,
                openedAt: openedAt,
                closedAt: closedAt,
                openingCash: openingCash,
                closingCash: closingCash,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String userId,
                required DateTime openedAt,
                Value<DateTime?> closedAt = const Value.absent(),
                required int openingCash,
                Value<int?> closingCash = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShiftsLocalCompanion.insert(
                id: id,
                storeId: storeId,
                userId: userId,
                openedAt: openedAt,
                closedAt: closedAt,
                openingCash: openingCash,
                closingCash: closingCash,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShiftsLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftsLocalTable,
      ShiftsLocalData,
      $$ShiftsLocalTableFilterComposer,
      $$ShiftsLocalTableOrderingComposer,
      $$ShiftsLocalTableAnnotationComposer,
      $$ShiftsLocalTableCreateCompanionBuilder,
      $$ShiftsLocalTableUpdateCompanionBuilder,
      (
        ShiftsLocalData,
        BaseReferences<_$AppDatabase, $ShiftsLocalTable, ShiftsLocalData>,
      ),
      ShiftsLocalData,
      PrefetchHooks Function()
    >;
typedef $$StoresLocalTableCreateCompanionBuilder =
    StoresLocalCompanion Function({
      required String id,
      required String code,
      required String name,
      Value<bool> active,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StoresLocalTableUpdateCompanionBuilder =
    StoresLocalCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<bool> active,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StoresLocalTableFilterComposer
    extends Composer<_$AppDatabase, $StoresLocalTable> {
  $$StoresLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoresLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $StoresLocalTable> {
  $$StoresLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoresLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoresLocalTable> {
  $$StoresLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StoresLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoresLocalTable,
          StoresLocalData,
          $$StoresLocalTableFilterComposer,
          $$StoresLocalTableOrderingComposer,
          $$StoresLocalTableAnnotationComposer,
          $$StoresLocalTableCreateCompanionBuilder,
          $$StoresLocalTableUpdateCompanionBuilder,
          (
            StoresLocalData,
            BaseReferences<_$AppDatabase, $StoresLocalTable, StoresLocalData>,
          ),
          StoresLocalData,
          PrefetchHooks Function()
        > {
  $$StoresLocalTableTableManager(_$AppDatabase db, $StoresLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoresLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoresLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoresLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresLocalCompanion(
                id: id,
                code: code,
                name: name,
                active: active,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                Value<bool> active = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StoresLocalCompanion.insert(
                id: id,
                code: code,
                name: name,
                active: active,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoresLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoresLocalTable,
      StoresLocalData,
      $$StoresLocalTableFilterComposer,
      $$StoresLocalTableOrderingComposer,
      $$StoresLocalTableAnnotationComposer,
      $$StoresLocalTableCreateCompanionBuilder,
      $$StoresLocalTableUpdateCompanionBuilder,
      (
        StoresLocalData,
        BaseReferences<_$AppDatabase, $StoresLocalTable, StoresLocalData>,
      ),
      StoresLocalData,
      PrefetchHooks Function()
    >;
typedef $$MetaLocalTableCreateCompanionBuilder =
    MetaLocalCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MetaLocalTableUpdateCompanionBuilder =
    MetaLocalCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MetaLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MetaLocalTable> {
  $$MetaLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MetaLocalTable> {
  $$MetaLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaLocalTable> {
  $$MetaLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MetaLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetaLocalTable,
          MetaLocalData,
          $$MetaLocalTableFilterComposer,
          $$MetaLocalTableOrderingComposer,
          $$MetaLocalTableAnnotationComposer,
          $$MetaLocalTableCreateCompanionBuilder,
          $$MetaLocalTableUpdateCompanionBuilder,
          (
            MetaLocalData,
            BaseReferences<_$AppDatabase, $MetaLocalTable, MetaLocalData>,
          ),
          MetaLocalData,
          PrefetchHooks Function()
        > {
  $$MetaLocalTableTableManager(_$AppDatabase db, $MetaLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaLocalCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetaLocalCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetaLocalTable,
      MetaLocalData,
      $$MetaLocalTableFilterComposer,
      $$MetaLocalTableOrderingComposer,
      $$MetaLocalTableAnnotationComposer,
      $$MetaLocalTableCreateCompanionBuilder,
      $$MetaLocalTableUpdateCompanionBuilder,
      (
        MetaLocalData,
        BaseReferences<_$AppDatabase, $MetaLocalTable, MetaLocalData>,
      ),
      MetaLocalData,
      PrefetchHooks Function()
    >;
typedef $$CustomersLocalTableCreateCompanionBuilder =
    CustomersLocalCompanion Function({
      required String id,
      required String name,
      Value<String?> phone,
      Value<int> balanceVnd,
      Value<int?> creditLimitVnd,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CustomersLocalTableUpdateCompanionBuilder =
    CustomersLocalCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> phone,
      Value<int> balanceVnd,
      Value<int?> creditLimitVnd,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CustomersLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersLocalTable> {
  $$CustomersLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceVnd => $composableBuilder(
    column: $table.balanceVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimitVnd => $composableBuilder(
    column: $table.creditLimitVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersLocalTable> {
  $$CustomersLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceVnd => $composableBuilder(
    column: $table.balanceVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimitVnd => $composableBuilder(
    column: $table.creditLimitVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersLocalTable> {
  $$CustomersLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<int> get balanceVnd => $composableBuilder(
    column: $table.balanceVnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditLimitVnd => $composableBuilder(
    column: $table.creditLimitVnd,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomersLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersLocalTable,
          CustomersLocalData,
          $$CustomersLocalTableFilterComposer,
          $$CustomersLocalTableOrderingComposer,
          $$CustomersLocalTableAnnotationComposer,
          $$CustomersLocalTableCreateCompanionBuilder,
          $$CustomersLocalTableUpdateCompanionBuilder,
          (
            CustomersLocalData,
            BaseReferences<
              _$AppDatabase,
              $CustomersLocalTable,
              CustomersLocalData
            >,
          ),
          CustomersLocalData,
          PrefetchHooks Function()
        > {
  $$CustomersLocalTableTableManager(
    _$AppDatabase db,
    $CustomersLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<int> balanceVnd = const Value.absent(),
                Value<int?> creditLimitVnd = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersLocalCompanion(
                id: id,
                name: name,
                phone: phone,
                balanceVnd: balanceVnd,
                creditLimitVnd: creditLimitVnd,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<int> balanceVnd = const Value.absent(),
                Value<int?> creditLimitVnd = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomersLocalCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                balanceVnd: balanceVnd,
                creditLimitVnd: creditLimitVnd,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersLocalTable,
      CustomersLocalData,
      $$CustomersLocalTableFilterComposer,
      $$CustomersLocalTableOrderingComposer,
      $$CustomersLocalTableAnnotationComposer,
      $$CustomersLocalTableCreateCompanionBuilder,
      $$CustomersLocalTableUpdateCompanionBuilder,
      (
        CustomersLocalData,
        BaseReferences<_$AppDatabase, $CustomersLocalTable, CustomersLocalData>,
      ),
      CustomersLocalData,
      PrefetchHooks Function()
    >;
typedef $$DebtLedgerLocalTableCreateCompanionBuilder =
    DebtLedgerLocalCompanion Function({
      required String id,
      required String storeId,
      required String customerId,
      required String type,
      required int amountVnd,
      required int balanceAfterVnd,
      Value<String?> saleId,
      Value<String?> shiftId,
      required String recordedById,
      Value<String?> paymentMethod,
      Value<String?> note,
      required DateTime clientCreatedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DebtLedgerLocalTableUpdateCompanionBuilder =
    DebtLedgerLocalCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> customerId,
      Value<String> type,
      Value<int> amountVnd,
      Value<int> balanceAfterVnd,
      Value<String?> saleId,
      Value<String?> shiftId,
      Value<String> recordedById,
      Value<String?> paymentMethod,
      Value<String?> note,
      Value<DateTime> clientCreatedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DebtLedgerLocalTableFilterComposer
    extends Composer<_$AppDatabase, $DebtLedgerLocalTable> {
  $$DebtLedgerLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountVnd => $composableBuilder(
    column: $table.amountVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceAfterVnd => $composableBuilder(
    column: $table.balanceAfterVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DebtLedgerLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtLedgerLocalTable> {
  $$DebtLedgerLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountVnd => $composableBuilder(
    column: $table.amountVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceAfterVnd => $composableBuilder(
    column: $table.balanceAfterVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtLedgerLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtLedgerLocalTable> {
  $$DebtLedgerLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountVnd =>
      $composableBuilder(column: $table.amountVnd, builder: (column) => column);

  GeneratedColumn<int> get balanceAfterVnd => $composableBuilder(
    column: $table.balanceAfterVnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DebtLedgerLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtLedgerLocalTable,
          DebtLedgerLocalData,
          $$DebtLedgerLocalTableFilterComposer,
          $$DebtLedgerLocalTableOrderingComposer,
          $$DebtLedgerLocalTableAnnotationComposer,
          $$DebtLedgerLocalTableCreateCompanionBuilder,
          $$DebtLedgerLocalTableUpdateCompanionBuilder,
          (
            DebtLedgerLocalData,
            BaseReferences<
              _$AppDatabase,
              $DebtLedgerLocalTable,
              DebtLedgerLocalData
            >,
          ),
          DebtLedgerLocalData,
          PrefetchHooks Function()
        > {
  $$DebtLedgerLocalTableTableManager(
    _$AppDatabase db,
    $DebtLedgerLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtLedgerLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtLedgerLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtLedgerLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountVnd = const Value.absent(),
                Value<int> balanceAfterVnd = const Value.absent(),
                Value<String?> saleId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                Value<String> recordedById = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtLedgerLocalCompanion(
                id: id,
                storeId: storeId,
                customerId: customerId,
                type: type,
                amountVnd: amountVnd,
                balanceAfterVnd: balanceAfterVnd,
                saleId: saleId,
                shiftId: shiftId,
                recordedById: recordedById,
                paymentMethod: paymentMethod,
                note: note,
                clientCreatedAt: clientCreatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String customerId,
                required String type,
                required int amountVnd,
                required int balanceAfterVnd,
                Value<String?> saleId = const Value.absent(),
                Value<String?> shiftId = const Value.absent(),
                required String recordedById,
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime clientCreatedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DebtLedgerLocalCompanion.insert(
                id: id,
                storeId: storeId,
                customerId: customerId,
                type: type,
                amountVnd: amountVnd,
                balanceAfterVnd: balanceAfterVnd,
                saleId: saleId,
                shiftId: shiftId,
                recordedById: recordedById,
                paymentMethod: paymentMethod,
                note: note,
                clientCreatedAt: clientCreatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DebtLedgerLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtLedgerLocalTable,
      DebtLedgerLocalData,
      $$DebtLedgerLocalTableFilterComposer,
      $$DebtLedgerLocalTableOrderingComposer,
      $$DebtLedgerLocalTableAnnotationComposer,
      $$DebtLedgerLocalTableCreateCompanionBuilder,
      $$DebtLedgerLocalTableUpdateCompanionBuilder,
      (
        DebtLedgerLocalData,
        BaseReferences<
          _$AppDatabase,
          $DebtLedgerLocalTable,
          DebtLedgerLocalData
        >,
      ),
      DebtLedgerLocalData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductStocksTableTableManager get productStocks =>
      $$ProductStocksTableTableManager(_db, _db.productStocks);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
  $$SalesLocalTableTableManager get salesLocal =>
      $$SalesLocalTableTableManager(_db, _db.salesLocal);
  $$SaleLinesLocalTableTableManager get saleLinesLocal =>
      $$SaleLinesLocalTableTableManager(_db, _db.saleLinesLocal);
  $$ShiftsLocalTableTableManager get shiftsLocal =>
      $$ShiftsLocalTableTableManager(_db, _db.shiftsLocal);
  $$StoresLocalTableTableManager get storesLocal =>
      $$StoresLocalTableTableManager(_db, _db.storesLocal);
  $$MetaLocalTableTableManager get metaLocal =>
      $$MetaLocalTableTableManager(_db, _db.metaLocal);
  $$CustomersLocalTableTableManager get customersLocal =>
      $$CustomersLocalTableTableManager(_db, _db.customersLocal);
  $$DebtLedgerLocalTableTableManager get debtLedgerLocal =>
      $$DebtLedgerLocalTableTableManager(_db, _db.debtLedgerLocal);
}
