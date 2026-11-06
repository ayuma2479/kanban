import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanban/model.dart';
import 'package:kanban/view.dart';
import 'package:kanban/view_model.dart';

class MemoryViewModel extends KanbanViewModel {
  String? saved;

  @override
  Future<void> save() async {
    saved = jsonEncode(tasks.map((task) => task.toJson()).toList());
    notifyListeners();
  }
}

void main() {
  testWidgets('戻るボタンなしで進行し、ごみ箱で右端の失注列に保管する', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = MemoryViewModel();
    final date = DateTime(2026, 1, 10);
    vm.add('導入相談', lastActionDate: date);
    await tester.pumpWidget(MaterialApp(home: KanbanView(vm)));
    await tester.tap(find.text('商談へ →'));
    await tester.pumpAndSettle();
    expect(find.textContaining('←'), findsNothing);
    expect(find.text('契約へ →'), findsOneWidget);
    await tester.tap(find.byTooltip('失注にする'));
    await tester.pumpAndSettle();
    expect(vm.tasks, hasLength(1));
    expect(vm.tasks.single.status, 3);
    final restored = Task.fromJson((jsonDecode(vm.saved!) as List).single);
    expect(restored.status, 3);
    expect(restored.title, '導入相談');
    expect(restored.lastActionDate, date);
    expect(find.text('導入相談'), findsOneWidget);
    expect(find.text('最終アクション日：2026/01/10'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('導入相談')).dx,
      greaterThan(tester.getTopLeft(find.text('✅ 契約')).dx),
    );
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.text('商談へ →'), findsNothing);
    expect(find.text('契約へ →'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('旧データは日付未設定として読み込める', () {
    final task = Task.fromJson({'title': '既存案件', 'status': 1});
    expect(task.title, '既存案件');
    expect(task.status, 1);
    expect(task.lastActionDate, isNull);
  });

  test('日付を保存し、列の移動後も保持して再読み込みできる', () {
    final vm = MemoryViewModel();
    final date = DateTime(2026, 11, 5);
    vm.add('導入相談', lastActionDate: date);
    vm.move(vm.tasks.single, 1);
    final restored = Task.fromJson((jsonDecode(vm.saved!) as List).single);
    expect(restored.lastActionDate, date);
    expect(restored.status, 1);
    vm.update(vm.tasks.single, '導入提案', lastActionDate: null);
    final cleared = Task.fromJson((jsonDecode(vm.saved!) as List).single);
    expect(cleared.title, '導入提案');
    expect(cleared.lastActionDate, isNull);
  });

  testWidgets('追加時に選んだ日付をカードに表示する', (tester) async {
    final vm = MemoryViewModel();
    await tester.pumpWidget(MaterialApp(home: KanbanView(vm)));
    await tester.enterText(find.byType(TextField), '新規案件');
    await tester.tap(find.text('最終アクション日：未設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('選択'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('リードに追加'));
    await tester.pumpAndSettle();
    expect(vm.tasks.single.lastActionDate, DateUtils.dateOnly(DateTime.now()));
    expect(find.text('新規案件'), findsOneWidget);
    expect(find.text('最終アクション日：未設定'), findsOneWidget);
    expect(find.textContaining('最終アクション日：'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('編集のキャンセルで日付を保持し、保存でクリアする', (tester) async {
    final vm = MemoryViewModel();
    vm.add('既存案件', lastActionDate: DateTime(2026, 1, 10));
    await tester.pumpWidget(MaterialApp(home: KanbanView(vm)));
    expect(find.text('最終アクション日：2026/01/10'), findsOneWidget);
    await tester.tap(find.byTooltip('案件を編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('日付をクリア'));
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(vm.tasks.single.lastActionDate, DateTime(2026, 1, 10));
    await tester.tap(find.byTooltip('案件を編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('日付をクリア'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(vm.tasks.single.lastActionDate, isNull);
    expect(tester.takeException(), isNull);
  });
}
