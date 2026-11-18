import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _data = DateFormat('dd/MM/yyyy');
final _qtd = NumberFormat.decimalPattern('pt_BR');

String moeda(double v) => _moeda.format(v);
String data(DateTime? d) => d == null ? '-' : _data.format(d);
String quantidade(double v) => _qtd.format(v);
