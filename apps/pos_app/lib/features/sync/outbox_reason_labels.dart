String? labelOutboxReason(String? code) {
  if (code == null) {
    return null;
  }
  return switch (code) {
    'insufficient_stock' => 'Không đủ tồn kho',
    'sku_conflict' => 'Trùng mã SKU',
    'barcode_conflict' => 'Trùng mã vạch',
    'credit_limit_exceeded' => 'Vượt hạn mức nợ',
    'store_forbidden' || 'role_forbidden' => 'Không có quyền / cửa hàng',
    'shift_not_open' || 'shift_not_found' => 'Ca chưa mở / không tìm thấy ca',
    'invalid_payload' || 'invalid_qty' => 'Dữ liệu không hợp lệ',
    _ => code,
  };
}

String labelEntityType(String entityType) {
  return switch (entityType) {
    'sale' => 'Bán hàng',
    'wastage' => 'Phiếu xuất hủy',
    'product_upsert' => 'Sản phẩm',
    'shift_open' => 'Mở ca',
    'shift_close' => 'Đóng ca',
    'debt_payment' => 'Thu nợ',
    'cash_voucher' => 'Phiếu thu/chi',
    'customer_upsert' => 'Khách hàng',
    'stock_transfer_create' => 'Chuyển kho',
    'stock_transfer_approve' => 'Duyệt chuyển kho',
    'stock_transfer_reject' => 'Từ chối chuyển kho',
    'stock_transfer_receive' => 'Nhận chuyển kho',
    'stocktake' => 'Kiểm kê',
    'purchase_receipt' => 'Nhập hàng',
    _ => entityType,
  };
}
