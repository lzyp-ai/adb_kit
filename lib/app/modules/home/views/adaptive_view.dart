import 'package:adb_kit/app/controller/config_controller.dart';
import 'package:adb_kit/config/config.dart';
import 'package:adb_kit/global/instance/global.dart';
import 'package:adb_kit/global/instance/page_manager.dart';
import 'package:adb_kit/utils/plugin_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart' hide ScreenType;
import 'package:global_repository/global_repository.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:settings/settings.dart';

import 'desktop_home.dart';
import 'dialog/otg_dialog.dart';
import 'mobile_home.dart';
import 'tablet_home.dart';

class AdbTool extends StatefulWidget {
  const AdbTool({
    Key? key,
    this.packageName,
  }) : super(key: key);

  final String? packageName;
  @override
  State createState() => _AdbToolState();
}

class _AdbToolState extends State<AdbTool> with WidgetsBindingObserver {
  bool dialogIsShow = false;
  ConfigController configController = Get.find();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.v('didChangeAppLifecycleState : $state');
  }

  @override
  void initState() {
    super.initState();
    if (GetPlatform.isMacOS && RuntimeEnvir.packageName == Config.packageName) {
      // 如果这个项目是独立运行的，那么RuntimeEnvir.packageName会在main函数中被设置成Config.packageName
      Config.flutterPackage = 'packages/adb_tool/';
      // Window.makeTitlebarTransparent();
      // Window.enableFullSizeContentView();
    }
    configController.syncBackgroundStyle();
    WidgetsBinding.instance.addObserver(this);
    PluginUtil.addHandler((call) {
      if (call.method == 'ShowOTGDialog') {
        dialogIsShow = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return const OTGDialog();
          },
        );
      } else if (call.method == 'CloseOTGDialog') {
        if (dialogIsShow) {
          Navigator.of(context).pop();
        }
        dialogIsShow = false;
      }
    });
    // TODO detach 也需要
    Future.delayed(Duration.zero, () async {
      if ('privacy'.setting.get() == null) {
        await Get.to(PrivacyAgreePage(
          onAgreeTap: () {
            'privacy'.setting.set(true);
            Navigator.of(context).pop();
          },
        ));
      }
    });
  }

  @override
  void dispose() {
    Log.w('ADB TOOL dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Global().page ??= PageManager.instance!.pages.first.buildPage(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark ? OverlayStyle.light : OverlayStyle.dark,
      child: Stack(
        children: [
          Builder(
            builder: (context) {
              if (ResponsiveBreakpoints.of(context).isDesktop) {
                return const DesktopHome();
              }
              if (ResponsiveBreakpoints.of(context).isTablet) {
                return const TableHome();
              }
              if (ResponsiveBreakpoints.of(context).isMobile) {
                return const MobileHome();
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
