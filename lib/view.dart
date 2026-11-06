import 'package:flutter/material.dart';
import 'model.dart';
import 'view_model.dart';

final names = ['🔎 リード', '🤝 商談', '✅ 契約', '📁 失注'];
final labels = ['リード', '商談', '契約', '失注'];
final colors = [
  Colors.blue.shade50,
  Colors.orange.shade50,
  Colors.green.shade50,
  Colors.red.shade50,
];

class KanbanView extends StatefulWidget {
  final KanbanViewModel vm;
  const KanbanView(this.vm, {super.key});

  @override
  State<KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends State<KanbanView> {
  final input = TextEditingController();
  DateTime? lastActionDate;

  String dateLabel(DateTime? date) => date == null
      ? '未設定'
      : '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  Future<DateTime?> pickDate(DateTime? current) {
    final today = DateUtils.dateOnly(DateTime.now());
    return showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: '最終アクション日',
      cancelText: 'キャンセル',
      confirmText: '選択',
    );
  }

  Widget dateField(DateTime? date, ValueChanged<DateTime?> onChanged) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: Icon(Icons.calendar_today_outlined),
          label: Text('最終アクション日：${dateLabel(date)}'),
          onPressed: () async {
            final picked = await pickDate(date);
            if (picked != null && mounted) onChanged(picked);
          },
        ),
      ),
      if (date != null)
        IconButton(
          tooltip: '日付をクリア',
          icon: Icon(Icons.close),
          onPressed: () => onChanged(null),
        ),
    ],
  );

  void add() {
    widget.vm.add(input.text, lastActionDate: lastActionDate);
    input.clear();
    setState(() => lastActionDate = null);
  }

  Future<void> edit(Task t) async {
    var text = t.title;
    var date = t.lastActionDate;
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('案件を編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: text,
                  autofocus: true,
                  decoration: InputDecoration(labelText: '案件名'),
                  onChanged: (v) => setDialogState(() => text = v),
                ),
                SizedBox(height: 12),
                dateField(date, (value) => setDialogState(() => date = value)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text('キャンセル')),
            FilledButton(
              onPressed: text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(c, true),
              child: Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (result == true) widget.vm.update(t, text, lastActionDate: date);
  }

  Widget taskCard(Task t) {
    final s = t.status;
    final buttons = Wrap(
      spacing: 4,
      children: [
        if (s < 2)
          FilledButton(
            onPressed: () => widget.vm.move(t, s + 1),
            child: Text('${labels[s + 1]}へ →'),
          ),
      ],
    );
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.title, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text('最終アクション日：${dateLabel(t.lastActionDate)}'),
            SizedBox(height: 8),
            buttons,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  tooltip: '案件を編集',
                  onPressed: () => edit(t),
                ),
                if (s != 3)
                  IconButton(
                    icon: Icon(Icons.delete_outline),
                    tooltip: '失注にする',
                    onPressed: () => widget.vm.markLost(t),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget lane(int s) {
    final cards = [
      for (final t in widget.vm.tasks)
        if (t.status == s) taskCard(t),
    ];
    return SizedBox(
      width: 300,
      child: Card(
        color: colors[s],
        child: Column(
          children: [
            ListTile(title: Text(names[s]), trailing: Text('${cards.length}件')),
            Expanded(child: ListView(children: cards)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: input,
      decoration: InputDecoration(
        labelText: '新しい案件',
        hintText: '例：株式会社〇〇：サービス導入相談',
        border: OutlineInputBorder(),
      ),
      onSubmitted: (text) {
        if (text.trim().isNotEmpty) add();
      },
    );
    final button = ValueListenableBuilder(
      valueListenable: input,
      builder: (context, value, child) => FilledButton.icon(
        onPressed: value.text.trim().isEmpty ? null : add,
        icon: Icon(Icons.add),
        label: Text('リードに追加'),
      ),
    );
    final entry = Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            field,
            SizedBox(height: 8),
            dateField(
              lastActionDate,
              (date) => setState(() => lastActionDate = date),
            ),
            Align(alignment: Alignment.centerRight, child: button),
          ],
        ),
      ),
    );
    final board = ListenableBuilder(
      listenable: widget.vm,
      builder: (context, child) => ListView(
        scrollDirection: Axis.horizontal,
        children: [for (int s = 0; s < names.length; s++) lane(s)],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('📋 営業案件ボード')),
      body: Column(
        children: [
          entry,
          Expanded(child: board),
        ],
      ),
    );
  }
}
