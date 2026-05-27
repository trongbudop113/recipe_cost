import 'dart:math' as math;

import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const RecipeCostApp());
}

class RecipeCostApp extends StatelessWidget {
  const RecipeCostApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF24211F);
    const olive = Color(0xFF385947);
    const berry = Color(0xFF9C3F4F);
    const linen = Color(0xFFF7F1E8);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chi phi banh gato',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: linen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: olive,
          brightness: Brightness.light,
        ).copyWith(
          primary: olive,
          secondary: berry,
          surface: const Color(0xFFFFFBF6),
          onSurface: ink,
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            color: ink,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
          headlineSmall: TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: ink, height: 1.35),
          bodyMedium: TextStyle(color: Color(0xFF605850), height: 1.35),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9CEC0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9CEC0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: olive, width: 1.4),
          ),
        ),
      ),
      home: const RecipeCostPage(),
    );
  }
}

class RecipeCostPage extends StatefulWidget {
  const RecipeCostPage({super.key});

  @override
  State<RecipeCostPage> createState() => _RecipeCostPageState();
}

class _RecipeCostPageState extends State<RecipeCostPage> {
  static const double _baseMoldSizeCm = 16;
  static const double _baseCakeWeightGrams = 350;
  static const double _moldHeightCm = 7;

  final TextEditingController _moldSizeController =
      TextEditingController(text: '16');
  late final List<TextEditingController> _unitPriceControllers;

  int _cakeCount = 1;

  static const List<Ingredient> _ingredients = <Ingredient>[
    Ingredient(name: 'Trứng gà', baseAmount: 15, unitPrice: 2500 / 55),
    Ingredient(name: 'Lòng đỏ trứng gà', baseAmount: 55, unitPrice: 2500 / 55),
    Ingredient(name: 'Corn syrup', baseAmount: 8, unitPrice: 30000 / 500),
    Ingredient(
      name: 'Đường (hỗn hợp lòng đỏ)',
      baseAmount: 25,
      unitPrice: 20000 / 1000,
    ),
    Ingredient(name: 'Muối', baseAmount: 1, unitPrice: 10000 / 1000),
    Ingredient(name: 'Dầu ăn', baseAmount: 30, unitPrice: 37000 / 1000),
    Ingredient(name: 'Sữa tươi', baseAmount: 30, unitPrice: 8000 / 220),
    Ingredient(name: 'Tinh chất vani', baseAmount: 2, unitPrice: 26000 / 30),
    Ingredient(name: 'Bột mì số 8', baseAmount: 60, unitPrice: 25000 / 1000),
    Ingredient(name: 'Bột nổi', baseAmount: 1, unitPrice: 15000 / 100),
    Ingredient(name: 'Lòng trắng trứng', baseAmount: 83, unitPrice: 2500 / 55),
    Ingredient(
      name: 'Đường (đánh lòng trắng)',
      baseAmount: 37,
      unitPrice: 20000 / 1000,
    ),
    Ingredient(name: 'Tarta', baseAmount: 2, unitPrice: 25000 / 100),
  ];

  @override
  void initState() {
    super.initState();
    _moldSizeController.addListener(_refreshCalculations);
    _unitPriceControllers = List<TextEditingController>.generate(
      _ingredients.length,
      (int index) {
        final TextEditingController controller = TextEditingController(
          text: _formatUnitPrice(_ingredients[index].unitPrice),
        )..addListener(_refreshCalculations);
        return controller;
      },
    );
  }

  @override
  void dispose() {
    _moldSizeController
      ..removeListener(_refreshCalculations)
      ..dispose();
    for (final TextEditingController controller in _unitPriceControllers) {
      controller
        ..removeListener(_refreshCalculations)
        ..dispose();
    }
    super.dispose();
  }

  void _refreshCalculations() {
    setState(() {});
  }

  void _setCakeCount(int value) {
    setState(() {
      _cakeCount = value.clamp(1, 99);
    });
  }

  double get _moldSizeCm {
    final double parsed = double.tryParse(_moldSizeController.text) ?? 0;
    return parsed > 0 ? parsed : _baseMoldSizeCm;
  }

  double get _recipeScale {
    return (_cakeWeightForMold(_moldSizeCm) / _baseCakeWeightGrams) *
        _cakeCount;
  }

  List<CalculatedIngredient> get _calculatedIngredients {
    return <CalculatedIngredient>[
      for (int index = 0; index < _ingredients.length; index += 1)
        CalculatedIngredient(
          ingredient: _ingredients[index],
          amount: _ingredients[index].baseAmount * _recipeScale,
          unitPrice: _parseUnitPrice(_unitPriceControllers[index].text),
          unitPriceController: _unitPriceControllers[index],
          index: index,
        ),
    ];
  }

  int get _totalCost {
    return _calculatedIngredients.fold<int>(
      0,
      (int total, CalculatedIngredient item) => total + item.lineTotal,
    );
  }

  double get _estimatedWeight {
    return _cakeWeightForMold(_moldSizeCm) * _cakeCount;
  }

  double _cakeWeightForMold(double moldSizeCm) {
    if (moldSizeCm == _baseMoldSizeCm) {
      return _baseCakeWeightGrams;
    }

    final double radius = moldSizeCm / 2;
    return (math.pi * radius * radius * _moldHeightCm) / 4;
  }

  Future<void> _exportIngredientPrices() async {
    final Uint8List bytes = IngredientPriceWorkbook.encode(
      <IngredientPriceRow>[
        for (int index = 0; index < _ingredients.length; index += 1)
          IngredientPriceRow(
            name: _ingredients[index].name,
            baseAmount: _ingredients[index].baseAmount,
            unit: _ingredients[index].unit,
            unitPrice: _parseUnitPrice(_unitPriceControllers[index].text),
          ),
      ],
    );

    await FileSaver.instance.saveFile(
      name: 'gia_nguyen_lieu_banh_gato',
      bytes: bytes,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    if (!mounted) {
      return;
    }
    _showMessage('Đã xuất file Excel giá nguyên liệu.');
  }

  Future<void> _importIngredientPrices() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['xlsx'],
      withData: true,
    );

    if (result == null) {
      return;
    }

    final Uint8List? bytes = result.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showMessage('Không đọc được dữ liệu trong file Excel.');
      return;
    }

    try {
      final Map<String, double> importedPrices =
          IngredientPriceWorkbook.decode(bytes);
      int updatedCount = 0;

      for (int index = 0; index < _ingredients.length; index += 1) {
        final double? price =
            importedPrices[normalizeIngredientName(_ingredients[index].name)];
        if (price == null) {
          continue;
        }
        _unitPriceControllers[index].text = _formatUnitPrice(price);
        updatedCount += 1;
      }

      if (!mounted) {
        return;
      }
      setState(() {});
      _showMessage(
        updatedCount > 0
            ? 'Đã cập nhật $updatedCount giá nguyên liệu từ Excel.'
            : 'Không tìm thấy nguyên liệu trùng tên trong file Excel.',
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('File Excel không đúng định dạng giá nguyên liệu.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final List<CalculatedIngredient> calculatedIngredients =
        _calculatedIngredients;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 980;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wide ? 32 : 16,
                wide ? 30 : 18,
                wide ? 32 : 16,
                28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const _PageHeader(),
                      const SizedBox(height: 20),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: _IngredientSection(
                                ingredients: calculatedIngredients,
                                onImportPrices: _importIngredientPrices,
                                onExportPrices: _exportIngredientPrices,
                              ),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: 360,
                              child: _CakeSetupPanel(
                                moldSizeController: _moldSizeController,
                                cakeCount: _cakeCount,
                                moldSizeCm: _moldSizeCm,
                                recipeScale: _recipeScale,
                                estimatedWeight: _estimatedWeight,
                                totalCost: _totalCost,
                                onCakeCountChanged: _setCakeCount,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _CakeSetupPanel(
                              moldSizeController: _moldSizeController,
                              cakeCount: _cakeCount,
                              moldSizeCm: _moldSizeCm,
                              recipeScale: _recipeScale,
                              estimatedWeight: _estimatedWeight,
                              totalCost: _totalCost,
                              onCakeCountChanged: _setCakeCount,
                            ),
                            const SizedBox(height: 16),
                            _IngredientSection(
                              ingredients: calculatedIngredients,
                              onImportPrices: _importIngredientPrices,
                              onExportPrices: _exportIngredientPrices,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5D7C7)),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 690),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bảng nguyên liệu bánh gato',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Công thức chuẩn cho 1 ổ 350g khuôn 16cm. Khi đổi khuôn, '
                  'gram bánh được tính theo pi * r^2 * h / 4 với h = 7cm, '
                  'rồi chia lại tỷ lệ từng nguyên liệu.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const _RecipeStatus(),
        ],
      ),
    );
  }
}

class _RecipeStatus extends StatelessWidget {
  const _RecipeStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E3CF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Công thức',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Đã nhập chuẩn 16cm / 350g.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CakeSetupPanel extends StatelessWidget {
  const _CakeSetupPanel({
    required this.moldSizeController,
    required this.cakeCount,
    required this.moldSizeCm,
    required this.recipeScale,
    required this.estimatedWeight,
    required this.totalCost,
    required this.onCakeCountChanged,
  });

  final TextEditingController moldSizeController;
  final int cakeCount;
  final double moldSizeCm;
  final double recipeScale;
  final double estimatedWeight;
  final int totalCost;
  final ValueChanged<int> onCakeCountChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Thiết lập mẻ bánh',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Khuôn bánh',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('mold-size-field'),
            controller: moldSizeController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              hintText: '12, 14, 16...',
              suffixText: 'cm',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Số lượng bánh',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _CountButton(
                tooltip: 'Giảm số lượng',
                icon: Icons.remove,
                onPressed: cakeCount > 1
                    ? () => onCakeCountChanged(cakeCount - 1)
                    : null,
              ),
              Expanded(
                child: Container(
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6EBDD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2CCB1)),
                  ),
                  child: Text(
                    '$cakeCount cái',
                    key: const Key('cake-count-value'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              _CountButton(
                tooltip: 'Tăng số lượng',
                icon: Icons.add,
                onPressed: () => onCakeCountChanged(cakeCount + 1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _BatchSummary(
            moldSizeCm: moldSizeCm,
            recipeScale: recipeScale,
            estimatedWeight: estimatedWeight,
            totalCost: totalCost,
          ),
        ],
      ),
    );
  }
}

class _BatchSummary extends StatelessWidget {
  const _BatchSummary({
    required this.moldSizeCm,
    required this.recipeScale,
    required this.estimatedWeight,
    required this.totalCost,
  });

  final double moldSizeCm;
  final double recipeScale;
  final double estimatedWeight;
  final int totalCost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF24211F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Tổng chi phí nguyên liệu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE7DBCE),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatMoney(totalCost),
            key: const Key('total-cost-value'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Khuôn ${_formatAmount(moldSizeCm)}cm · '
            'x${recipeScale.toStringAsFixed(2)} công thức · '
            '~${_formatAmount(estimatedWeight)}g bánh',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE7DBCE),
                ),
          ),
        ],
      ),
    );
  }
}

class _IngredientSection extends StatelessWidget {
  const _IngredientSection({
    required this.ingredients,
    required this.onImportPrices,
    required this.onExportPrices,
  });

  final List<CalculatedIngredient> ingredients;
  final VoidCallback onImportPrices;
  final VoidCallback onExportPrices;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Danh sách nguyên liệu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Đơn giá đã được quy đổi sẵn về đ/g từ giá nguyên liệu bạn cung '
            'cấp. Có thể sửa trực tiếp từng ô hoặc nhập file Excel khi giá mua '
            'thay đổi.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                key: const Key('export-excel-button'),
                onPressed: onExportPrices,
                icon: const Icon(Icons.download),
                label: const Text('Xuất Excel'),
              ),
              OutlinedButton.icon(
                key: const Key('import-excel-button'),
                onPressed: onImportPrices,
                icon: const Icon(Icons.upload_file),
                label: const Text('Nhập Excel'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth < 560) {
                return Column(
                  children: ingredients
                      .map(
                        (CalculatedIngredient ingredient) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _IngredientCard(ingredient: ingredient),
                        ),
                      )
                      .toList(),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  columnWidths: const <int, TableColumnWidth>{
                    0: FlexColumnWidth(2.2),
                    1: FlexColumnWidth(1.05),
                    2: FlexColumnWidth(0.75),
                    3: FlexColumnWidth(1.15),
                    4: FlexColumnWidth(1.1),
                  },
                  border: TableBorder.all(
                    color: const Color(0xFFE8DDD1),
                    width: 1,
                  ),
                  children: <TableRow>[
                    const TableRow(
                      decoration: BoxDecoration(
                        color: Color(0xFF385947),
                      ),
                      children: <Widget>[
                        _TableCellLabel(label: 'Nguyên liệu', header: true),
                        _TableCellLabel(label: 'Định lượng', header: true),
                        _TableCellLabel(label: 'Đơn vị', header: true),
                        _TableCellLabel(label: 'Đơn giá', header: true),
                        _TableCellLabel(label: 'Thành tiền', header: true),
                      ],
                    ),
                    ...ingredients.map(
                      (CalculatedIngredient ingredient) => TableRow(
                        decoration: const BoxDecoration(color: Colors.white),
                        children: <Widget>[
                          _TableCellLabel(label: ingredient.name),
                          _TableCellLabel(
                            label: _formatAmount(ingredient.amount),
                          ),
                          _TableCellLabel(label: ingredient.unit),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: _UnitPriceField(
                              controller: ingredient.unitPriceController,
                              index: ingredient.index,
                            ),
                          ),
                          _TableCellLabel(
                            label: _formatMoney(ingredient.lineTotal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({required this.ingredient});

  final CalculatedIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DDD1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ingredient.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _IngredientFact(
                  label: 'Định lượng',
                  value: _formatAmount(ingredient.amount),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _IngredientFact(label: 'Đơn vị', value: ingredient.unit),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _UnitPriceField(
            controller: ingredient.unitPriceController,
            index: ingredient.index,
          ),
          const SizedBox(height: 10),
          _IngredientFact(
            label: 'Thành tiền',
            value: _formatMoney(ingredient.lineTotal),
          ),
        ],
      ),
    );
  }
}

class _IngredientFact extends StatelessWidget {
  const _IngredientFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _UnitPriceField extends StatelessWidget {
  const _UnitPriceField({
    required this.controller,
    required this.index,
  });

  final TextEditingController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: Key('unit-price-$index'),
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
      decoration: const InputDecoration(
        labelText: 'Đơn giá',
        suffixText: 'đ/g',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5D7C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TableCellLabel extends StatelessWidget {
  const _TableCellLabel({required this.label, this.header = false});

  final String label;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Text(
        label,
        style: header
            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                )
            : Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class Ingredient {
  const Ingredient({
    required this.name,
    required this.baseAmount,
    required this.unitPrice,
    this.unit = 'g',
  });

  final String name;
  final double baseAmount;
  final double unitPrice;
  final String unit;
}

class CalculatedIngredient {
  const CalculatedIngredient({
    required this.ingredient,
    required this.amount,
    required this.unitPrice,
    required this.unitPriceController,
    required this.index,
  });

  final Ingredient ingredient;
  final double amount;
  final double unitPrice;
  final TextEditingController unitPriceController;
  final int index;

  String get name => ingredient.name;
  String get unit => ingredient.unit;
  int get lineTotal => (amount * unitPrice).round();
}

class IngredientPriceRow {
  const IngredientPriceRow({
    required this.name,
    required this.baseAmount,
    required this.unit,
    required this.unitPrice,
  });

  final String name;
  final double baseAmount;
  final String unit;
  final double unitPrice;
}

class IngredientPriceWorkbook {
  static const String sheetName = 'Gia nguyen lieu';
  static const String ingredientHeader = 'Nguyên liệu';
  static const String baseAmountHeader = 'Định lượng gốc';
  static const String unitHeader = 'Đơn vị';
  static const String unitPriceHeader = 'Đơn giá (đ/g)';
  static const String noteHeader = 'Ghi chú';

  static Uint8List encode(List<IngredientPriceRow> rows) {
    final excel.Excel workbook = excel.Excel.createExcel();
    final excel.Sheet sheet = workbook[sheetName];
    if (workbook.getDefaultSheet() != sheetName) {
      workbook.delete('Sheet1');
    }

    sheet.appendRow(<excel.CellValue?>[
      excel.TextCellValue(ingredientHeader),
      excel.TextCellValue(baseAmountHeader),
      excel.TextCellValue(unitHeader),
      excel.TextCellValue(unitPriceHeader),
      excel.TextCellValue(noteHeader),
    ]);

    for (final IngredientPriceRow row in rows) {
      sheet.appendRow(<excel.CellValue?>[
        excel.TextCellValue(row.name),
        excel.DoubleCellValue(row.baseAmount),
        excel.TextCellValue(row.unit),
        excel.DoubleCellValue(row.unitPrice),
        excel.TextCellValue('Sửa cột đơn giá để import lại vào app'),
      ]);
    }

    final List<int>? bytes = workbook.encode();
    if (bytes == null) {
      throw const FormatException('Không tạo được file Excel.');
    }
    return Uint8List.fromList(bytes);
  }

  static Map<String, double> decode(List<int> bytes) {
    final excel.Excel workbook = excel.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw const FormatException('File Excel không có dữ liệu.');
    }

    final excel.Sheet sheet =
        workbook.tables[sheetName] ?? workbook.tables.values.first;
    final List<List<excel.Data?>> rows = sheet.rows;
    if (rows.length < 2) {
      throw const FormatException('File Excel chưa có dòng giá nguyên liệu.');
    }

    final List<String> headers = rows.first
        .map((excel.Data? cell) => _cellText(cell?.value))
        .map(_normalizeHeader)
        .toList();
    final int nameIndex = _headerIndex(headers, ingredientHeader, fallback: 0);
    final int priceIndex = _headerIndex(headers, unitPriceHeader, fallback: 3);

    final Map<String, double> prices = <String, double>{};
    for (final List<excel.Data?> row in rows.skip(1)) {
      final String name = _cellText(_cellValueAt(row, nameIndex)).trim();
      if (name.isEmpty) {
        continue;
      }

      final double? price =
          _parseImportedUnitPrice(_cellText(_cellValueAt(row, priceIndex)));
      if (price == null) {
        continue;
      }
      prices[normalizeIngredientName(name)] = price;
    }

    if (prices.isEmpty) {
      throw const FormatException('File Excel chưa có đơn giá hợp lệ.');
    }
    return prices;
  }

  static excel.CellValue? _cellValueAt(List<excel.Data?> row, int index) {
    if (index < 0 || index >= row.length) {
      return null;
    }
    return row[index]?.value;
  }

  static int _headerIndex(
    List<String> headers,
    String expectedHeader, {
    required int fallback,
  }) {
    final int index = headers.indexOf(_normalizeHeader(expectedHeader));
    if (index >= 0) {
      return index;
    }
    return fallback;
  }

  static String _normalizeHeader(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\s()/-]+'), '')
        .replaceAll('đ', 'd');
  }

  static String _cellText(excel.CellValue? value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }
}

double _parseUnitPrice(String value) {
  final String normalized = value.trim().replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

double? _parseImportedUnitPrice(String value) {
  String normalized = value
      .toLowerCase()
      .replaceAll('đ/g', '')
      .replaceAll('vnd/g', '')
      .replaceAll('đ', '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();

  if (normalized.contains(',') && !normalized.contains('.')) {
    normalized = normalized.replaceAll(',', '.');
  }
  if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(normalized)) {
    normalized = normalized.replaceAll('.', '');
  }

  final double? price = double.tryParse(normalized);
  if (price == null || price < 0) {
    return null;
  }
  return price;
}

String normalizeIngredientName(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _formatUnitPrice(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2);
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

String _formatMoney(int value) {
  final String digits = value.toString();
  final StringBuffer buffer = StringBuffer();

  for (int index = 0; index < digits.length; index += 1) {
    final int remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${buffer.toString()} đ';
}
