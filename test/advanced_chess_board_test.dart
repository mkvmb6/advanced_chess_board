// Thin index file that imports every sub-test file so `flutter test`
// discovers them. See `design.md §8` "Harness layout".

import 'api/barrel_imports_test.dart' as barrel_imports;
import 'controller/controller_basic_test.dart' as controller_basic;
import 'controller/exploration_dispose_ordering_test.dart'
    as exploration_dispose_ordering;
import 'controller/exploration_listener_fanout_test.dart'
    as exploration_listener_fanout;
import 'packaging/changelog_format_test.dart' as changelog_format;
import 'packaging/exploration_empty_test_file_test.dart'
    as exploration_empty_test_file;
import 'packaging/exploration_strict_analyse_test.dart'
    as exploration_strict_analyse;
import 'packaging/pubspec_metadata_test.dart' as pubspec_metadata;
import 'packaging/readme_content_test.dart' as readme_content;
import 'painter/arrow_painter_test.dart' as arrow_painter;
import 'painter/exploration_arrow_repaint_test.dart'
    as exploration_arrow_repaint;
import 'painter/exploration_orientation_repaint_test.dart'
    as exploration_orientation_repaint;
import 'painter/exploration_san_substring_test.dart'
    as exploration_san_substring;
import 'properties/controller_properties_test.dart' as controller_properties;
import 'properties/move_validation_properties_test.dart'
    as move_validation_properties;
import 'properties/preservation_test.dart' as preservation;
import 'widget/accessibility_test.dart' as accessibility;
import 'widget/board_layout_test.dart' as board_layout;
import 'widget/board_rebuild_test.dart' as board_rebuild;
import 'widget/exploration_drag_scale_test.dart' as exploration_drag_scale;
import 'widget/exploration_gridview_present_test.dart'
    as exploration_gridview_present;
import 'widget/exploration_last_move_placeholder_test.dart'
    as exploration_last_move_placeholder;
import 'widget/exploration_missing_semantics_test.dart'
    as exploration_missing_semantics;
import 'widget/exploration_noop_tap_rebuild_test.dart'
    as exploration_noop_tap_rebuild;
import 'widget/exploration_widget_non_rebuild_test.dart'
    as exploration_widget_non_rebuild;

void main() {
  // API / barrel.
  barrel_imports.main();

  // Controller.
  controller_basic.main();
  exploration_listener_fanout.main();
  exploration_dispose_ordering.main();

  // Painter.
  arrow_painter.main();
  exploration_arrow_repaint.main();
  exploration_orientation_repaint.main();
  exploration_san_substring.main();

  // Widget.
  board_layout.main();
  board_rebuild.main();
  accessibility.main();
  exploration_widget_non_rebuild.main();
  exploration_noop_tap_rebuild.main();
  exploration_last_move_placeholder.main();
  exploration_gridview_present.main();
  exploration_drag_scale.main();
  exploration_missing_semantics.main();

  // Properties (PBT).
  controller_properties.main();
  move_validation_properties.main();
  preservation.main();

  // Packaging.
  pubspec_metadata.main();
  readme_content.main();
  changelog_format.main();
  exploration_empty_test_file.main();
  exploration_strict_analyse.main();
}
