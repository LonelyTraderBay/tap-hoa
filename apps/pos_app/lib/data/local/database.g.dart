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
  static const VerificationMeta _expectedCashVndMeta = const VerificationMeta(
    'expectedCashVnd',
  );
  @override
  late final GeneratedColumn<int> expectedCashVnd = GeneratedColumn<int>(
    'expected_cash_vnd',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _varianceVndMeta = const VerificationMeta(
    'varianceVnd',
  );
  @override
  late final GeneratedColumn<int> varianceVnd = GeneratedColumn<int>(
    'variance_vnd',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transferInShiftVndMeta =
      const VerificationMeta('transferInShiftVnd');
  @override
  late final GeneratedColumn<int> transferInShiftVnd = GeneratedColumn<int>(
    'transfer_in_shift_vnd',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    expectedCashVnd,
    varianceVnd,
    transferInShiftVnd,
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
    if (data.containsKey('expected_cash_vnd')) {
      context.handle(
        _expectedCashVndMeta,
        expectedCashVnd.isAcceptableOrUnknown(
          data['expected_cash_vnd']!,
          _expectedCashVndMeta,
        ),
      );
    }
    if (data.containsKey('variance_vnd')) {
      context.handle(
        _varianceVndMeta,
        varianceVnd.isAcceptableOrUnknown(
          data['variance_vnd']!,
          _varianceVndMeta,
        ),
      );
    }
    if (data.containsKey('transfer_in_shift_vnd')) {
      context.handle(
        _transferInShiftVndMeta,
        transferInShiftVnd.isAcceptableOrUnknown(
          data['transfer_in_shift_vnd']!,
          _transferInShiftVndMeta,
        ),
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
      expectedCashVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_cash_vnd'],
      ),
      varianceVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}variance_vnd'],
      ),
      transferInShiftVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transfer_in_shift_vnd'],
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
  final int? expectedCashVnd;
  final int? varianceVnd;
  final int? transferInShiftVnd;
  const ShiftsLocalData({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.closingCash,
    this.note,
    this.expectedCashVnd,
    this.varianceVnd,
    this.transferInShiftVnd,
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
    if (!nullToAbsent || expectedCashVnd != null) {
      map['expected_cash_vnd'] = Variable<int>(expectedCashVnd);
    }
    if (!nullToAbsent || varianceVnd != null) {
      map['variance_vnd'] = Variable<int>(varianceVnd);
    }
    if (!nullToAbsent || transferInShiftVnd != null) {
      map['transfer_in_shift_vnd'] = Variable<int>(transferInShiftVnd);
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
      expectedCashVnd: expectedCashVnd == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCashVnd),
      varianceVnd: varianceVnd == null && nullToAbsent
          ? const Value.absent()
          : Value(varianceVnd),
      transferInShiftVnd: transferInShiftVnd == null && nullToAbsent
          ? const Value.absent()
          : Value(transferInShiftVnd),
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
      expectedCashVnd: serializer.fromJson<int?>(json['expectedCashVnd']),
      varianceVnd: serializer.fromJson<int?>(json['varianceVnd']),
      transferInShiftVnd: serializer.fromJson<int?>(json['transferInShiftVnd']),
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
      'expectedCashVnd': serializer.toJson<int?>(expectedCashVnd),
      'varianceVnd': serializer.toJson<int?>(varianceVnd),
      'transferInShiftVnd': serializer.toJson<int?>(transferInShiftVnd),
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
    Value<int?> expectedCashVnd = const Value.absent(),
    Value<int?> varianceVnd = const Value.absent(),
    Value<int?> transferInShiftVnd = const Value.absent(),
  }) => ShiftsLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    userId: userId ?? this.userId,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    openingCash: openingCash ?? this.openingCash,
    closingCash: closingCash.present ? closingCash.value : this.closingCash,
    note: note.present ? note.value : this.note,
    expectedCashVnd: expectedCashVnd.present
        ? expectedCashVnd.value
        : this.expectedCashVnd,
    varianceVnd: varianceVnd.present ? varianceVnd.value : this.varianceVnd,
    transferInShiftVnd: transferInShiftVnd.present
        ? transferInShiftVnd.value
        : this.transferInShiftVnd,
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
      expectedCashVnd: data.expectedCashVnd.present
          ? data.expectedCashVnd.value
          : this.expectedCashVnd,
      varianceVnd: data.varianceVnd.present
          ? data.varianceVnd.value
          : this.varianceVnd,
      transferInShiftVnd: data.transferInShiftVnd.present
          ? data.transferInShiftVnd.value
          : this.transferInShiftVnd,
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
          ..write('note: $note, ')
          ..write('expectedCashVnd: $expectedCashVnd, ')
          ..write('varianceVnd: $varianceVnd, ')
          ..write('transferInShiftVnd: $transferInShiftVnd')
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
    expectedCashVnd,
    varianceVnd,
    transferInShiftVnd,
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
          other.note == this.note &&
          other.expectedCashVnd == this.expectedCashVnd &&
          other.varianceVnd == this.varianceVnd &&
          other.transferInShiftVnd == this.transferInShiftVnd);
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
  final Value<int?> expectedCashVnd;
  final Value<int?> varianceVnd;
  final Value<int?> transferInShiftVnd;
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
    this.expectedCashVnd = const Value.absent(),
    this.varianceVnd = const Value.absent(),
    this.transferInShiftVnd = const Value.absent(),
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
    this.expectedCashVnd = const Value.absent(),
    this.varianceVnd = const Value.absent(),
    this.transferInShiftVnd = const Value.absent(),
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
    Expression<int>? expectedCashVnd,
    Expression<int>? varianceVnd,
    Expression<int>? transferInShiftVnd,
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
      if (expectedCashVnd != null) 'expected_cash_vnd': expectedCashVnd,
      if (varianceVnd != null) 'variance_vnd': varianceVnd,
      if (transferInShiftVnd != null)
        'transfer_in_shift_vnd': transferInShiftVnd,
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
    Value<int?>? expectedCashVnd,
    Value<int?>? varianceVnd,
    Value<int?>? transferInShiftVnd,
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
      expectedCashVnd: expectedCashVnd ?? this.expectedCashVnd,
      varianceVnd: varianceVnd ?? this.varianceVnd,
      transferInShiftVnd: transferInShiftVnd ?? this.transferInShiftVnd,
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
    if (expectedCashVnd.present) {
      map['expected_cash_vnd'] = Variable<int>(expectedCashVnd.value);
    }
    if (varianceVnd.present) {
      map['variance_vnd'] = Variable<int>(varianceVnd.value);
    }
    if (transferInShiftVnd.present) {
      map['transfer_in_shift_vnd'] = Variable<int>(transferInShiftVnd.value);
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
          ..write('expectedCashVnd: $expectedCashVnd, ')
          ..write('varianceVnd: $varianceVnd, ')
          ..write('transferInShiftVnd: $transferInShiftVnd, ')
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

class $CashCategoriesLocalTable extends CashCategoriesLocal
    with TableInfo<$CashCategoriesLocalTable, CashCategoriesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashCategoriesLocalTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, code, name, direction, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_categories_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashCategoriesLocalData> instance, {
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
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashCategoriesLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashCategoriesLocalData(
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
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CashCategoriesLocalTable createAlias(String alias) {
    return $CashCategoriesLocalTable(attachedDatabase, alias);
  }
}

class CashCategoriesLocalData extends DataClass
    implements Insertable<CashCategoriesLocalData> {
  final String id;
  final String code;
  final String name;
  final String direction;
  final int sortOrder;
  const CashCategoriesLocalData({
    required this.id,
    required this.code,
    required this.name,
    required this.direction,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['direction'] = Variable<String>(direction);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CashCategoriesLocalCompanion toCompanion(bool nullToAbsent) {
    return CashCategoriesLocalCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      direction: Value(direction),
      sortOrder: Value(sortOrder),
    );
  }

  factory CashCategoriesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashCategoriesLocalData(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      direction: serializer.fromJson<String>(json['direction']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'direction': serializer.toJson<String>(direction),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CashCategoriesLocalData copyWith({
    String? id,
    String? code,
    String? name,
    String? direction,
    int? sortOrder,
  }) => CashCategoriesLocalData(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    direction: direction ?? this.direction,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CashCategoriesLocalData copyWithCompanion(CashCategoriesLocalCompanion data) {
    return CashCategoriesLocalData(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      direction: data.direction.present ? data.direction.value : this.direction,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashCategoriesLocalData(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('direction: $direction, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, direction, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashCategoriesLocalData &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.direction == this.direction &&
          other.sortOrder == this.sortOrder);
}

class CashCategoriesLocalCompanion
    extends UpdateCompanion<CashCategoriesLocalData> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> direction;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CashCategoriesLocalCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.direction = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashCategoriesLocalCompanion.insert({
    required String id,
    required String code,
    required String name,
    required String direction,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       direction = Value(direction);
  static Insertable<CashCategoriesLocalData> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? direction,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (direction != null) 'direction': direction,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashCategoriesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? direction,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CashCategoriesLocalCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashCategoriesLocalCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('direction: $direction, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashVouchersLocalTable extends CashVouchersLocal
    with TableInfo<$CashVouchersLocalTable, CashVouchersLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashVouchersLocalTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    shiftId,
    categoryId,
    direction,
    channel,
    amountVnd,
    note,
    recordedById,
    clientCreatedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_vouchers_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashVouchersLocalData> instance, {
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
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('amount_vnd')) {
      context.handle(
        _amountVndMeta,
        amountVnd.isAcceptableOrUnknown(data['amount_vnd']!, _amountVndMeta),
      );
    } else if (isInserting) {
      context.missing(_amountVndMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  CashVouchersLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashVouchersLocalData(
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
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      amountVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_vnd'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      recordedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_id'],
      )!,
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
  $CashVouchersLocalTable createAlias(String alias) {
    return $CashVouchersLocalTable(attachedDatabase, alias);
  }
}

class CashVouchersLocalData extends DataClass
    implements Insertable<CashVouchersLocalData> {
  final String id;
  final String storeId;
  final String shiftId;
  final String categoryId;
  final String direction;
  final String channel;
  final int amountVnd;
  final String? note;
  final String recordedById;
  final DateTime clientCreatedAt;
  final DateTime updatedAt;
  const CashVouchersLocalData({
    required this.id,
    required this.storeId,
    required this.shiftId,
    required this.categoryId,
    required this.direction,
    required this.channel,
    required this.amountVnd,
    this.note,
    required this.recordedById,
    required this.clientCreatedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['shift_id'] = Variable<String>(shiftId);
    map['category_id'] = Variable<String>(categoryId);
    map['direction'] = Variable<String>(direction);
    map['channel'] = Variable<String>(channel);
    map['amount_vnd'] = Variable<int>(amountVnd);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['recorded_by_id'] = Variable<String>(recordedById);
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CashVouchersLocalCompanion toCompanion(bool nullToAbsent) {
    return CashVouchersLocalCompanion(
      id: Value(id),
      storeId: Value(storeId),
      shiftId: Value(shiftId),
      categoryId: Value(categoryId),
      direction: Value(direction),
      channel: Value(channel),
      amountVnd: Value(amountVnd),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      recordedById: Value(recordedById),
      clientCreatedAt: Value(clientCreatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CashVouchersLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashVouchersLocalData(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      direction: serializer.fromJson<String>(json['direction']),
      channel: serializer.fromJson<String>(json['channel']),
      amountVnd: serializer.fromJson<int>(json['amountVnd']),
      note: serializer.fromJson<String?>(json['note']),
      recordedById: serializer.fromJson<String>(json['recordedById']),
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
      'shiftId': serializer.toJson<String>(shiftId),
      'categoryId': serializer.toJson<String>(categoryId),
      'direction': serializer.toJson<String>(direction),
      'channel': serializer.toJson<String>(channel),
      'amountVnd': serializer.toJson<int>(amountVnd),
      'note': serializer.toJson<String?>(note),
      'recordedById': serializer.toJson<String>(recordedById),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CashVouchersLocalData copyWith({
    String? id,
    String? storeId,
    String? shiftId,
    String? categoryId,
    String? direction,
    String? channel,
    int? amountVnd,
    Value<String?> note = const Value.absent(),
    String? recordedById,
    DateTime? clientCreatedAt,
    DateTime? updatedAt,
  }) => CashVouchersLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    shiftId: shiftId ?? this.shiftId,
    categoryId: categoryId ?? this.categoryId,
    direction: direction ?? this.direction,
    channel: channel ?? this.channel,
    amountVnd: amountVnd ?? this.amountVnd,
    note: note.present ? note.value : this.note,
    recordedById: recordedById ?? this.recordedById,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CashVouchersLocalData copyWithCompanion(CashVouchersLocalCompanion data) {
    return CashVouchersLocalData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      direction: data.direction.present ? data.direction.value : this.direction,
      channel: data.channel.present ? data.channel.value : this.channel,
      amountVnd: data.amountVnd.present ? data.amountVnd.value : this.amountVnd,
      note: data.note.present ? data.note.value : this.note,
      recordedById: data.recordedById.present
          ? data.recordedById.value
          : this.recordedById,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashVouchersLocalData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('shiftId: $shiftId, ')
          ..write('categoryId: $categoryId, ')
          ..write('direction: $direction, ')
          ..write('channel: $channel, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('note: $note, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    shiftId,
    categoryId,
    direction,
    channel,
    amountVnd,
    note,
    recordedById,
    clientCreatedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashVouchersLocalData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.shiftId == this.shiftId &&
          other.categoryId == this.categoryId &&
          other.direction == this.direction &&
          other.channel == this.channel &&
          other.amountVnd == this.amountVnd &&
          other.note == this.note &&
          other.recordedById == this.recordedById &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.updatedAt == this.updatedAt);
}

class CashVouchersLocalCompanion
    extends UpdateCompanion<CashVouchersLocalData> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> shiftId;
  final Value<String> categoryId;
  final Value<String> direction;
  final Value<String> channel;
  final Value<int> amountVnd;
  final Value<String?> note;
  final Value<String> recordedById;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CashVouchersLocalCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.direction = const Value.absent(),
    this.channel = const Value.absent(),
    this.amountVnd = const Value.absent(),
    this.note = const Value.absent(),
    this.recordedById = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashVouchersLocalCompanion.insert({
    required String id,
    required String storeId,
    required String shiftId,
    required String categoryId,
    required String direction,
    required String channel,
    required int amountVnd,
    this.note = const Value.absent(),
    required String recordedById,
    required DateTime clientCreatedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       shiftId = Value(shiftId),
       categoryId = Value(categoryId),
       direction = Value(direction),
       channel = Value(channel),
       amountVnd = Value(amountVnd),
       recordedById = Value(recordedById),
       clientCreatedAt = Value(clientCreatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<CashVouchersLocalData> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? shiftId,
    Expression<String>? categoryId,
    Expression<String>? direction,
    Expression<String>? channel,
    Expression<int>? amountVnd,
    Expression<String>? note,
    Expression<String>? recordedById,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (shiftId != null) 'shift_id': shiftId,
      if (categoryId != null) 'category_id': categoryId,
      if (direction != null) 'direction': direction,
      if (channel != null) 'channel': channel,
      if (amountVnd != null) 'amount_vnd': amountVnd,
      if (note != null) 'note': note,
      if (recordedById != null) 'recorded_by_id': recordedById,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashVouchersLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? shiftId,
    Value<String>? categoryId,
    Value<String>? direction,
    Value<String>? channel,
    Value<int>? amountVnd,
    Value<String?>? note,
    Value<String>? recordedById,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CashVouchersLocalCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      shiftId: shiftId ?? this.shiftId,
      categoryId: categoryId ?? this.categoryId,
      direction: direction ?? this.direction,
      channel: channel ?? this.channel,
      amountVnd: amountVnd ?? this.amountVnd,
      note: note ?? this.note,
      recordedById: recordedById ?? this.recordedById,
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
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (amountVnd.present) {
      map['amount_vnd'] = Variable<int>(amountVnd.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (recordedById.present) {
      map['recorded_by_id'] = Variable<String>(recordedById.value);
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
    return (StringBuffer('CashVouchersLocalCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('shiftId: $shiftId, ')
          ..write('categoryId: $categoryId, ')
          ..write('direction: $direction, ')
          ..write('channel: $channel, ')
          ..write('amountVnd: $amountVnd, ')
          ..write('note: $note, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockTransfersLocalTable extends StockTransfersLocal
    with TableInfo<$StockTransfersLocalTable, StockTransfersLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockTransfersLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromStoreIdMeta = const VerificationMeta(
    'fromStoreId',
  );
  @override
  late final GeneratedColumn<String> fromStoreId = GeneratedColumn<String>(
    'from_store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toStoreIdMeta = const VerificationMeta(
    'toStoreId',
  );
  @override
  late final GeneratedColumn<String> toStoreId = GeneratedColumn<String>(
    'to_store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _createdByIdMeta = const VerificationMeta(
    'createdById',
  );
  @override
  late final GeneratedColumn<String> createdById = GeneratedColumn<String>(
    'created_by_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedByIdMeta = const VerificationMeta(
    'approvedById',
  );
  @override
  late final GeneratedColumn<String> approvedById = GeneratedColumn<String>(
    'approved_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedByIdMeta = const VerificationMeta(
    'receivedById',
  );
  @override
  late final GeneratedColumn<String> receivedById = GeneratedColumn<String>(
    'received_by_id',
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
  static const VerificationMeta _approvedAtMeta = const VerificationMeta(
    'approvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> approvedAt = GeneratedColumn<DateTime>(
    'approved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    fromStoreId,
    toStoreId,
    status,
    note,
    createdById,
    approvedById,
    receivedById,
    clientCreatedAt,
    approvedAt,
    receivedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_transfers_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockTransfersLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_store_id')) {
      context.handle(
        _fromStoreIdMeta,
        fromStoreId.isAcceptableOrUnknown(
          data['from_store_id']!,
          _fromStoreIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromStoreIdMeta);
    }
    if (data.containsKey('to_store_id')) {
      context.handle(
        _toStoreIdMeta,
        toStoreId.isAcceptableOrUnknown(data['to_store_id']!, _toStoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toStoreIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_by_id')) {
      context.handle(
        _createdByIdMeta,
        createdById.isAcceptableOrUnknown(
          data['created_by_id']!,
          _createdByIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByIdMeta);
    }
    if (data.containsKey('approved_by_id')) {
      context.handle(
        _approvedByIdMeta,
        approvedById.isAcceptableOrUnknown(
          data['approved_by_id']!,
          _approvedByIdMeta,
        ),
      );
    }
    if (data.containsKey('received_by_id')) {
      context.handle(
        _receivedByIdMeta,
        receivedById.isAcceptableOrUnknown(
          data['received_by_id']!,
          _receivedByIdMeta,
        ),
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
    if (data.containsKey('approved_at')) {
      context.handle(
        _approvedAtMeta,
        approvedAt.isAcceptableOrUnknown(data['approved_at']!, _approvedAtMeta),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
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
  StockTransfersLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockTransfersLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fromStoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_store_id'],
      )!,
      toStoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_store_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_id'],
      )!,
      approvedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by_id'],
      ),
      receivedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}received_by_id'],
      ),
      clientCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_created_at'],
      )!,
      approvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}approved_at'],
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StockTransfersLocalTable createAlias(String alias) {
    return $StockTransfersLocalTable(attachedDatabase, alias);
  }
}

class StockTransfersLocalData extends DataClass
    implements Insertable<StockTransfersLocalData> {
  final String id;
  final String fromStoreId;
  final String toStoreId;
  final String status;
  final String? note;
  final String createdById;
  final String? approvedById;
  final String? receivedById;
  final DateTime clientCreatedAt;
  final DateTime? approvedAt;
  final DateTime? receivedAt;
  final DateTime updatedAt;
  const StockTransfersLocalData({
    required this.id,
    required this.fromStoreId,
    required this.toStoreId,
    required this.status,
    this.note,
    required this.createdById,
    this.approvedById,
    this.receivedById,
    required this.clientCreatedAt,
    this.approvedAt,
    this.receivedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_store_id'] = Variable<String>(fromStoreId);
    map['to_store_id'] = Variable<String>(toStoreId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_by_id'] = Variable<String>(createdById);
    if (!nullToAbsent || approvedById != null) {
      map['approved_by_id'] = Variable<String>(approvedById);
    }
    if (!nullToAbsent || receivedById != null) {
      map['received_by_id'] = Variable<String>(receivedById);
    }
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    if (!nullToAbsent || approvedAt != null) {
      map['approved_at'] = Variable<DateTime>(approvedAt);
    }
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<DateTime>(receivedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StockTransfersLocalCompanion toCompanion(bool nullToAbsent) {
    return StockTransfersLocalCompanion(
      id: Value(id),
      fromStoreId: Value(fromStoreId),
      toStoreId: Value(toStoreId),
      status: Value(status),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdById: Value(createdById),
      approvedById: approvedById == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedById),
      receivedById: receivedById == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedById),
      clientCreatedAt: Value(clientCreatedAt),
      approvedAt: approvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedAt),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StockTransfersLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockTransfersLocalData(
      id: serializer.fromJson<String>(json['id']),
      fromStoreId: serializer.fromJson<String>(json['fromStoreId']),
      toStoreId: serializer.fromJson<String>(json['toStoreId']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String?>(json['note']),
      createdById: serializer.fromJson<String>(json['createdById']),
      approvedById: serializer.fromJson<String?>(json['approvedById']),
      receivedById: serializer.fromJson<String?>(json['receivedById']),
      clientCreatedAt: serializer.fromJson<DateTime>(json['clientCreatedAt']),
      approvedAt: serializer.fromJson<DateTime?>(json['approvedAt']),
      receivedAt: serializer.fromJson<DateTime?>(json['receivedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromStoreId': serializer.toJson<String>(fromStoreId),
      'toStoreId': serializer.toJson<String>(toStoreId),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String?>(note),
      'createdById': serializer.toJson<String>(createdById),
      'approvedById': serializer.toJson<String?>(approvedById),
      'receivedById': serializer.toJson<String?>(receivedById),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'approvedAt': serializer.toJson<DateTime?>(approvedAt),
      'receivedAt': serializer.toJson<DateTime?>(receivedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StockTransfersLocalData copyWith({
    String? id,
    String? fromStoreId,
    String? toStoreId,
    String? status,
    Value<String?> note = const Value.absent(),
    String? createdById,
    Value<String?> approvedById = const Value.absent(),
    Value<String?> receivedById = const Value.absent(),
    DateTime? clientCreatedAt,
    Value<DateTime?> approvedAt = const Value.absent(),
    Value<DateTime?> receivedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => StockTransfersLocalData(
    id: id ?? this.id,
    fromStoreId: fromStoreId ?? this.fromStoreId,
    toStoreId: toStoreId ?? this.toStoreId,
    status: status ?? this.status,
    note: note.present ? note.value : this.note,
    createdById: createdById ?? this.createdById,
    approvedById: approvedById.present ? approvedById.value : this.approvedById,
    receivedById: receivedById.present ? receivedById.value : this.receivedById,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    approvedAt: approvedAt.present ? approvedAt.value : this.approvedAt,
    receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StockTransfersLocalData copyWithCompanion(StockTransfersLocalCompanion data) {
    return StockTransfersLocalData(
      id: data.id.present ? data.id.value : this.id,
      fromStoreId: data.fromStoreId.present
          ? data.fromStoreId.value
          : this.fromStoreId,
      toStoreId: data.toStoreId.present ? data.toStoreId.value : this.toStoreId,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      createdById: data.createdById.present
          ? data.createdById.value
          : this.createdById,
      approvedById: data.approvedById.present
          ? data.approvedById.value
          : this.approvedById,
      receivedById: data.receivedById.present
          ? data.receivedById.value
          : this.receivedById,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      approvedAt: data.approvedAt.present
          ? data.approvedAt.value
          : this.approvedAt,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockTransfersLocalData(')
          ..write('id: $id, ')
          ..write('fromStoreId: $fromStoreId, ')
          ..write('toStoreId: $toStoreId, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdById: $createdById, ')
          ..write('approvedById: $approvedById, ')
          ..write('receivedById: $receivedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fromStoreId,
    toStoreId,
    status,
    note,
    createdById,
    approvedById,
    receivedById,
    clientCreatedAt,
    approvedAt,
    receivedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockTransfersLocalData &&
          other.id == this.id &&
          other.fromStoreId == this.fromStoreId &&
          other.toStoreId == this.toStoreId &&
          other.status == this.status &&
          other.note == this.note &&
          other.createdById == this.createdById &&
          other.approvedById == this.approvedById &&
          other.receivedById == this.receivedById &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.approvedAt == this.approvedAt &&
          other.receivedAt == this.receivedAt &&
          other.updatedAt == this.updatedAt);
}

class StockTransfersLocalCompanion
    extends UpdateCompanion<StockTransfersLocalData> {
  final Value<String> id;
  final Value<String> fromStoreId;
  final Value<String> toStoreId;
  final Value<String> status;
  final Value<String?> note;
  final Value<String> createdById;
  final Value<String?> approvedById;
  final Value<String?> receivedById;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime?> approvedAt;
  final Value<DateTime?> receivedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StockTransfersLocalCompanion({
    this.id = const Value.absent(),
    this.fromStoreId = const Value.absent(),
    this.toStoreId = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.createdById = const Value.absent(),
    this.approvedById = const Value.absent(),
    this.receivedById = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.approvedAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockTransfersLocalCompanion.insert({
    required String id,
    required String fromStoreId,
    required String toStoreId,
    required String status,
    this.note = const Value.absent(),
    required String createdById,
    this.approvedById = const Value.absent(),
    this.receivedById = const Value.absent(),
    required DateTime clientCreatedAt,
    this.approvedAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fromStoreId = Value(fromStoreId),
       toStoreId = Value(toStoreId),
       status = Value(status),
       createdById = Value(createdById),
       clientCreatedAt = Value(clientCreatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<StockTransfersLocalData> custom({
    Expression<String>? id,
    Expression<String>? fromStoreId,
    Expression<String>? toStoreId,
    Expression<String>? status,
    Expression<String>? note,
    Expression<String>? createdById,
    Expression<String>? approvedById,
    Expression<String>? receivedById,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? approvedAt,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromStoreId != null) 'from_store_id': fromStoreId,
      if (toStoreId != null) 'to_store_id': toStoreId,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (createdById != null) 'created_by_id': createdById,
      if (approvedById != null) 'approved_by_id': approvedById,
      if (receivedById != null) 'received_by_id': receivedById,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (approvedAt != null) 'approved_at': approvedAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockTransfersLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? fromStoreId,
    Value<String>? toStoreId,
    Value<String>? status,
    Value<String?>? note,
    Value<String>? createdById,
    Value<String?>? approvedById,
    Value<String?>? receivedById,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime?>? approvedAt,
    Value<DateTime?>? receivedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StockTransfersLocalCompanion(
      id: id ?? this.id,
      fromStoreId: fromStoreId ?? this.fromStoreId,
      toStoreId: toStoreId ?? this.toStoreId,
      status: status ?? this.status,
      note: note ?? this.note,
      createdById: createdById ?? this.createdById,
      approvedById: approvedById ?? this.approvedById,
      receivedById: receivedById ?? this.receivedById,
      clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      receivedAt: receivedAt ?? this.receivedAt,
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
    if (fromStoreId.present) {
      map['from_store_id'] = Variable<String>(fromStoreId.value);
    }
    if (toStoreId.present) {
      map['to_store_id'] = Variable<String>(toStoreId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdById.present) {
      map['created_by_id'] = Variable<String>(createdById.value);
    }
    if (approvedById.present) {
      map['approved_by_id'] = Variable<String>(approvedById.value);
    }
    if (receivedById.present) {
      map['received_by_id'] = Variable<String>(receivedById.value);
    }
    if (clientCreatedAt.present) {
      map['client_created_at'] = Variable<DateTime>(clientCreatedAt.value);
    }
    if (approvedAt.present) {
      map['approved_at'] = Variable<DateTime>(approvedAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
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
    return (StringBuffer('StockTransfersLocalCompanion(')
          ..write('id: $id, ')
          ..write('fromStoreId: $fromStoreId, ')
          ..write('toStoreId: $toStoreId, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('createdById: $createdById, ')
          ..write('approvedById: $approvedById, ')
          ..write('receivedById: $receivedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('approvedAt: $approvedAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockTransferLinesLocalTable extends StockTransferLinesLocal
    with TableInfo<$StockTransferLinesLocalTable, StockTransferLinesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockTransferLinesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferIdMeta = const VerificationMeta(
    'transferId',
  );
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
    'transfer_id',
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
  @override
  List<GeneratedColumn> get $columns => [id, transferId, productId, qty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_transfer_lines_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockTransferLinesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
        _transferIdMeta,
        transferId.isAcceptableOrUnknown(data['transfer_id']!, _transferIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transferIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockTransferLinesLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockTransferLinesLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transferId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qty'],
      )!,
    );
  }

  @override
  $StockTransferLinesLocalTable createAlias(String alias) {
    return $StockTransferLinesLocalTable(attachedDatabase, alias);
  }
}

class StockTransferLinesLocalData extends DataClass
    implements Insertable<StockTransferLinesLocalData> {
  final String id;
  final String transferId;
  final String productId;
  final String qty;
  const StockTransferLinesLocalData({
    required this.id,
    required this.transferId,
    required this.productId,
    required this.qty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transfer_id'] = Variable<String>(transferId);
    map['product_id'] = Variable<String>(productId);
    map['qty'] = Variable<String>(qty);
    return map;
  }

  StockTransferLinesLocalCompanion toCompanion(bool nullToAbsent) {
    return StockTransferLinesLocalCompanion(
      id: Value(id),
      transferId: Value(transferId),
      productId: Value(productId),
      qty: Value(qty),
    );
  }

  factory StockTransferLinesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockTransferLinesLocalData(
      id: serializer.fromJson<String>(json['id']),
      transferId: serializer.fromJson<String>(json['transferId']),
      productId: serializer.fromJson<String>(json['productId']),
      qty: serializer.fromJson<String>(json['qty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transferId': serializer.toJson<String>(transferId),
      'productId': serializer.toJson<String>(productId),
      'qty': serializer.toJson<String>(qty),
    };
  }

  StockTransferLinesLocalData copyWith({
    String? id,
    String? transferId,
    String? productId,
    String? qty,
  }) => StockTransferLinesLocalData(
    id: id ?? this.id,
    transferId: transferId ?? this.transferId,
    productId: productId ?? this.productId,
    qty: qty ?? this.qty,
  );
  StockTransferLinesLocalData copyWithCompanion(
    StockTransferLinesLocalCompanion data,
  ) {
    return StockTransferLinesLocalData(
      id: data.id.present ? data.id.value : this.id,
      transferId: data.transferId.present
          ? data.transferId.value
          : this.transferId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockTransferLinesLocalData(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transferId, productId, qty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockTransferLinesLocalData &&
          other.id == this.id &&
          other.transferId == this.transferId &&
          other.productId == this.productId &&
          other.qty == this.qty);
}

class StockTransferLinesLocalCompanion
    extends UpdateCompanion<StockTransferLinesLocalData> {
  final Value<String> id;
  final Value<String> transferId;
  final Value<String> productId;
  final Value<String> qty;
  final Value<int> rowid;
  const StockTransferLinesLocalCompanion({
    this.id = const Value.absent(),
    this.transferId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockTransferLinesLocalCompanion.insert({
    required String id,
    required String transferId,
    required String productId,
    required String qty,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transferId = Value(transferId),
       productId = Value(productId),
       qty = Value(qty);
  static Insertable<StockTransferLinesLocalData> custom({
    Expression<String>? id,
    Expression<String>? transferId,
    Expression<String>? productId,
    Expression<String>? qty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transferId != null) 'transfer_id': transferId,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockTransferLinesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? transferId,
    Value<String>? productId,
    Value<String>? qty,
    Value<int>? rowid,
  }) {
    return StockTransferLinesLocalCompanion(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<String>(qty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockTransferLinesLocalCompanion(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StocktakesLocalTable extends StocktakesLocal
    with TableInfo<$StocktakesLocalTable, StocktakesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StocktakesLocalTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
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
    note,
    recordedById,
    clientCreatedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stocktakes_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<StocktakesLocalData> instance, {
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
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  StocktakesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StocktakesLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      recordedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_id'],
      )!,
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
  $StocktakesLocalTable createAlias(String alias) {
    return $StocktakesLocalTable(attachedDatabase, alias);
  }
}

class StocktakesLocalData extends DataClass
    implements Insertable<StocktakesLocalData> {
  final String id;
  final String storeId;
  final String? note;
  final String recordedById;
  final DateTime clientCreatedAt;
  final DateTime updatedAt;
  const StocktakesLocalData({
    required this.id,
    required this.storeId,
    this.note,
    required this.recordedById,
    required this.clientCreatedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['recorded_by_id'] = Variable<String>(recordedById);
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StocktakesLocalCompanion toCompanion(bool nullToAbsent) {
    return StocktakesLocalCompanion(
      id: Value(id),
      storeId: Value(storeId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      recordedById: Value(recordedById),
      clientCreatedAt: Value(clientCreatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StocktakesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StocktakesLocalData(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      note: serializer.fromJson<String?>(json['note']),
      recordedById: serializer.fromJson<String>(json['recordedById']),
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
      'note': serializer.toJson<String?>(note),
      'recordedById': serializer.toJson<String>(recordedById),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StocktakesLocalData copyWith({
    String? id,
    String? storeId,
    Value<String?> note = const Value.absent(),
    String? recordedById,
    DateTime? clientCreatedAt,
    DateTime? updatedAt,
  }) => StocktakesLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    note: note.present ? note.value : this.note,
    recordedById: recordedById ?? this.recordedById,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StocktakesLocalData copyWithCompanion(StocktakesLocalCompanion data) {
    return StocktakesLocalData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      note: data.note.present ? data.note.value : this.note,
      recordedById: data.recordedById.present
          ? data.recordedById.value
          : this.recordedById,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StocktakesLocalData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('note: $note, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, storeId, note, recordedById, clientCreatedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StocktakesLocalData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.note == this.note &&
          other.recordedById == this.recordedById &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.updatedAt == this.updatedAt);
}

class StocktakesLocalCompanion extends UpdateCompanion<StocktakesLocalData> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String?> note;
  final Value<String> recordedById;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StocktakesLocalCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.note = const Value.absent(),
    this.recordedById = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StocktakesLocalCompanion.insert({
    required String id,
    required String storeId,
    this.note = const Value.absent(),
    required String recordedById,
    required DateTime clientCreatedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       recordedById = Value(recordedById),
       clientCreatedAt = Value(clientCreatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<StocktakesLocalData> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? note,
    Expression<String>? recordedById,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (note != null) 'note': note,
      if (recordedById != null) 'recorded_by_id': recordedById,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StocktakesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String?>? note,
    Value<String>? recordedById,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StocktakesLocalCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      note: note ?? this.note,
      recordedById: recordedById ?? this.recordedById,
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
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (recordedById.present) {
      map['recorded_by_id'] = Variable<String>(recordedById.value);
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
    return (StringBuffer('StocktakesLocalCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('note: $note, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StocktakeLinesLocalTable extends StocktakeLinesLocal
    with TableInfo<$StocktakeLinesLocalTable, StocktakeLinesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StocktakeLinesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stocktakeIdMeta = const VerificationMeta(
    'stocktakeId',
  );
  @override
  late final GeneratedColumn<String> stocktakeId = GeneratedColumn<String>(
    'stocktake_id',
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
  static const VerificationMeta _systemQtyMeta = const VerificationMeta(
    'systemQty',
  );
  @override
  late final GeneratedColumn<String> systemQty = GeneratedColumn<String>(
    'system_qty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countedQtyMeta = const VerificationMeta(
    'countedQty',
  );
  @override
  late final GeneratedColumn<String> countedQty = GeneratedColumn<String>(
    'counted_qty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _varianceQtyMeta = const VerificationMeta(
    'varianceQty',
  );
  @override
  late final GeneratedColumn<String> varianceQty = GeneratedColumn<String>(
    'variance_qty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonNoteMeta = const VerificationMeta(
    'reasonNote',
  );
  @override
  late final GeneratedColumn<String> reasonNote = GeneratedColumn<String>(
    'reason_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stocktakeId,
    productId,
    systemQty,
    countedQty,
    varianceQty,
    reason,
    reasonNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stocktake_lines_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<StocktakeLinesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('stocktake_id')) {
      context.handle(
        _stocktakeIdMeta,
        stocktakeId.isAcceptableOrUnknown(
          data['stocktake_id']!,
          _stocktakeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stocktakeIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('system_qty')) {
      context.handle(
        _systemQtyMeta,
        systemQty.isAcceptableOrUnknown(data['system_qty']!, _systemQtyMeta),
      );
    } else if (isInserting) {
      context.missing(_systemQtyMeta);
    }
    if (data.containsKey('counted_qty')) {
      context.handle(
        _countedQtyMeta,
        countedQty.isAcceptableOrUnknown(data['counted_qty']!, _countedQtyMeta),
      );
    } else if (isInserting) {
      context.missing(_countedQtyMeta);
    }
    if (data.containsKey('variance_qty')) {
      context.handle(
        _varianceQtyMeta,
        varianceQty.isAcceptableOrUnknown(
          data['variance_qty']!,
          _varianceQtyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_varianceQtyMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('reason_note')) {
      context.handle(
        _reasonNoteMeta,
        reasonNote.isAcceptableOrUnknown(data['reason_note']!, _reasonNoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StocktakeLinesLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StocktakeLinesLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      stocktakeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stocktake_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      systemQty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_qty'],
      )!,
      countedQty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counted_qty'],
      )!,
      varianceQty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variance_qty'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      reasonNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_note'],
      ),
    );
  }

  @override
  $StocktakeLinesLocalTable createAlias(String alias) {
    return $StocktakeLinesLocalTable(attachedDatabase, alias);
  }
}

class StocktakeLinesLocalData extends DataClass
    implements Insertable<StocktakeLinesLocalData> {
  final String id;
  final String stocktakeId;
  final String productId;
  final String systemQty;
  final String countedQty;
  final String varianceQty;
  final String reason;
  final String? reasonNote;
  const StocktakeLinesLocalData({
    required this.id,
    required this.stocktakeId,
    required this.productId,
    required this.systemQty,
    required this.countedQty,
    required this.varianceQty,
    required this.reason,
    this.reasonNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['stocktake_id'] = Variable<String>(stocktakeId);
    map['product_id'] = Variable<String>(productId);
    map['system_qty'] = Variable<String>(systemQty);
    map['counted_qty'] = Variable<String>(countedQty);
    map['variance_qty'] = Variable<String>(varianceQty);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || reasonNote != null) {
      map['reason_note'] = Variable<String>(reasonNote);
    }
    return map;
  }

  StocktakeLinesLocalCompanion toCompanion(bool nullToAbsent) {
    return StocktakeLinesLocalCompanion(
      id: Value(id),
      stocktakeId: Value(stocktakeId),
      productId: Value(productId),
      systemQty: Value(systemQty),
      countedQty: Value(countedQty),
      varianceQty: Value(varianceQty),
      reason: Value(reason),
      reasonNote: reasonNote == null && nullToAbsent
          ? const Value.absent()
          : Value(reasonNote),
    );
  }

  factory StocktakeLinesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StocktakeLinesLocalData(
      id: serializer.fromJson<String>(json['id']),
      stocktakeId: serializer.fromJson<String>(json['stocktakeId']),
      productId: serializer.fromJson<String>(json['productId']),
      systemQty: serializer.fromJson<String>(json['systemQty']),
      countedQty: serializer.fromJson<String>(json['countedQty']),
      varianceQty: serializer.fromJson<String>(json['varianceQty']),
      reason: serializer.fromJson<String>(json['reason']),
      reasonNote: serializer.fromJson<String?>(json['reasonNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stocktakeId': serializer.toJson<String>(stocktakeId),
      'productId': serializer.toJson<String>(productId),
      'systemQty': serializer.toJson<String>(systemQty),
      'countedQty': serializer.toJson<String>(countedQty),
      'varianceQty': serializer.toJson<String>(varianceQty),
      'reason': serializer.toJson<String>(reason),
      'reasonNote': serializer.toJson<String?>(reasonNote),
    };
  }

  StocktakeLinesLocalData copyWith({
    String? id,
    String? stocktakeId,
    String? productId,
    String? systemQty,
    String? countedQty,
    String? varianceQty,
    String? reason,
    Value<String?> reasonNote = const Value.absent(),
  }) => StocktakeLinesLocalData(
    id: id ?? this.id,
    stocktakeId: stocktakeId ?? this.stocktakeId,
    productId: productId ?? this.productId,
    systemQty: systemQty ?? this.systemQty,
    countedQty: countedQty ?? this.countedQty,
    varianceQty: varianceQty ?? this.varianceQty,
    reason: reason ?? this.reason,
    reasonNote: reasonNote.present ? reasonNote.value : this.reasonNote,
  );
  StocktakeLinesLocalData copyWithCompanion(StocktakeLinesLocalCompanion data) {
    return StocktakeLinesLocalData(
      id: data.id.present ? data.id.value : this.id,
      stocktakeId: data.stocktakeId.present
          ? data.stocktakeId.value
          : this.stocktakeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      systemQty: data.systemQty.present ? data.systemQty.value : this.systemQty,
      countedQty: data.countedQty.present
          ? data.countedQty.value
          : this.countedQty,
      varianceQty: data.varianceQty.present
          ? data.varianceQty.value
          : this.varianceQty,
      reason: data.reason.present ? data.reason.value : this.reason,
      reasonNote: data.reasonNote.present
          ? data.reasonNote.value
          : this.reasonNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StocktakeLinesLocalData(')
          ..write('id: $id, ')
          ..write('stocktakeId: $stocktakeId, ')
          ..write('productId: $productId, ')
          ..write('systemQty: $systemQty, ')
          ..write('countedQty: $countedQty, ')
          ..write('varianceQty: $varianceQty, ')
          ..write('reason: $reason, ')
          ..write('reasonNote: $reasonNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stocktakeId,
    productId,
    systemQty,
    countedQty,
    varianceQty,
    reason,
    reasonNote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StocktakeLinesLocalData &&
          other.id == this.id &&
          other.stocktakeId == this.stocktakeId &&
          other.productId == this.productId &&
          other.systemQty == this.systemQty &&
          other.countedQty == this.countedQty &&
          other.varianceQty == this.varianceQty &&
          other.reason == this.reason &&
          other.reasonNote == this.reasonNote);
}

class StocktakeLinesLocalCompanion
    extends UpdateCompanion<StocktakeLinesLocalData> {
  final Value<String> id;
  final Value<String> stocktakeId;
  final Value<String> productId;
  final Value<String> systemQty;
  final Value<String> countedQty;
  final Value<String> varianceQty;
  final Value<String> reason;
  final Value<String?> reasonNote;
  final Value<int> rowid;
  const StocktakeLinesLocalCompanion({
    this.id = const Value.absent(),
    this.stocktakeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.systemQty = const Value.absent(),
    this.countedQty = const Value.absent(),
    this.varianceQty = const Value.absent(),
    this.reason = const Value.absent(),
    this.reasonNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StocktakeLinesLocalCompanion.insert({
    required String id,
    required String stocktakeId,
    required String productId,
    required String systemQty,
    required String countedQty,
    required String varianceQty,
    required String reason,
    this.reasonNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       stocktakeId = Value(stocktakeId),
       productId = Value(productId),
       systemQty = Value(systemQty),
       countedQty = Value(countedQty),
       varianceQty = Value(varianceQty),
       reason = Value(reason);
  static Insertable<StocktakeLinesLocalData> custom({
    Expression<String>? id,
    Expression<String>? stocktakeId,
    Expression<String>? productId,
    Expression<String>? systemQty,
    Expression<String>? countedQty,
    Expression<String>? varianceQty,
    Expression<String>? reason,
    Expression<String>? reasonNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stocktakeId != null) 'stocktake_id': stocktakeId,
      if (productId != null) 'product_id': productId,
      if (systemQty != null) 'system_qty': systemQty,
      if (countedQty != null) 'counted_qty': countedQty,
      if (varianceQty != null) 'variance_qty': varianceQty,
      if (reason != null) 'reason': reason,
      if (reasonNote != null) 'reason_note': reasonNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StocktakeLinesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? stocktakeId,
    Value<String>? productId,
    Value<String>? systemQty,
    Value<String>? countedQty,
    Value<String>? varianceQty,
    Value<String>? reason,
    Value<String?>? reasonNote,
    Value<int>? rowid,
  }) {
    return StocktakeLinesLocalCompanion(
      id: id ?? this.id,
      stocktakeId: stocktakeId ?? this.stocktakeId,
      productId: productId ?? this.productId,
      systemQty: systemQty ?? this.systemQty,
      countedQty: countedQty ?? this.countedQty,
      varianceQty: varianceQty ?? this.varianceQty,
      reason: reason ?? this.reason,
      reasonNote: reasonNote ?? this.reasonNote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (stocktakeId.present) {
      map['stocktake_id'] = Variable<String>(stocktakeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (systemQty.present) {
      map['system_qty'] = Variable<String>(systemQty.value);
    }
    if (countedQty.present) {
      map['counted_qty'] = Variable<String>(countedQty.value);
    }
    if (varianceQty.present) {
      map['variance_qty'] = Variable<String>(varianceQty.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (reasonNote.present) {
      map['reason_note'] = Variable<String>(reasonNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StocktakeLinesLocalCompanion(')
          ..write('id: $id, ')
          ..write('stocktakeId: $stocktakeId, ')
          ..write('productId: $productId, ')
          ..write('systemQty: $systemQty, ')
          ..write('countedQty: $countedQty, ')
          ..write('varianceQty: $varianceQty, ')
          ..write('reason: $reason, ')
          ..write('reasonNote: $reasonNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseReceiptsLocalTable extends PurchaseReceiptsLocal
    with TableInfo<$PurchaseReceiptsLocalTable, PurchaseReceiptsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseReceiptsLocalTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _supplierNameMeta = const VerificationMeta(
    'supplierName',
  );
  @override
  late final GeneratedColumn<String> supplierName = GeneratedColumn<String>(
    'supplier_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supplierPhoneMeta = const VerificationMeta(
    'supplierPhone',
  );
  @override
  late final GeneratedColumn<String> supplierPhone = GeneratedColumn<String>(
    'supplier_phone',
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
    supplierName,
    supplierPhone,
    note,
    recordedById,
    clientCreatedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_receipts_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseReceiptsLocalData> instance, {
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
    if (data.containsKey('supplier_name')) {
      context.handle(
        _supplierNameMeta,
        supplierName.isAcceptableOrUnknown(
          data['supplier_name']!,
          _supplierNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_supplierNameMeta);
    }
    if (data.containsKey('supplier_phone')) {
      context.handle(
        _supplierPhoneMeta,
        supplierPhone.isAcceptableOrUnknown(
          data['supplier_phone']!,
          _supplierPhoneMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  PurchaseReceiptsLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseReceiptsLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      supplierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_name'],
      )!,
      supplierPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_phone'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      recordedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_id'],
      )!,
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
  $PurchaseReceiptsLocalTable createAlias(String alias) {
    return $PurchaseReceiptsLocalTable(attachedDatabase, alias);
  }
}

class PurchaseReceiptsLocalData extends DataClass
    implements Insertable<PurchaseReceiptsLocalData> {
  final String id;
  final String storeId;
  final String supplierName;
  final String? supplierPhone;
  final String? note;
  final String recordedById;
  final DateTime clientCreatedAt;
  final DateTime updatedAt;
  const PurchaseReceiptsLocalData({
    required this.id,
    required this.storeId,
    required this.supplierName,
    this.supplierPhone,
    this.note,
    required this.recordedById,
    required this.clientCreatedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['supplier_name'] = Variable<String>(supplierName);
    if (!nullToAbsent || supplierPhone != null) {
      map['supplier_phone'] = Variable<String>(supplierPhone);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['recorded_by_id'] = Variable<String>(recordedById);
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PurchaseReceiptsLocalCompanion toCompanion(bool nullToAbsent) {
    return PurchaseReceiptsLocalCompanion(
      id: Value(id),
      storeId: Value(storeId),
      supplierName: Value(supplierName),
      supplierPhone: supplierPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierPhone),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      recordedById: Value(recordedById),
      clientCreatedAt: Value(clientCreatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PurchaseReceiptsLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseReceiptsLocalData(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      supplierName: serializer.fromJson<String>(json['supplierName']),
      supplierPhone: serializer.fromJson<String?>(json['supplierPhone']),
      note: serializer.fromJson<String?>(json['note']),
      recordedById: serializer.fromJson<String>(json['recordedById']),
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
      'supplierName': serializer.toJson<String>(supplierName),
      'supplierPhone': serializer.toJson<String?>(supplierPhone),
      'note': serializer.toJson<String?>(note),
      'recordedById': serializer.toJson<String>(recordedById),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PurchaseReceiptsLocalData copyWith({
    String? id,
    String? storeId,
    String? supplierName,
    Value<String?> supplierPhone = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? recordedById,
    DateTime? clientCreatedAt,
    DateTime? updatedAt,
  }) => PurchaseReceiptsLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    supplierName: supplierName ?? this.supplierName,
    supplierPhone: supplierPhone.present
        ? supplierPhone.value
        : this.supplierPhone,
    note: note.present ? note.value : this.note,
    recordedById: recordedById ?? this.recordedById,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PurchaseReceiptsLocalData copyWithCompanion(
    PurchaseReceiptsLocalCompanion data,
  ) {
    return PurchaseReceiptsLocalData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      supplierName: data.supplierName.present
          ? data.supplierName.value
          : this.supplierName,
      supplierPhone: data.supplierPhone.present
          ? data.supplierPhone.value
          : this.supplierPhone,
      note: data.note.present ? data.note.value : this.note,
      recordedById: data.recordedById.present
          ? data.recordedById.value
          : this.recordedById,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseReceiptsLocalData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('supplierName: $supplierName, ')
          ..write('supplierPhone: $supplierPhone, ')
          ..write('note: $note, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    supplierName,
    supplierPhone,
    note,
    recordedById,
    clientCreatedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseReceiptsLocalData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.supplierName == this.supplierName &&
          other.supplierPhone == this.supplierPhone &&
          other.note == this.note &&
          other.recordedById == this.recordedById &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.updatedAt == this.updatedAt);
}

class PurchaseReceiptsLocalCompanion
    extends UpdateCompanion<PurchaseReceiptsLocalData> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> supplierName;
  final Value<String?> supplierPhone;
  final Value<String?> note;
  final Value<String> recordedById;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PurchaseReceiptsLocalCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.supplierName = const Value.absent(),
    this.supplierPhone = const Value.absent(),
    this.note = const Value.absent(),
    this.recordedById = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseReceiptsLocalCompanion.insert({
    required String id,
    required String storeId,
    required String supplierName,
    this.supplierPhone = const Value.absent(),
    this.note = const Value.absent(),
    required String recordedById,
    required DateTime clientCreatedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       supplierName = Value(supplierName),
       recordedById = Value(recordedById),
       clientCreatedAt = Value(clientCreatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<PurchaseReceiptsLocalData> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? supplierName,
    Expression<String>? supplierPhone,
    Expression<String>? note,
    Expression<String>? recordedById,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (supplierName != null) 'supplier_name': supplierName,
      if (supplierPhone != null) 'supplier_phone': supplierPhone,
      if (note != null) 'note': note,
      if (recordedById != null) 'recorded_by_id': recordedById,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseReceiptsLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? supplierName,
    Value<String?>? supplierPhone,
    Value<String?>? note,
    Value<String>? recordedById,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PurchaseReceiptsLocalCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      note: note ?? this.note,
      recordedById: recordedById ?? this.recordedById,
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
    if (supplierName.present) {
      map['supplier_name'] = Variable<String>(supplierName.value);
    }
    if (supplierPhone.present) {
      map['supplier_phone'] = Variable<String>(supplierPhone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (recordedById.present) {
      map['recorded_by_id'] = Variable<String>(recordedById.value);
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
    return (StringBuffer('PurchaseReceiptsLocalCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('supplierName: $supplierName, ')
          ..write('supplierPhone: $supplierPhone, ')
          ..write('note: $note, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseReceiptLinesLocalTable extends PurchaseReceiptLinesLocal
    with
        TableInfo<
          $PurchaseReceiptLinesLocalTable,
          PurchaseReceiptLinesLocalData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseReceiptLinesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
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
  static const VerificationMeta _unitCostVndMeta = const VerificationMeta(
    'unitCostVnd',
  );
  @override
  late final GeneratedColumn<int> unitCostVnd = GeneratedColumn<int>(
    'unit_cost_vnd',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    productId,
    qty,
    unitCostVnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_receipt_lines_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseReceiptLinesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
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
    if (data.containsKey('unit_cost_vnd')) {
      context.handle(
        _unitCostVndMeta,
        unitCostVnd.isAcceptableOrUnknown(
          data['unit_cost_vnd']!,
          _unitCostVndMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseReceiptLinesLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseReceiptLinesLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qty'],
      )!,
      unitCostVnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_cost_vnd'],
      ),
    );
  }

  @override
  $PurchaseReceiptLinesLocalTable createAlias(String alias) {
    return $PurchaseReceiptLinesLocalTable(attachedDatabase, alias);
  }
}

class PurchaseReceiptLinesLocalData extends DataClass
    implements Insertable<PurchaseReceiptLinesLocalData> {
  final String id;
  final String receiptId;
  final String productId;
  final String qty;
  final int? unitCostVnd;
  const PurchaseReceiptLinesLocalData({
    required this.id,
    required this.receiptId,
    required this.productId,
    required this.qty,
    this.unitCostVnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['product_id'] = Variable<String>(productId);
    map['qty'] = Variable<String>(qty);
    if (!nullToAbsent || unitCostVnd != null) {
      map['unit_cost_vnd'] = Variable<int>(unitCostVnd);
    }
    return map;
  }

  PurchaseReceiptLinesLocalCompanion toCompanion(bool nullToAbsent) {
    return PurchaseReceiptLinesLocalCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      productId: Value(productId),
      qty: Value(qty),
      unitCostVnd: unitCostVnd == null && nullToAbsent
          ? const Value.absent()
          : Value(unitCostVnd),
    );
  }

  factory PurchaseReceiptLinesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseReceiptLinesLocalData(
      id: serializer.fromJson<String>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      productId: serializer.fromJson<String>(json['productId']),
      qty: serializer.fromJson<String>(json['qty']),
      unitCostVnd: serializer.fromJson<int?>(json['unitCostVnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'productId': serializer.toJson<String>(productId),
      'qty': serializer.toJson<String>(qty),
      'unitCostVnd': serializer.toJson<int?>(unitCostVnd),
    };
  }

  PurchaseReceiptLinesLocalData copyWith({
    String? id,
    String? receiptId,
    String? productId,
    String? qty,
    Value<int?> unitCostVnd = const Value.absent(),
  }) => PurchaseReceiptLinesLocalData(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    productId: productId ?? this.productId,
    qty: qty ?? this.qty,
    unitCostVnd: unitCostVnd.present ? unitCostVnd.value : this.unitCostVnd,
  );
  PurchaseReceiptLinesLocalData copyWithCompanion(
    PurchaseReceiptLinesLocalCompanion data,
  ) {
    return PurchaseReceiptLinesLocalData(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitCostVnd: data.unitCostVnd.present
          ? data.unitCostVnd.value
          : this.unitCostVnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseReceiptLinesLocalData(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('unitCostVnd: $unitCostVnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, receiptId, productId, qty, unitCostVnd);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseReceiptLinesLocalData &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.productId == this.productId &&
          other.qty == this.qty &&
          other.unitCostVnd == this.unitCostVnd);
}

class PurchaseReceiptLinesLocalCompanion
    extends UpdateCompanion<PurchaseReceiptLinesLocalData> {
  final Value<String> id;
  final Value<String> receiptId;
  final Value<String> productId;
  final Value<String> qty;
  final Value<int?> unitCostVnd;
  final Value<int> rowid;
  const PurchaseReceiptLinesLocalCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitCostVnd = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseReceiptLinesLocalCompanion.insert({
    required String id,
    required String receiptId,
    required String productId,
    required String qty,
    this.unitCostVnd = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptId = Value(receiptId),
       productId = Value(productId),
       qty = Value(qty);
  static Insertable<PurchaseReceiptLinesLocalData> custom({
    Expression<String>? id,
    Expression<String>? receiptId,
    Expression<String>? productId,
    Expression<String>? qty,
    Expression<int>? unitCostVnd,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (unitCostVnd != null) 'unit_cost_vnd': unitCostVnd,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseReceiptLinesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptId,
    Value<String>? productId,
    Value<String>? qty,
    Value<int?>? unitCostVnd,
    Value<int>? rowid,
  }) {
    return PurchaseReceiptLinesLocalCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      unitCostVnd: unitCostVnd ?? this.unitCostVnd,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<String>(qty.value);
    }
    if (unitCostVnd.present) {
      map['unit_cost_vnd'] = Variable<int>(unitCostVnd.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseReceiptLinesLocalCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('unitCostVnd: $unitCostVnd, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WastageVouchersLocalTable extends WastageVouchersLocal
    with TableInfo<$WastageVouchersLocalTable, WastageVouchersLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WastageVouchersLocalTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    reasonCode,
    note,
    recordedById,
    clientCreatedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wastage_vouchers_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<WastageVouchersLocalData> instance, {
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
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonCodeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  WastageVouchersLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WastageVouchersLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      recordedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_id'],
      )!,
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
  $WastageVouchersLocalTable createAlias(String alias) {
    return $WastageVouchersLocalTable(attachedDatabase, alias);
  }
}

class WastageVouchersLocalData extends DataClass
    implements Insertable<WastageVouchersLocalData> {
  final String id;
  final String storeId;
  final String reasonCode;
  final String? note;
  final String recordedById;
  final DateTime clientCreatedAt;
  final DateTime updatedAt;
  const WastageVouchersLocalData({
    required this.id,
    required this.storeId,
    required this.reasonCode,
    this.note,
    required this.recordedById,
    required this.clientCreatedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['reason_code'] = Variable<String>(reasonCode);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['recorded_by_id'] = Variable<String>(recordedById);
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WastageVouchersLocalCompanion toCompanion(bool nullToAbsent) {
    return WastageVouchersLocalCompanion(
      id: Value(id),
      storeId: Value(storeId),
      reasonCode: Value(reasonCode),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      recordedById: Value(recordedById),
      clientCreatedAt: Value(clientCreatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WastageVouchersLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WastageVouchersLocalData(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      reasonCode: serializer.fromJson<String>(json['reasonCode']),
      note: serializer.fromJson<String?>(json['note']),
      recordedById: serializer.fromJson<String>(json['recordedById']),
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
      'reasonCode': serializer.toJson<String>(reasonCode),
      'note': serializer.toJson<String?>(note),
      'recordedById': serializer.toJson<String>(recordedById),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WastageVouchersLocalData copyWith({
    String? id,
    String? storeId,
    String? reasonCode,
    Value<String?> note = const Value.absent(),
    String? recordedById,
    DateTime? clientCreatedAt,
    DateTime? updatedAt,
  }) => WastageVouchersLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    reasonCode: reasonCode ?? this.reasonCode,
    note: note.present ? note.value : this.note,
    recordedById: recordedById ?? this.recordedById,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WastageVouchersLocalData copyWithCompanion(
    WastageVouchersLocalCompanion data,
  ) {
    return WastageVouchersLocalData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      note: data.note.present ? data.note.value : this.note,
      recordedById: data.recordedById.present
          ? data.recordedById.value
          : this.recordedById,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WastageVouchersLocalData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('note: $note, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    reasonCode,
    note,
    recordedById,
    clientCreatedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WastageVouchersLocalData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.reasonCode == this.reasonCode &&
          other.note == this.note &&
          other.recordedById == this.recordedById &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.updatedAt == this.updatedAt);
}

class WastageVouchersLocalCompanion
    extends UpdateCompanion<WastageVouchersLocalData> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> reasonCode;
  final Value<String?> note;
  final Value<String> recordedById;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WastageVouchersLocalCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.note = const Value.absent(),
    this.recordedById = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WastageVouchersLocalCompanion.insert({
    required String id,
    required String storeId,
    required String reasonCode,
    this.note = const Value.absent(),
    required String recordedById,
    required DateTime clientCreatedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       reasonCode = Value(reasonCode),
       recordedById = Value(recordedById),
       clientCreatedAt = Value(clientCreatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<WastageVouchersLocalData> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? reasonCode,
    Expression<String>? note,
    Expression<String>? recordedById,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (note != null) 'note': note,
      if (recordedById != null) 'recorded_by_id': recordedById,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WastageVouchersLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? reasonCode,
    Value<String?>? note,
    Value<String>? recordedById,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WastageVouchersLocalCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      reasonCode: reasonCode ?? this.reasonCode,
      note: note ?? this.note,
      recordedById: recordedById ?? this.recordedById,
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
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (recordedById.present) {
      map['recorded_by_id'] = Variable<String>(recordedById.value);
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
    return (StringBuffer('WastageVouchersLocalCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('note: $note, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WastageVoucherLinesLocalTable extends WastageVoucherLinesLocal
    with
        TableInfo<
          $WastageVoucherLinesLocalTable,
          WastageVoucherLinesLocalData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WastageVoucherLinesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wastageIdMeta = const VerificationMeta(
    'wastageId',
  );
  @override
  late final GeneratedColumn<String> wastageId = GeneratedColumn<String>(
    'wastage_id',
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
  @override
  List<GeneratedColumn> get $columns => [id, wastageId, productId, qty];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wastage_voucher_lines_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<WastageVoucherLinesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('wastage_id')) {
      context.handle(
        _wastageIdMeta,
        wastageId.isAcceptableOrUnknown(data['wastage_id']!, _wastageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wastageIdMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WastageVoucherLinesLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WastageVoucherLinesLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      wastageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wastage_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qty'],
      )!,
    );
  }

  @override
  $WastageVoucherLinesLocalTable createAlias(String alias) {
    return $WastageVoucherLinesLocalTable(attachedDatabase, alias);
  }
}

class WastageVoucherLinesLocalData extends DataClass
    implements Insertable<WastageVoucherLinesLocalData> {
  final String id;
  final String wastageId;
  final String productId;
  final String qty;
  const WastageVoucherLinesLocalData({
    required this.id,
    required this.wastageId,
    required this.productId,
    required this.qty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['wastage_id'] = Variable<String>(wastageId);
    map['product_id'] = Variable<String>(productId);
    map['qty'] = Variable<String>(qty);
    return map;
  }

  WastageVoucherLinesLocalCompanion toCompanion(bool nullToAbsent) {
    return WastageVoucherLinesLocalCompanion(
      id: Value(id),
      wastageId: Value(wastageId),
      productId: Value(productId),
      qty: Value(qty),
    );
  }

  factory WastageVoucherLinesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WastageVoucherLinesLocalData(
      id: serializer.fromJson<String>(json['id']),
      wastageId: serializer.fromJson<String>(json['wastageId']),
      productId: serializer.fromJson<String>(json['productId']),
      qty: serializer.fromJson<String>(json['qty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wastageId': serializer.toJson<String>(wastageId),
      'productId': serializer.toJson<String>(productId),
      'qty': serializer.toJson<String>(qty),
    };
  }

  WastageVoucherLinesLocalData copyWith({
    String? id,
    String? wastageId,
    String? productId,
    String? qty,
  }) => WastageVoucherLinesLocalData(
    id: id ?? this.id,
    wastageId: wastageId ?? this.wastageId,
    productId: productId ?? this.productId,
    qty: qty ?? this.qty,
  );
  WastageVoucherLinesLocalData copyWithCompanion(
    WastageVoucherLinesLocalCompanion data,
  ) {
    return WastageVoucherLinesLocalData(
      id: data.id.present ? data.id.value : this.id,
      wastageId: data.wastageId.present ? data.wastageId.value : this.wastageId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qty: data.qty.present ? data.qty.value : this.qty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WastageVoucherLinesLocalData(')
          ..write('id: $id, ')
          ..write('wastageId: $wastageId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wastageId, productId, qty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WastageVoucherLinesLocalData &&
          other.id == this.id &&
          other.wastageId == this.wastageId &&
          other.productId == this.productId &&
          other.qty == this.qty);
}

class WastageVoucherLinesLocalCompanion
    extends UpdateCompanion<WastageVoucherLinesLocalData> {
  final Value<String> id;
  final Value<String> wastageId;
  final Value<String> productId;
  final Value<String> qty;
  final Value<int> rowid;
  const WastageVoucherLinesLocalCompanion({
    this.id = const Value.absent(),
    this.wastageId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WastageVoucherLinesLocalCompanion.insert({
    required String id,
    required String wastageId,
    required String productId,
    required String qty,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       wastageId = Value(wastageId),
       productId = Value(productId),
       qty = Value(qty);
  static Insertable<WastageVoucherLinesLocalData> custom({
    Expression<String>? id,
    Expression<String>? wastageId,
    Expression<String>? productId,
    Expression<String>? qty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wastageId != null) 'wastage_id': wastageId,
      if (productId != null) 'product_id': productId,
      if (qty != null) 'qty': qty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WastageVoucherLinesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? wastageId,
    Value<String>? productId,
    Value<String>? qty,
    Value<int>? rowid,
  }) {
    return WastageVoucherLinesLocalCompanion(
      id: id ?? this.id,
      wastageId: wastageId ?? this.wastageId,
      productId: productId ?? this.productId,
      qty: qty ?? this.qty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wastageId.present) {
      map['wastage_id'] = Variable<String>(wastageId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<String>(qty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WastageVoucherLinesLocalCompanion(')
          ..write('id: $id, ')
          ..write('wastageId: $wastageId, ')
          ..write('productId: $productId, ')
          ..write('qty: $qty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsLocalTable extends StockMovementsLocal
    with TableInfo<$StockMovementsLocalTable, StockMovementsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsLocalTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _qtyDeltaMeta = const VerificationMeta(
    'qtyDelta',
  );
  @override
  late final GeneratedColumn<String> qtyDelta = GeneratedColumn<String>(
    'qty_delta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceAfterMeta = const VerificationMeta(
    'balanceAfter',
  );
  @override
  late final GeneratedColumn<String> balanceAfter = GeneratedColumn<String>(
    'balance_after',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docTypeMeta = const VerificationMeta(
    'docType',
  );
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
    'doc_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docIdMeta = const VerificationMeta('docId');
  @override
  late final GeneratedColumn<String> docId = GeneratedColumn<String>(
    'doc_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _docLineIdMeta = const VerificationMeta(
    'docLineId',
  );
  @override
  late final GeneratedColumn<String> docLineId = GeneratedColumn<String>(
    'doc_line_id',
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
    productId,
    qtyDelta,
    balanceAfter,
    docType,
    docId,
    docLineId,
    recordedById,
    clientCreatedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMovementsLocalData> instance, {
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
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('qty_delta')) {
      context.handle(
        _qtyDeltaMeta,
        qtyDelta.isAcceptableOrUnknown(data['qty_delta']!, _qtyDeltaMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyDeltaMeta);
    }
    if (data.containsKey('balance_after')) {
      context.handle(
        _balanceAfterMeta,
        balanceAfter.isAcceptableOrUnknown(
          data['balance_after']!,
          _balanceAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceAfterMeta);
    }
    if (data.containsKey('doc_type')) {
      context.handle(
        _docTypeMeta,
        docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_docTypeMeta);
    }
    if (data.containsKey('doc_id')) {
      context.handle(
        _docIdMeta,
        docId.isAcceptableOrUnknown(data['doc_id']!, _docIdMeta),
      );
    } else if (isInserting) {
      context.missing(_docIdMeta);
    }
    if (data.containsKey('doc_line_id')) {
      context.handle(
        _docLineIdMeta,
        docLineId.isAcceptableOrUnknown(data['doc_line_id']!, _docLineIdMeta),
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
  StockMovementsLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMovementsLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      qtyDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qty_delta'],
      )!,
      balanceAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}balance_after'],
      )!,
      docType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_type'],
      )!,
      docId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_id'],
      )!,
      docLineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doc_line_id'],
      ),
      recordedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by_id'],
      )!,
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
  $StockMovementsLocalTable createAlias(String alias) {
    return $StockMovementsLocalTable(attachedDatabase, alias);
  }
}

class StockMovementsLocalData extends DataClass
    implements Insertable<StockMovementsLocalData> {
  final String id;
  final String storeId;
  final String productId;
  final String qtyDelta;
  final String balanceAfter;
  final String docType;
  final String docId;
  final String? docLineId;
  final String recordedById;
  final DateTime clientCreatedAt;
  final DateTime updatedAt;
  const StockMovementsLocalData({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.qtyDelta,
    required this.balanceAfter,
    required this.docType,
    required this.docId,
    this.docLineId,
    required this.recordedById,
    required this.clientCreatedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['product_id'] = Variable<String>(productId);
    map['qty_delta'] = Variable<String>(qtyDelta);
    map['balance_after'] = Variable<String>(balanceAfter);
    map['doc_type'] = Variable<String>(docType);
    map['doc_id'] = Variable<String>(docId);
    if (!nullToAbsent || docLineId != null) {
      map['doc_line_id'] = Variable<String>(docLineId);
    }
    map['recorded_by_id'] = Variable<String>(recordedById);
    map['client_created_at'] = Variable<DateTime>(clientCreatedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StockMovementsLocalCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsLocalCompanion(
      id: Value(id),
      storeId: Value(storeId),
      productId: Value(productId),
      qtyDelta: Value(qtyDelta),
      balanceAfter: Value(balanceAfter),
      docType: Value(docType),
      docId: Value(docId),
      docLineId: docLineId == null && nullToAbsent
          ? const Value.absent()
          : Value(docLineId),
      recordedById: Value(recordedById),
      clientCreatedAt: Value(clientCreatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StockMovementsLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMovementsLocalData(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['storeId']),
      productId: serializer.fromJson<String>(json['productId']),
      qtyDelta: serializer.fromJson<String>(json['qtyDelta']),
      balanceAfter: serializer.fromJson<String>(json['balanceAfter']),
      docType: serializer.fromJson<String>(json['docType']),
      docId: serializer.fromJson<String>(json['docId']),
      docLineId: serializer.fromJson<String?>(json['docLineId']),
      recordedById: serializer.fromJson<String>(json['recordedById']),
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
      'productId': serializer.toJson<String>(productId),
      'qtyDelta': serializer.toJson<String>(qtyDelta),
      'balanceAfter': serializer.toJson<String>(balanceAfter),
      'docType': serializer.toJson<String>(docType),
      'docId': serializer.toJson<String>(docId),
      'docLineId': serializer.toJson<String?>(docLineId),
      'recordedById': serializer.toJson<String>(recordedById),
      'clientCreatedAt': serializer.toJson<DateTime>(clientCreatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StockMovementsLocalData copyWith({
    String? id,
    String? storeId,
    String? productId,
    String? qtyDelta,
    String? balanceAfter,
    String? docType,
    String? docId,
    Value<String?> docLineId = const Value.absent(),
    String? recordedById,
    DateTime? clientCreatedAt,
    DateTime? updatedAt,
  }) => StockMovementsLocalData(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    productId: productId ?? this.productId,
    qtyDelta: qtyDelta ?? this.qtyDelta,
    balanceAfter: balanceAfter ?? this.balanceAfter,
    docType: docType ?? this.docType,
    docId: docId ?? this.docId,
    docLineId: docLineId.present ? docLineId.value : this.docLineId,
    recordedById: recordedById ?? this.recordedById,
    clientCreatedAt: clientCreatedAt ?? this.clientCreatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StockMovementsLocalData copyWithCompanion(StockMovementsLocalCompanion data) {
    return StockMovementsLocalData(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      qtyDelta: data.qtyDelta.present ? data.qtyDelta.value : this.qtyDelta,
      balanceAfter: data.balanceAfter.present
          ? data.balanceAfter.value
          : this.balanceAfter,
      docType: data.docType.present ? data.docType.value : this.docType,
      docId: data.docId.present ? data.docId.value : this.docId,
      docLineId: data.docLineId.present ? data.docLineId.value : this.docLineId,
      recordedById: data.recordedById.present
          ? data.recordedById.value
          : this.recordedById,
      clientCreatedAt: data.clientCreatedAt.present
          ? data.clientCreatedAt.value
          : this.clientCreatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsLocalData(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('qtyDelta: $qtyDelta, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('docType: $docType, ')
          ..write('docId: $docId, ')
          ..write('docLineId: $docLineId, ')
          ..write('recordedById: $recordedById, ')
          ..write('clientCreatedAt: $clientCreatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    productId,
    qtyDelta,
    balanceAfter,
    docType,
    docId,
    docLineId,
    recordedById,
    clientCreatedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMovementsLocalData &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.productId == this.productId &&
          other.qtyDelta == this.qtyDelta &&
          other.balanceAfter == this.balanceAfter &&
          other.docType == this.docType &&
          other.docId == this.docId &&
          other.docLineId == this.docLineId &&
          other.recordedById == this.recordedById &&
          other.clientCreatedAt == this.clientCreatedAt &&
          other.updatedAt == this.updatedAt);
}

class StockMovementsLocalCompanion
    extends UpdateCompanion<StockMovementsLocalData> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> productId;
  final Value<String> qtyDelta;
  final Value<String> balanceAfter;
  final Value<String> docType;
  final Value<String> docId;
  final Value<String?> docLineId;
  final Value<String> recordedById;
  final Value<DateTime> clientCreatedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StockMovementsLocalCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.qtyDelta = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.docType = const Value.absent(),
    this.docId = const Value.absent(),
    this.docLineId = const Value.absent(),
    this.recordedById = const Value.absent(),
    this.clientCreatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsLocalCompanion.insert({
    required String id,
    required String storeId,
    required String productId,
    required String qtyDelta,
    required String balanceAfter,
    required String docType,
    required String docId,
    this.docLineId = const Value.absent(),
    required String recordedById,
    required DateTime clientCreatedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       productId = Value(productId),
       qtyDelta = Value(qtyDelta),
       balanceAfter = Value(balanceAfter),
       docType = Value(docType),
       docId = Value(docId),
       recordedById = Value(recordedById),
       clientCreatedAt = Value(clientCreatedAt),
       updatedAt = Value(updatedAt);
  static Insertable<StockMovementsLocalData> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? productId,
    Expression<String>? qtyDelta,
    Expression<String>? balanceAfter,
    Expression<String>? docType,
    Expression<String>? docId,
    Expression<String>? docLineId,
    Expression<String>? recordedById,
    Expression<DateTime>? clientCreatedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (productId != null) 'product_id': productId,
      if (qtyDelta != null) 'qty_delta': qtyDelta,
      if (balanceAfter != null) 'balance_after': balanceAfter,
      if (docType != null) 'doc_type': docType,
      if (docId != null) 'doc_id': docId,
      if (docLineId != null) 'doc_line_id': docLineId,
      if (recordedById != null) 'recorded_by_id': recordedById,
      if (clientCreatedAt != null) 'client_created_at': clientCreatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? productId,
    Value<String>? qtyDelta,
    Value<String>? balanceAfter,
    Value<String>? docType,
    Value<String>? docId,
    Value<String?>? docLineId,
    Value<String>? recordedById,
    Value<DateTime>? clientCreatedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StockMovementsLocalCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      productId: productId ?? this.productId,
      qtyDelta: qtyDelta ?? this.qtyDelta,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      docType: docType ?? this.docType,
      docId: docId ?? this.docId,
      docLineId: docLineId ?? this.docLineId,
      recordedById: recordedById ?? this.recordedById,
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
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (qtyDelta.present) {
      map['qty_delta'] = Variable<String>(qtyDelta.value);
    }
    if (balanceAfter.present) {
      map['balance_after'] = Variable<String>(balanceAfter.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (docId.present) {
      map['doc_id'] = Variable<String>(docId.value);
    }
    if (docLineId.present) {
      map['doc_line_id'] = Variable<String>(docLineId.value);
    }
    if (recordedById.present) {
      map['recorded_by_id'] = Variable<String>(recordedById.value);
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
    return (StringBuffer('StockMovementsLocalCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('productId: $productId, ')
          ..write('qtyDelta: $qtyDelta, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('docType: $docType, ')
          ..write('docId: $docId, ')
          ..write('docLineId: $docLineId, ')
          ..write('recordedById: $recordedById, ')
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
  late final $CashCategoriesLocalTable cashCategoriesLocal =
      $CashCategoriesLocalTable(this);
  late final $CashVouchersLocalTable cashVouchersLocal =
      $CashVouchersLocalTable(this);
  late final $StockTransfersLocalTable stockTransfersLocal =
      $StockTransfersLocalTable(this);
  late final $StockTransferLinesLocalTable stockTransferLinesLocal =
      $StockTransferLinesLocalTable(this);
  late final $StocktakesLocalTable stocktakesLocal = $StocktakesLocalTable(
    this,
  );
  late final $StocktakeLinesLocalTable stocktakeLinesLocal =
      $StocktakeLinesLocalTable(this);
  late final $PurchaseReceiptsLocalTable purchaseReceiptsLocal =
      $PurchaseReceiptsLocalTable(this);
  late final $PurchaseReceiptLinesLocalTable purchaseReceiptLinesLocal =
      $PurchaseReceiptLinesLocalTable(this);
  late final $WastageVouchersLocalTable wastageVouchersLocal =
      $WastageVouchersLocalTable(this);
  late final $WastageVoucherLinesLocalTable wastageVoucherLinesLocal =
      $WastageVoucherLinesLocalTable(this);
  late final $StockMovementsLocalTable stockMovementsLocal =
      $StockMovementsLocalTable(this);
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
    cashCategoriesLocal,
    cashVouchersLocal,
    stockTransfersLocal,
    stockTransferLinesLocal,
    stocktakesLocal,
    stocktakeLinesLocal,
    purchaseReceiptsLocal,
    purchaseReceiptLinesLocal,
    wastageVouchersLocal,
    wastageVoucherLinesLocal,
    stockMovementsLocal,
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
      Value<int?> expectedCashVnd,
      Value<int?> varianceVnd,
      Value<int?> transferInShiftVnd,
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
      Value<int?> expectedCashVnd,
      Value<int?> varianceVnd,
      Value<int?> transferInShiftVnd,
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

  ColumnFilters<int> get expectedCashVnd => $composableBuilder(
    column: $table.expectedCashVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get varianceVnd => $composableBuilder(
    column: $table.varianceVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transferInShiftVnd => $composableBuilder(
    column: $table.transferInShiftVnd,
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

  ColumnOrderings<int> get expectedCashVnd => $composableBuilder(
    column: $table.expectedCashVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get varianceVnd => $composableBuilder(
    column: $table.varianceVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transferInShiftVnd => $composableBuilder(
    column: $table.transferInShiftVnd,
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

  GeneratedColumn<int> get expectedCashVnd => $composableBuilder(
    column: $table.expectedCashVnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get varianceVnd => $composableBuilder(
    column: $table.varianceVnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transferInShiftVnd => $composableBuilder(
    column: $table.transferInShiftVnd,
    builder: (column) => column,
  );
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
                Value<int?> expectedCashVnd = const Value.absent(),
                Value<int?> varianceVnd = const Value.absent(),
                Value<int?> transferInShiftVnd = const Value.absent(),
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
                expectedCashVnd: expectedCashVnd,
                varianceVnd: varianceVnd,
                transferInShiftVnd: transferInShiftVnd,
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
                Value<int?> expectedCashVnd = const Value.absent(),
                Value<int?> varianceVnd = const Value.absent(),
                Value<int?> transferInShiftVnd = const Value.absent(),
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
                expectedCashVnd: expectedCashVnd,
                varianceVnd: varianceVnd,
                transferInShiftVnd: transferInShiftVnd,
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
typedef $$CashCategoriesLocalTableCreateCompanionBuilder =
    CashCategoriesLocalCompanion Function({
      required String id,
      required String code,
      required String name,
      required String direction,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CashCategoriesLocalTableUpdateCompanionBuilder =
    CashCategoriesLocalCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<String> direction,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$CashCategoriesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CashCategoriesLocalTable> {
  $$CashCategoriesLocalTableFilterComposer({
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

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CashCategoriesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CashCategoriesLocalTable> {
  $$CashCategoriesLocalTableOrderingComposer({
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

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CashCategoriesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashCategoriesLocalTable> {
  $$CashCategoriesLocalTableAnnotationComposer({
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

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CashCategoriesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashCategoriesLocalTable,
          CashCategoriesLocalData,
          $$CashCategoriesLocalTableFilterComposer,
          $$CashCategoriesLocalTableOrderingComposer,
          $$CashCategoriesLocalTableAnnotationComposer,
          $$CashCategoriesLocalTableCreateCompanionBuilder,
          $$CashCategoriesLocalTableUpdateCompanionBuilder,
          (
            CashCategoriesLocalData,
            BaseReferences<
              _$AppDatabase,
              $CashCategoriesLocalTable,
              CashCategoriesLocalData
            >,
          ),
          CashCategoriesLocalData,
          PrefetchHooks Function()
        > {
  $$CashCategoriesLocalTableTableManager(
    _$AppDatabase db,
    $CashCategoriesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashCategoriesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashCategoriesLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CashCategoriesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashCategoriesLocalCompanion(
                id: id,
                code: code,
                name: name,
                direction: direction,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required String direction,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashCategoriesLocalCompanion.insert(
                id: id,
                code: code,
                name: name,
                direction: direction,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CashCategoriesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashCategoriesLocalTable,
      CashCategoriesLocalData,
      $$CashCategoriesLocalTableFilterComposer,
      $$CashCategoriesLocalTableOrderingComposer,
      $$CashCategoriesLocalTableAnnotationComposer,
      $$CashCategoriesLocalTableCreateCompanionBuilder,
      $$CashCategoriesLocalTableUpdateCompanionBuilder,
      (
        CashCategoriesLocalData,
        BaseReferences<
          _$AppDatabase,
          $CashCategoriesLocalTable,
          CashCategoriesLocalData
        >,
      ),
      CashCategoriesLocalData,
      PrefetchHooks Function()
    >;
typedef $$CashVouchersLocalTableCreateCompanionBuilder =
    CashVouchersLocalCompanion Function({
      required String id,
      required String storeId,
      required String shiftId,
      required String categoryId,
      required String direction,
      required String channel,
      required int amountVnd,
      Value<String?> note,
      required String recordedById,
      required DateTime clientCreatedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CashVouchersLocalTableUpdateCompanionBuilder =
    CashVouchersLocalCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> shiftId,
      Value<String> categoryId,
      Value<String> direction,
      Value<String> channel,
      Value<int> amountVnd,
      Value<String?> note,
      Value<String> recordedById,
      Value<DateTime> clientCreatedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CashVouchersLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CashVouchersLocalTable> {
  $$CashVouchersLocalTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountVnd => $composableBuilder(
    column: $table.amountVnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$CashVouchersLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CashVouchersLocalTable> {
  $$CashVouchersLocalTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountVnd => $composableBuilder(
    column: $table.amountVnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$CashVouchersLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashVouchersLocalTable> {
  $$CashVouchersLocalTableAnnotationComposer({
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

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<int> get amountVnd =>
      $composableBuilder(column: $table.amountVnd, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CashVouchersLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashVouchersLocalTable,
          CashVouchersLocalData,
          $$CashVouchersLocalTableFilterComposer,
          $$CashVouchersLocalTableOrderingComposer,
          $$CashVouchersLocalTableAnnotationComposer,
          $$CashVouchersLocalTableCreateCompanionBuilder,
          $$CashVouchersLocalTableUpdateCompanionBuilder,
          (
            CashVouchersLocalData,
            BaseReferences<
              _$AppDatabase,
              $CashVouchersLocalTable,
              CashVouchersLocalData
            >,
          ),
          CashVouchersLocalData,
          PrefetchHooks Function()
        > {
  $$CashVouchersLocalTableTableManager(
    _$AppDatabase db,
    $CashVouchersLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashVouchersLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashVouchersLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashVouchersLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<int> amountVnd = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> recordedById = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashVouchersLocalCompanion(
                id: id,
                storeId: storeId,
                shiftId: shiftId,
                categoryId: categoryId,
                direction: direction,
                channel: channel,
                amountVnd: amountVnd,
                note: note,
                recordedById: recordedById,
                clientCreatedAt: clientCreatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String shiftId,
                required String categoryId,
                required String direction,
                required String channel,
                required int amountVnd,
                Value<String?> note = const Value.absent(),
                required String recordedById,
                required DateTime clientCreatedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CashVouchersLocalCompanion.insert(
                id: id,
                storeId: storeId,
                shiftId: shiftId,
                categoryId: categoryId,
                direction: direction,
                channel: channel,
                amountVnd: amountVnd,
                note: note,
                recordedById: recordedById,
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

typedef $$CashVouchersLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashVouchersLocalTable,
      CashVouchersLocalData,
      $$CashVouchersLocalTableFilterComposer,
      $$CashVouchersLocalTableOrderingComposer,
      $$CashVouchersLocalTableAnnotationComposer,
      $$CashVouchersLocalTableCreateCompanionBuilder,
      $$CashVouchersLocalTableUpdateCompanionBuilder,
      (
        CashVouchersLocalData,
        BaseReferences<
          _$AppDatabase,
          $CashVouchersLocalTable,
          CashVouchersLocalData
        >,
      ),
      CashVouchersLocalData,
      PrefetchHooks Function()
    >;
typedef $$StockTransfersLocalTableCreateCompanionBuilder =
    StockTransfersLocalCompanion Function({
      required String id,
      required String fromStoreId,
      required String toStoreId,
      required String status,
      Value<String?> note,
      required String createdById,
      Value<String?> approvedById,
      Value<String?> receivedById,
      required DateTime clientCreatedAt,
      Value<DateTime?> approvedAt,
      Value<DateTime?> receivedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StockTransfersLocalTableUpdateCompanionBuilder =
    StockTransfersLocalCompanion Function({
      Value<String> id,
      Value<String> fromStoreId,
      Value<String> toStoreId,
      Value<String> status,
      Value<String?> note,
      Value<String> createdById,
      Value<String?> approvedById,
      Value<String?> receivedById,
      Value<DateTime> clientCreatedAt,
      Value<DateTime?> approvedAt,
      Value<DateTime?> receivedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StockTransfersLocalTableFilterComposer
    extends Composer<_$AppDatabase, $StockTransfersLocalTable> {
  $$StockTransfersLocalTableFilterComposer({
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

  ColumnFilters<String> get fromStoreId => $composableBuilder(
    column: $table.fromStoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toStoreId => $composableBuilder(
    column: $table.toStoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivedById => $composableBuilder(
    column: $table.receivedById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockTransfersLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $StockTransfersLocalTable> {
  $$StockTransfersLocalTableOrderingComposer({
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

  ColumnOrderings<String> get fromStoreId => $composableBuilder(
    column: $table.fromStoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toStoreId => $composableBuilder(
    column: $table.toStoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivedById => $composableBuilder(
    column: $table.receivedById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockTransfersLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockTransfersLocalTable> {
  $$StockTransfersLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromStoreId => $composableBuilder(
    column: $table.fromStoreId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toStoreId =>
      $composableBuilder(column: $table.toStoreId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdById => $composableBuilder(
    column: $table.createdById,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvedById => $composableBuilder(
    column: $table.approvedById,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receivedById => $composableBuilder(
    column: $table.receivedById,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get approvedAt => $composableBuilder(
    column: $table.approvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StockTransfersLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockTransfersLocalTable,
          StockTransfersLocalData,
          $$StockTransfersLocalTableFilterComposer,
          $$StockTransfersLocalTableOrderingComposer,
          $$StockTransfersLocalTableAnnotationComposer,
          $$StockTransfersLocalTableCreateCompanionBuilder,
          $$StockTransfersLocalTableUpdateCompanionBuilder,
          (
            StockTransfersLocalData,
            BaseReferences<
              _$AppDatabase,
              $StockTransfersLocalTable,
              StockTransfersLocalData
            >,
          ),
          StockTransfersLocalData,
          PrefetchHooks Function()
        > {
  $$StockTransfersLocalTableTableManager(
    _$AppDatabase db,
    $StockTransfersLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockTransfersLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockTransfersLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StockTransfersLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fromStoreId = const Value.absent(),
                Value<String> toStoreId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdById = const Value.absent(),
                Value<String?> approvedById = const Value.absent(),
                Value<String?> receivedById = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<DateTime?> receivedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockTransfersLocalCompanion(
                id: id,
                fromStoreId: fromStoreId,
                toStoreId: toStoreId,
                status: status,
                note: note,
                createdById: createdById,
                approvedById: approvedById,
                receivedById: receivedById,
                clientCreatedAt: clientCreatedAt,
                approvedAt: approvedAt,
                receivedAt: receivedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fromStoreId,
                required String toStoreId,
                required String status,
                Value<String?> note = const Value.absent(),
                required String createdById,
                Value<String?> approvedById = const Value.absent(),
                Value<String?> receivedById = const Value.absent(),
                required DateTime clientCreatedAt,
                Value<DateTime?> approvedAt = const Value.absent(),
                Value<DateTime?> receivedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StockTransfersLocalCompanion.insert(
                id: id,
                fromStoreId: fromStoreId,
                toStoreId: toStoreId,
                status: status,
                note: note,
                createdById: createdById,
                approvedById: approvedById,
                receivedById: receivedById,
                clientCreatedAt: clientCreatedAt,
                approvedAt: approvedAt,
                receivedAt: receivedAt,
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

typedef $$StockTransfersLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockTransfersLocalTable,
      StockTransfersLocalData,
      $$StockTransfersLocalTableFilterComposer,
      $$StockTransfersLocalTableOrderingComposer,
      $$StockTransfersLocalTableAnnotationComposer,
      $$StockTransfersLocalTableCreateCompanionBuilder,
      $$StockTransfersLocalTableUpdateCompanionBuilder,
      (
        StockTransfersLocalData,
        BaseReferences<
          _$AppDatabase,
          $StockTransfersLocalTable,
          StockTransfersLocalData
        >,
      ),
      StockTransfersLocalData,
      PrefetchHooks Function()
    >;
typedef $$StockTransferLinesLocalTableCreateCompanionBuilder =
    StockTransferLinesLocalCompanion Function({
      required String id,
      required String transferId,
      required String productId,
      required String qty,
      Value<int> rowid,
    });
typedef $$StockTransferLinesLocalTableUpdateCompanionBuilder =
    StockTransferLinesLocalCompanion Function({
      Value<String> id,
      Value<String> transferId,
      Value<String> productId,
      Value<String> qty,
      Value<int> rowid,
    });

class $$StockTransferLinesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $StockTransferLinesLocalTable> {
  $$StockTransferLinesLocalTableFilterComposer({
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

  ColumnFilters<String> get transferId => $composableBuilder(
    column: $table.transferId,
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
}

class $$StockTransferLinesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $StockTransferLinesLocalTable> {
  $$StockTransferLinesLocalTableOrderingComposer({
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

  ColumnOrderings<String> get transferId => $composableBuilder(
    column: $table.transferId,
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
}

class $$StockTransferLinesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockTransferLinesLocalTable> {
  $$StockTransferLinesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);
}

class $$StockTransferLinesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockTransferLinesLocalTable,
          StockTransferLinesLocalData,
          $$StockTransferLinesLocalTableFilterComposer,
          $$StockTransferLinesLocalTableOrderingComposer,
          $$StockTransferLinesLocalTableAnnotationComposer,
          $$StockTransferLinesLocalTableCreateCompanionBuilder,
          $$StockTransferLinesLocalTableUpdateCompanionBuilder,
          (
            StockTransferLinesLocalData,
            BaseReferences<
              _$AppDatabase,
              $StockTransferLinesLocalTable,
              StockTransferLinesLocalData
            >,
          ),
          StockTransferLinesLocalData,
          PrefetchHooks Function()
        > {
  $$StockTransferLinesLocalTableTableManager(
    _$AppDatabase db,
    $StockTransferLinesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockTransferLinesLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$StockTransferLinesLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StockTransferLinesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transferId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> qty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockTransferLinesLocalCompanion(
                id: id,
                transferId: transferId,
                productId: productId,
                qty: qty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transferId,
                required String productId,
                required String qty,
                Value<int> rowid = const Value.absent(),
              }) => StockTransferLinesLocalCompanion.insert(
                id: id,
                transferId: transferId,
                productId: productId,
                qty: qty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockTransferLinesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockTransferLinesLocalTable,
      StockTransferLinesLocalData,
      $$StockTransferLinesLocalTableFilterComposer,
      $$StockTransferLinesLocalTableOrderingComposer,
      $$StockTransferLinesLocalTableAnnotationComposer,
      $$StockTransferLinesLocalTableCreateCompanionBuilder,
      $$StockTransferLinesLocalTableUpdateCompanionBuilder,
      (
        StockTransferLinesLocalData,
        BaseReferences<
          _$AppDatabase,
          $StockTransferLinesLocalTable,
          StockTransferLinesLocalData
        >,
      ),
      StockTransferLinesLocalData,
      PrefetchHooks Function()
    >;
typedef $$StocktakesLocalTableCreateCompanionBuilder =
    StocktakesLocalCompanion Function({
      required String id,
      required String storeId,
      Value<String?> note,
      required String recordedById,
      required DateTime clientCreatedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StocktakesLocalTableUpdateCompanionBuilder =
    StocktakesLocalCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String?> note,
      Value<String> recordedById,
      Value<DateTime> clientCreatedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StocktakesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $StocktakesLocalTable> {
  $$StocktakesLocalTableFilterComposer({
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

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$StocktakesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $StocktakesLocalTable> {
  $$StocktakesLocalTableOrderingComposer({
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

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$StocktakesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $StocktakesLocalTable> {
  $$StocktakesLocalTableAnnotationComposer({
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

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StocktakesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StocktakesLocalTable,
          StocktakesLocalData,
          $$StocktakesLocalTableFilterComposer,
          $$StocktakesLocalTableOrderingComposer,
          $$StocktakesLocalTableAnnotationComposer,
          $$StocktakesLocalTableCreateCompanionBuilder,
          $$StocktakesLocalTableUpdateCompanionBuilder,
          (
            StocktakesLocalData,
            BaseReferences<
              _$AppDatabase,
              $StocktakesLocalTable,
              StocktakesLocalData
            >,
          ),
          StocktakesLocalData,
          PrefetchHooks Function()
        > {
  $$StocktakesLocalTableTableManager(
    _$AppDatabase db,
    $StocktakesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StocktakesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StocktakesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StocktakesLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> recordedById = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StocktakesLocalCompanion(
                id: id,
                storeId: storeId,
                note: note,
                recordedById: recordedById,
                clientCreatedAt: clientCreatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                Value<String?> note = const Value.absent(),
                required String recordedById,
                required DateTime clientCreatedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StocktakesLocalCompanion.insert(
                id: id,
                storeId: storeId,
                note: note,
                recordedById: recordedById,
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

typedef $$StocktakesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StocktakesLocalTable,
      StocktakesLocalData,
      $$StocktakesLocalTableFilterComposer,
      $$StocktakesLocalTableOrderingComposer,
      $$StocktakesLocalTableAnnotationComposer,
      $$StocktakesLocalTableCreateCompanionBuilder,
      $$StocktakesLocalTableUpdateCompanionBuilder,
      (
        StocktakesLocalData,
        BaseReferences<
          _$AppDatabase,
          $StocktakesLocalTable,
          StocktakesLocalData
        >,
      ),
      StocktakesLocalData,
      PrefetchHooks Function()
    >;
typedef $$StocktakeLinesLocalTableCreateCompanionBuilder =
    StocktakeLinesLocalCompanion Function({
      required String id,
      required String stocktakeId,
      required String productId,
      required String systemQty,
      required String countedQty,
      required String varianceQty,
      required String reason,
      Value<String?> reasonNote,
      Value<int> rowid,
    });
typedef $$StocktakeLinesLocalTableUpdateCompanionBuilder =
    StocktakeLinesLocalCompanion Function({
      Value<String> id,
      Value<String> stocktakeId,
      Value<String> productId,
      Value<String> systemQty,
      Value<String> countedQty,
      Value<String> varianceQty,
      Value<String> reason,
      Value<String?> reasonNote,
      Value<int> rowid,
    });

class $$StocktakeLinesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $StocktakeLinesLocalTable> {
  $$StocktakeLinesLocalTableFilterComposer({
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

  ColumnFilters<String> get stocktakeId => $composableBuilder(
    column: $table.stocktakeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemQty => $composableBuilder(
    column: $table.systemQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countedQty => $composableBuilder(
    column: $table.countedQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get varianceQty => $composableBuilder(
    column: $table.varianceQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonNote => $composableBuilder(
    column: $table.reasonNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StocktakeLinesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $StocktakeLinesLocalTable> {
  $$StocktakeLinesLocalTableOrderingComposer({
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

  ColumnOrderings<String> get stocktakeId => $composableBuilder(
    column: $table.stocktakeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemQty => $composableBuilder(
    column: $table.systemQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countedQty => $composableBuilder(
    column: $table.countedQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get varianceQty => $composableBuilder(
    column: $table.varianceQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonNote => $composableBuilder(
    column: $table.reasonNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StocktakeLinesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $StocktakeLinesLocalTable> {
  $$StocktakeLinesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stocktakeId => $composableBuilder(
    column: $table.stocktakeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get systemQty =>
      $composableBuilder(column: $table.systemQty, builder: (column) => column);

  GeneratedColumn<String> get countedQty => $composableBuilder(
    column: $table.countedQty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get varianceQty => $composableBuilder(
    column: $table.varianceQty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get reasonNote => $composableBuilder(
    column: $table.reasonNote,
    builder: (column) => column,
  );
}

class $$StocktakeLinesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StocktakeLinesLocalTable,
          StocktakeLinesLocalData,
          $$StocktakeLinesLocalTableFilterComposer,
          $$StocktakeLinesLocalTableOrderingComposer,
          $$StocktakeLinesLocalTableAnnotationComposer,
          $$StocktakeLinesLocalTableCreateCompanionBuilder,
          $$StocktakeLinesLocalTableUpdateCompanionBuilder,
          (
            StocktakeLinesLocalData,
            BaseReferences<
              _$AppDatabase,
              $StocktakeLinesLocalTable,
              StocktakeLinesLocalData
            >,
          ),
          StocktakeLinesLocalData,
          PrefetchHooks Function()
        > {
  $$StocktakeLinesLocalTableTableManager(
    _$AppDatabase db,
    $StocktakeLinesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StocktakeLinesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StocktakeLinesLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StocktakeLinesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> stocktakeId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> systemQty = const Value.absent(),
                Value<String> countedQty = const Value.absent(),
                Value<String> varianceQty = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> reasonNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StocktakeLinesLocalCompanion(
                id: id,
                stocktakeId: stocktakeId,
                productId: productId,
                systemQty: systemQty,
                countedQty: countedQty,
                varianceQty: varianceQty,
                reason: reason,
                reasonNote: reasonNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String stocktakeId,
                required String productId,
                required String systemQty,
                required String countedQty,
                required String varianceQty,
                required String reason,
                Value<String?> reasonNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StocktakeLinesLocalCompanion.insert(
                id: id,
                stocktakeId: stocktakeId,
                productId: productId,
                systemQty: systemQty,
                countedQty: countedQty,
                varianceQty: varianceQty,
                reason: reason,
                reasonNote: reasonNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StocktakeLinesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StocktakeLinesLocalTable,
      StocktakeLinesLocalData,
      $$StocktakeLinesLocalTableFilterComposer,
      $$StocktakeLinesLocalTableOrderingComposer,
      $$StocktakeLinesLocalTableAnnotationComposer,
      $$StocktakeLinesLocalTableCreateCompanionBuilder,
      $$StocktakeLinesLocalTableUpdateCompanionBuilder,
      (
        StocktakeLinesLocalData,
        BaseReferences<
          _$AppDatabase,
          $StocktakeLinesLocalTable,
          StocktakeLinesLocalData
        >,
      ),
      StocktakeLinesLocalData,
      PrefetchHooks Function()
    >;
typedef $$PurchaseReceiptsLocalTableCreateCompanionBuilder =
    PurchaseReceiptsLocalCompanion Function({
      required String id,
      required String storeId,
      required String supplierName,
      Value<String?> supplierPhone,
      Value<String?> note,
      required String recordedById,
      required DateTime clientCreatedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PurchaseReceiptsLocalTableUpdateCompanionBuilder =
    PurchaseReceiptsLocalCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> supplierName,
      Value<String?> supplierPhone,
      Value<String?> note,
      Value<String> recordedById,
      Value<DateTime> clientCreatedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PurchaseReceiptsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseReceiptsLocalTable> {
  $$PurchaseReceiptsLocalTableFilterComposer({
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

  ColumnFilters<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplierPhone => $composableBuilder(
    column: $table.supplierPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$PurchaseReceiptsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseReceiptsLocalTable> {
  $$PurchaseReceiptsLocalTableOrderingComposer({
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

  ColumnOrderings<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplierPhone => $composableBuilder(
    column: $table.supplierPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$PurchaseReceiptsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseReceiptsLocalTable> {
  $$PurchaseReceiptsLocalTableAnnotationComposer({
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

  GeneratedColumn<String> get supplierName => $composableBuilder(
    column: $table.supplierName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplierPhone => $composableBuilder(
    column: $table.supplierPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PurchaseReceiptsLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseReceiptsLocalTable,
          PurchaseReceiptsLocalData,
          $$PurchaseReceiptsLocalTableFilterComposer,
          $$PurchaseReceiptsLocalTableOrderingComposer,
          $$PurchaseReceiptsLocalTableAnnotationComposer,
          $$PurchaseReceiptsLocalTableCreateCompanionBuilder,
          $$PurchaseReceiptsLocalTableUpdateCompanionBuilder,
          (
            PurchaseReceiptsLocalData,
            BaseReferences<
              _$AppDatabase,
              $PurchaseReceiptsLocalTable,
              PurchaseReceiptsLocalData
            >,
          ),
          PurchaseReceiptsLocalData,
          PrefetchHooks Function()
        > {
  $$PurchaseReceiptsLocalTableTableManager(
    _$AppDatabase db,
    $PurchaseReceiptsLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseReceiptsLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PurchaseReceiptsLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PurchaseReceiptsLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> supplierName = const Value.absent(),
                Value<String?> supplierPhone = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> recordedById = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseReceiptsLocalCompanion(
                id: id,
                storeId: storeId,
                supplierName: supplierName,
                supplierPhone: supplierPhone,
                note: note,
                recordedById: recordedById,
                clientCreatedAt: clientCreatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String supplierName,
                Value<String?> supplierPhone = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String recordedById,
                required DateTime clientCreatedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PurchaseReceiptsLocalCompanion.insert(
                id: id,
                storeId: storeId,
                supplierName: supplierName,
                supplierPhone: supplierPhone,
                note: note,
                recordedById: recordedById,
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

typedef $$PurchaseReceiptsLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseReceiptsLocalTable,
      PurchaseReceiptsLocalData,
      $$PurchaseReceiptsLocalTableFilterComposer,
      $$PurchaseReceiptsLocalTableOrderingComposer,
      $$PurchaseReceiptsLocalTableAnnotationComposer,
      $$PurchaseReceiptsLocalTableCreateCompanionBuilder,
      $$PurchaseReceiptsLocalTableUpdateCompanionBuilder,
      (
        PurchaseReceiptsLocalData,
        BaseReferences<
          _$AppDatabase,
          $PurchaseReceiptsLocalTable,
          PurchaseReceiptsLocalData
        >,
      ),
      PurchaseReceiptsLocalData,
      PrefetchHooks Function()
    >;
typedef $$PurchaseReceiptLinesLocalTableCreateCompanionBuilder =
    PurchaseReceiptLinesLocalCompanion Function({
      required String id,
      required String receiptId,
      required String productId,
      required String qty,
      Value<int?> unitCostVnd,
      Value<int> rowid,
    });
typedef $$PurchaseReceiptLinesLocalTableUpdateCompanionBuilder =
    PurchaseReceiptLinesLocalCompanion Function({
      Value<String> id,
      Value<String> receiptId,
      Value<String> productId,
      Value<String> qty,
      Value<int?> unitCostVnd,
      Value<int> rowid,
    });

class $$PurchaseReceiptLinesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseReceiptLinesLocalTable> {
  $$PurchaseReceiptLinesLocalTableFilterComposer({
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

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
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

  ColumnFilters<int> get unitCostVnd => $composableBuilder(
    column: $table.unitCostVnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchaseReceiptLinesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseReceiptLinesLocalTable> {
  $$PurchaseReceiptLinesLocalTableOrderingComposer({
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

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
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

  ColumnOrderings<int> get unitCostVnd => $composableBuilder(
    column: $table.unitCostVnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchaseReceiptLinesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseReceiptLinesLocalTable> {
  $$PurchaseReceiptLinesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get unitCostVnd => $composableBuilder(
    column: $table.unitCostVnd,
    builder: (column) => column,
  );
}

class $$PurchaseReceiptLinesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseReceiptLinesLocalTable,
          PurchaseReceiptLinesLocalData,
          $$PurchaseReceiptLinesLocalTableFilterComposer,
          $$PurchaseReceiptLinesLocalTableOrderingComposer,
          $$PurchaseReceiptLinesLocalTableAnnotationComposer,
          $$PurchaseReceiptLinesLocalTableCreateCompanionBuilder,
          $$PurchaseReceiptLinesLocalTableUpdateCompanionBuilder,
          (
            PurchaseReceiptLinesLocalData,
            BaseReferences<
              _$AppDatabase,
              $PurchaseReceiptLinesLocalTable,
              PurchaseReceiptLinesLocalData
            >,
          ),
          PurchaseReceiptLinesLocalData,
          PrefetchHooks Function()
        > {
  $$PurchaseReceiptLinesLocalTableTableManager(
    _$AppDatabase db,
    $PurchaseReceiptLinesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseReceiptLinesLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PurchaseReceiptLinesLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PurchaseReceiptLinesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> qty = const Value.absent(),
                Value<int?> unitCostVnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseReceiptLinesLocalCompanion(
                id: id,
                receiptId: receiptId,
                productId: productId,
                qty: qty,
                unitCostVnd: unitCostVnd,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptId,
                required String productId,
                required String qty,
                Value<int?> unitCostVnd = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseReceiptLinesLocalCompanion.insert(
                id: id,
                receiptId: receiptId,
                productId: productId,
                qty: qty,
                unitCostVnd: unitCostVnd,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchaseReceiptLinesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseReceiptLinesLocalTable,
      PurchaseReceiptLinesLocalData,
      $$PurchaseReceiptLinesLocalTableFilterComposer,
      $$PurchaseReceiptLinesLocalTableOrderingComposer,
      $$PurchaseReceiptLinesLocalTableAnnotationComposer,
      $$PurchaseReceiptLinesLocalTableCreateCompanionBuilder,
      $$PurchaseReceiptLinesLocalTableUpdateCompanionBuilder,
      (
        PurchaseReceiptLinesLocalData,
        BaseReferences<
          _$AppDatabase,
          $PurchaseReceiptLinesLocalTable,
          PurchaseReceiptLinesLocalData
        >,
      ),
      PurchaseReceiptLinesLocalData,
      PrefetchHooks Function()
    >;
typedef $$WastageVouchersLocalTableCreateCompanionBuilder =
    WastageVouchersLocalCompanion Function({
      required String id,
      required String storeId,
      required String reasonCode,
      Value<String?> note,
      required String recordedById,
      required DateTime clientCreatedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WastageVouchersLocalTableUpdateCompanionBuilder =
    WastageVouchersLocalCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> reasonCode,
      Value<String?> note,
      Value<String> recordedById,
      Value<DateTime> clientCreatedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WastageVouchersLocalTableFilterComposer
    extends Composer<_$AppDatabase, $WastageVouchersLocalTable> {
  $$WastageVouchersLocalTableFilterComposer({
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

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$WastageVouchersLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $WastageVouchersLocalTable> {
  $$WastageVouchersLocalTableOrderingComposer({
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

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$WastageVouchersLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $WastageVouchersLocalTable> {
  $$WastageVouchersLocalTableAnnotationComposer({
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

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WastageVouchersLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WastageVouchersLocalTable,
          WastageVouchersLocalData,
          $$WastageVouchersLocalTableFilterComposer,
          $$WastageVouchersLocalTableOrderingComposer,
          $$WastageVouchersLocalTableAnnotationComposer,
          $$WastageVouchersLocalTableCreateCompanionBuilder,
          $$WastageVouchersLocalTableUpdateCompanionBuilder,
          (
            WastageVouchersLocalData,
            BaseReferences<
              _$AppDatabase,
              $WastageVouchersLocalTable,
              WastageVouchersLocalData
            >,
          ),
          WastageVouchersLocalData,
          PrefetchHooks Function()
        > {
  $$WastageVouchersLocalTableTableManager(
    _$AppDatabase db,
    $WastageVouchersLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WastageVouchersLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WastageVouchersLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WastageVouchersLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> reasonCode = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> recordedById = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WastageVouchersLocalCompanion(
                id: id,
                storeId: storeId,
                reasonCode: reasonCode,
                note: note,
                recordedById: recordedById,
                clientCreatedAt: clientCreatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String reasonCode,
                Value<String?> note = const Value.absent(),
                required String recordedById,
                required DateTime clientCreatedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WastageVouchersLocalCompanion.insert(
                id: id,
                storeId: storeId,
                reasonCode: reasonCode,
                note: note,
                recordedById: recordedById,
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

typedef $$WastageVouchersLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WastageVouchersLocalTable,
      WastageVouchersLocalData,
      $$WastageVouchersLocalTableFilterComposer,
      $$WastageVouchersLocalTableOrderingComposer,
      $$WastageVouchersLocalTableAnnotationComposer,
      $$WastageVouchersLocalTableCreateCompanionBuilder,
      $$WastageVouchersLocalTableUpdateCompanionBuilder,
      (
        WastageVouchersLocalData,
        BaseReferences<
          _$AppDatabase,
          $WastageVouchersLocalTable,
          WastageVouchersLocalData
        >,
      ),
      WastageVouchersLocalData,
      PrefetchHooks Function()
    >;
typedef $$WastageVoucherLinesLocalTableCreateCompanionBuilder =
    WastageVoucherLinesLocalCompanion Function({
      required String id,
      required String wastageId,
      required String productId,
      required String qty,
      Value<int> rowid,
    });
typedef $$WastageVoucherLinesLocalTableUpdateCompanionBuilder =
    WastageVoucherLinesLocalCompanion Function({
      Value<String> id,
      Value<String> wastageId,
      Value<String> productId,
      Value<String> qty,
      Value<int> rowid,
    });

class $$WastageVoucherLinesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $WastageVoucherLinesLocalTable> {
  $$WastageVoucherLinesLocalTableFilterComposer({
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

  ColumnFilters<String> get wastageId => $composableBuilder(
    column: $table.wastageId,
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
}

class $$WastageVoucherLinesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $WastageVoucherLinesLocalTable> {
  $$WastageVoucherLinesLocalTableOrderingComposer({
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

  ColumnOrderings<String> get wastageId => $composableBuilder(
    column: $table.wastageId,
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
}

class $$WastageVoucherLinesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $WastageVoucherLinesLocalTable> {
  $$WastageVoucherLinesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get wastageId =>
      $composableBuilder(column: $table.wastageId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);
}

class $$WastageVoucherLinesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WastageVoucherLinesLocalTable,
          WastageVoucherLinesLocalData,
          $$WastageVoucherLinesLocalTableFilterComposer,
          $$WastageVoucherLinesLocalTableOrderingComposer,
          $$WastageVoucherLinesLocalTableAnnotationComposer,
          $$WastageVoucherLinesLocalTableCreateCompanionBuilder,
          $$WastageVoucherLinesLocalTableUpdateCompanionBuilder,
          (
            WastageVoucherLinesLocalData,
            BaseReferences<
              _$AppDatabase,
              $WastageVoucherLinesLocalTable,
              WastageVoucherLinesLocalData
            >,
          ),
          WastageVoucherLinesLocalData,
          PrefetchHooks Function()
        > {
  $$WastageVoucherLinesLocalTableTableManager(
    _$AppDatabase db,
    $WastageVoucherLinesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WastageVoucherLinesLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WastageVoucherLinesLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WastageVoucherLinesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> wastageId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> qty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WastageVoucherLinesLocalCompanion(
                id: id,
                wastageId: wastageId,
                productId: productId,
                qty: qty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String wastageId,
                required String productId,
                required String qty,
                Value<int> rowid = const Value.absent(),
              }) => WastageVoucherLinesLocalCompanion.insert(
                id: id,
                wastageId: wastageId,
                productId: productId,
                qty: qty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WastageVoucherLinesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WastageVoucherLinesLocalTable,
      WastageVoucherLinesLocalData,
      $$WastageVoucherLinesLocalTableFilterComposer,
      $$WastageVoucherLinesLocalTableOrderingComposer,
      $$WastageVoucherLinesLocalTableAnnotationComposer,
      $$WastageVoucherLinesLocalTableCreateCompanionBuilder,
      $$WastageVoucherLinesLocalTableUpdateCompanionBuilder,
      (
        WastageVoucherLinesLocalData,
        BaseReferences<
          _$AppDatabase,
          $WastageVoucherLinesLocalTable,
          WastageVoucherLinesLocalData
        >,
      ),
      WastageVoucherLinesLocalData,
      PrefetchHooks Function()
    >;
typedef $$StockMovementsLocalTableCreateCompanionBuilder =
    StockMovementsLocalCompanion Function({
      required String id,
      required String storeId,
      required String productId,
      required String qtyDelta,
      required String balanceAfter,
      required String docType,
      required String docId,
      Value<String?> docLineId,
      required String recordedById,
      required DateTime clientCreatedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StockMovementsLocalTableUpdateCompanionBuilder =
    StockMovementsLocalCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> productId,
      Value<String> qtyDelta,
      Value<String> balanceAfter,
      Value<String> docType,
      Value<String> docId,
      Value<String?> docLineId,
      Value<String> recordedById,
      Value<DateTime> clientCreatedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StockMovementsLocalTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsLocalTable> {
  $$StockMovementsLocalTableFilterComposer({
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

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qtyDelta => $composableBuilder(
    column: $table.qtyDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get docLineId => $composableBuilder(
    column: $table.docLineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$StockMovementsLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsLocalTable> {
  $$StockMovementsLocalTableOrderingComposer({
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

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qtyDelta => $composableBuilder(
    column: $table.qtyDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docType => $composableBuilder(
    column: $table.docType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docId => $composableBuilder(
    column: $table.docId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get docLineId => $composableBuilder(
    column: $table.docLineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
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

class $$StockMovementsLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsLocalTable> {
  $$StockMovementsLocalTableAnnotationComposer({
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

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get qtyDelta =>
      $composableBuilder(column: $table.qtyDelta, builder: (column) => column);

  GeneratedColumn<String> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<String> get docId =>
      $composableBuilder(column: $table.docId, builder: (column) => column);

  GeneratedColumn<String> get docLineId =>
      $composableBuilder(column: $table.docLineId, builder: (column) => column);

  GeneratedColumn<String> get recordedById => $composableBuilder(
    column: $table.recordedById,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clientCreatedAt => $composableBuilder(
    column: $table.clientCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StockMovementsLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockMovementsLocalTable,
          StockMovementsLocalData,
          $$StockMovementsLocalTableFilterComposer,
          $$StockMovementsLocalTableOrderingComposer,
          $$StockMovementsLocalTableAnnotationComposer,
          $$StockMovementsLocalTableCreateCompanionBuilder,
          $$StockMovementsLocalTableUpdateCompanionBuilder,
          (
            StockMovementsLocalData,
            BaseReferences<
              _$AppDatabase,
              $StockMovementsLocalTable,
              StockMovementsLocalData
            >,
          ),
          StockMovementsLocalData,
          PrefetchHooks Function()
        > {
  $$StockMovementsLocalTableTableManager(
    _$AppDatabase db,
    $StockMovementsLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StockMovementsLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> qtyDelta = const Value.absent(),
                Value<String> balanceAfter = const Value.absent(),
                Value<String> docType = const Value.absent(),
                Value<String> docId = const Value.absent(),
                Value<String?> docLineId = const Value.absent(),
                Value<String> recordedById = const Value.absent(),
                Value<DateTime> clientCreatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsLocalCompanion(
                id: id,
                storeId: storeId,
                productId: productId,
                qtyDelta: qtyDelta,
                balanceAfter: balanceAfter,
                docType: docType,
                docId: docId,
                docLineId: docLineId,
                recordedById: recordedById,
                clientCreatedAt: clientCreatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String productId,
                required String qtyDelta,
                required String balanceAfter,
                required String docType,
                required String docId,
                Value<String?> docLineId = const Value.absent(),
                required String recordedById,
                required DateTime clientCreatedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsLocalCompanion.insert(
                id: id,
                storeId: storeId,
                productId: productId,
                qtyDelta: qtyDelta,
                balanceAfter: balanceAfter,
                docType: docType,
                docId: docId,
                docLineId: docLineId,
                recordedById: recordedById,
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

typedef $$StockMovementsLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockMovementsLocalTable,
      StockMovementsLocalData,
      $$StockMovementsLocalTableFilterComposer,
      $$StockMovementsLocalTableOrderingComposer,
      $$StockMovementsLocalTableAnnotationComposer,
      $$StockMovementsLocalTableCreateCompanionBuilder,
      $$StockMovementsLocalTableUpdateCompanionBuilder,
      (
        StockMovementsLocalData,
        BaseReferences<
          _$AppDatabase,
          $StockMovementsLocalTable,
          StockMovementsLocalData
        >,
      ),
      StockMovementsLocalData,
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
  $$CashCategoriesLocalTableTableManager get cashCategoriesLocal =>
      $$CashCategoriesLocalTableTableManager(_db, _db.cashCategoriesLocal);
  $$CashVouchersLocalTableTableManager get cashVouchersLocal =>
      $$CashVouchersLocalTableTableManager(_db, _db.cashVouchersLocal);
  $$StockTransfersLocalTableTableManager get stockTransfersLocal =>
      $$StockTransfersLocalTableTableManager(_db, _db.stockTransfersLocal);
  $$StockTransferLinesLocalTableTableManager get stockTransferLinesLocal =>
      $$StockTransferLinesLocalTableTableManager(
        _db,
        _db.stockTransferLinesLocal,
      );
  $$StocktakesLocalTableTableManager get stocktakesLocal =>
      $$StocktakesLocalTableTableManager(_db, _db.stocktakesLocal);
  $$StocktakeLinesLocalTableTableManager get stocktakeLinesLocal =>
      $$StocktakeLinesLocalTableTableManager(_db, _db.stocktakeLinesLocal);
  $$PurchaseReceiptsLocalTableTableManager get purchaseReceiptsLocal =>
      $$PurchaseReceiptsLocalTableTableManager(_db, _db.purchaseReceiptsLocal);
  $$PurchaseReceiptLinesLocalTableTableManager get purchaseReceiptLinesLocal =>
      $$PurchaseReceiptLinesLocalTableTableManager(
        _db,
        _db.purchaseReceiptLinesLocal,
      );
  $$WastageVouchersLocalTableTableManager get wastageVouchersLocal =>
      $$WastageVouchersLocalTableTableManager(_db, _db.wastageVouchersLocal);
  $$WastageVoucherLinesLocalTableTableManager get wastageVoucherLinesLocal =>
      $$WastageVoucherLinesLocalTableTableManager(
        _db,
        _db.wastageVoucherLinesLocal,
      );
  $$StockMovementsLocalTableTableManager get stockMovementsLocal =>
      $$StockMovementsLocalTableTableManager(_db, _db.stockMovementsLocal);
}
