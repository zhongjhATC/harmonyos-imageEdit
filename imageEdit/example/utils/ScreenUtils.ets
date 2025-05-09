/**
 * 屏幕工具类
 */
export default class ScreenUtils {
  private static instance: ScreenUtils;

  public static getInstance(): ScreenUtils {
    if (!ScreenUtils.instance) {
      ScreenUtils.instance = new ScreenUtils();
    }
    return ScreenUtils.instance;
  }

  /**
   * 屏幕宽度
   */
  screenWidth = 0;
  /**
   * 任务栏高度
   */
  screenHeight = 0;
}