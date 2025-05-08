import window from '@ohos.window';
import display from '@ohos.display';
import ScreenUtils from './ScreenUtils';

/**
 * 状态栏工具类
 * https://juejin.cn/post/7302456005526110227
 */
export default class StatusUtils {
  private static instance: StatusUtils;

  public static getInstance(): StatusUtils {
    if (!StatusUtils.instance) {
      StatusUtils.instance = new StatusUtils();
    }
    return StatusUtils.instance;
  }

  windowClass?: window.Window
  /**
   * 状态栏高度
   */
  statusBarHeight = 0;
  /**
   * 任务栏高度
   */
  navigationBarHeight = 0;

  /**
   * 设置沉侵式状态栏
   * 初始化缓存状态栏高度和任务栏高度
   * @param windowStage windowStage
   */
  initStatusBarAndNavigationBar(windowClass: window.Window) {
    this.windowClass = windowClass;
    // 创建颜色透明
    let SystemBarProperties: window.SystemBarProperties = {
      // 状态栏颜色
      statusBarColor: '#00000000',
      // 导航栏颜色
      navigationBarColor: '#00000000',
      // 状态栏文字颜色
      statusBarContentColor: '#FFFFFF',
      // 导航栏文字颜色
      // navigationBarContentColor: '#ffffffff'
    }
    windowClass.setWindowLayoutFullScreen(true);
    // 启动状态栏,意思是隐藏任务栏
    windowClass.setWindowSystemBarEnable(['status']);
    // 设置颜色
    windowClass.setWindowSystemBarProperties(SystemBarProperties, (_err) => {

    })

    // 获取高度,用于后续padding这些高度
    let avoidArea: window.AvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    // px2vp目前Api9在Ability无效,暂时自己计算
    let displayEntity = display.getDefaultDisplaySync();
    // 状态栏
    this.statusBarHeight = avoidArea.topRect.height / displayEntity.densityPixels;
    // 导航栏
    avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    this.navigationBarHeight = avoidArea.bottomRect.height / displayEntity.densityPixels;
    // 获取宽高
    ScreenUtils.getInstance().screenWidth = displayEntity.width;
    ScreenUtils.getInstance().screenHeight = displayEntity.height;
  }

  /**
   * 设置app状态栏文字颜色
   * @param systemBarProperties
   */
  setStatusBarContentColor(isBlack: boolean | undefined) {
    if (isBlack) {
      // 修改成黑色字
      this.setWindowSystemBarProperties({
        // 状态栏文字颜色
        statusBarContentColor: '#000000'
      })
    } else {
      // 修改成白色字
      this.setWindowSystemBarProperties({
        // 状态栏文字颜色
        statusBarContentColor: '#FFFFFF'
      })
    }
  }

  /**
   * 设置app状态栏、导航栏等属性
   * @param systemBarProperties
   */
  setWindowSystemBarProperties(systemBarProperties: window.SystemBarProperties) {
    // 设置颜色
    this.windowClass?.setWindowSystemBarProperties(systemBarProperties)
  }
}