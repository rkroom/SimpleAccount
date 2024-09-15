enum Transaction {
  income("income"),
  consume("consume"),
  transfer("transfer");

  // 定义一个存储字符串值的字段
  final String value;

  // 枚举的构造函数，用于初始化每个枚举值的字符串
  const Transaction(this.value);
}

enum AccountType {
  debt("debt"),
  asset("asset");

  final String value;

  const AccountType(this.value);
}
