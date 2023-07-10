import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:isar/isar.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/utils/lang.dart';

class SourcesFilterScreen extends ConsumerWidget {
  const SourcesFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sources"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: StreamBuilder(
            stream: isar.sources
                .filter()
                .idIsNotNull()
                .and()
                .sourceCodeIsNotEmpty()
                .watch(fireImmediately: true),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final entries = snapshot.data!
                    .where((element) => ref.watch(showNSFWStateProvider)
                        ? true
                        : element.isNsfw == false)
                    .toList();

                return GroupedListView<Source, String>(
                  elements: entries,
                  groupBy: (element) => element.lang!,
                  groupSeparatorBuilder: (String groupByValue) =>
                      SwitchListTile(
                    value: entries
                        .where((element) =>
                            element.lang == groupByValue && element.isActive!)
                        .isNotEmpty,
                    onChanged: (val) {
                      isar.writeTxnSync(() {
                        for (var source in entries) {
                          if (source.lang == groupByValue) {
                            isar.sources
                                .putSync(source..isActive = val == true);
                          }
                        }
                      });
                    },
                    title: Text(
                      completeLang(groupByValue),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  itemBuilder: (context, Source element) {
                    if (entries
                        .where(
                            (ele) => ele.lang == element.lang && ele.isActive!)
                        .isEmpty) {
                      return Container();
                    }
                    return CheckboxListTile(
                      secondary: Container(
                        height: 37,
                        width: 37,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .secondaryHeaderColor
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(5)),
                        child: const Icon(Icons.source_outlined),
                      ),
                      onChanged: (bool? value) {
                        isar.writeTxnSync(() {
                          isar.sources.putSync(element..isAdded = value);
                        });
                      },
                      value: element.isAdded!,
                      title: Text(element.name!),
                    );
                  },
                  groupComparator: (group1, group2) => group1.compareTo(group2),
                  itemComparator: (item1, item2) =>
                      item1.name!.compareTo(item2.name!),
                  order: GroupedListOrder.ASC,
                );
              }
              return Container();
            }),
      ),
    );
  }
}