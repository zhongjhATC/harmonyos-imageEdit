import { AbilityConstant, bundleManager, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import StatusUtils from '@zhongjh/image_edit/example/utils/StatusUtils';
import { ImageEditManager } from '@zhongjh/image_edit';

/**
 * 例子的入口
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    let windowClass: window.Window = windowStage.getMainWindowSync();
    StatusUtils.getInstance().initStatusBarAndNavigationBar(windowClass);
    // 监控窗口变化,用来初始化ImageEditManager
    windowClass.on('windowStatusChange', (status) => {
      ImageEditManager.getInstance()
        .init(windowClass, status, StatusUtils.getInstance().statusBarHeight,
          StatusUtils.getInstance().navigationBarHeight);
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }
}