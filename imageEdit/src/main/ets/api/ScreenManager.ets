/*
 * Copyright (c) 2025 Zhongjinghua
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { window } from '@kit.ArkUI';
import Log from '../utils/LoggerUtil';
import { CommonConstants } from '../common/CommonConstants';
import { ImageEditManager } from './ImageEditManager';

const TAG: string = 'common_ScreenManager';

type SystemBarKeys = 'status' | 'navigation';

/**
 * 列大小
 */
export enum ColumnSize {
  COLUMN_ONE_POINT_FIVE = 1.5,
  COLUMN_TWO = 2,
  COLUMN_FOUR = 4,
  COLUMN_SIX = 6,
  COLUMN_EIGHT = 8,
  COLUMN_TWELVE = 12
}

/**
 * 屏幕宽度
 */
enum ScreenWidth {
  WIDTH_MEDIUM = 520,
  WIDTH_LARGE = 840
}

/**
 * 窗口模式
 */
enum WindowStatusTypeCustom {
  UNDEFINED = 0,
  FULLSCREEN,
  MAXIMIZE,
  MINIMIZE,
  FLOATING,
  SPLIT_SCREEN
}

/**
 * 屏幕管理
 */
export class ScreenManager {
  static readonly DEFAULT_WIDTH: number = 1920;
  static readonly DEFAULT_HEIGHT: number = 1080;
  private winWidth = 0.0;
  private winHeight = 0.0;
  private columns: number = ColumnSize.COLUMN_FOUR;
  // Default orientation for Pc
  private horizontal: boolean = true;
  // Default sidebar for Pc
  private sidebar: boolean = true;
  private windowMode = 0;

  private constructor() {
    Log.info(TAG, 'constructor');
  }

  /**
   * 单例模式
   * @returns
   */
  static getInstance(): ScreenManager {
    if (AppStorage.get(CommonConstants.APP_KEY_SCREEN_MANAGER) == null) {
      AppStorage.setOrCreate(CommonConstants.APP_KEY_SCREEN_MANAGER, new ScreenManager());
    }
    let manager: ScreenManager = AppStorage.get(CommonConstants.APP_KEY_SCREEN_MANAGER) as ScreenManager;
    return manager;
  }

  /**
   * 初始化 winWidth,winHeight
   * @param win window
   */
  initializationSize() {
    let properties = ImageEditManager.getInstance().windowClass.getWindowProperties();
    if (!properties || !properties.windowRect) {
      return;
    }
    let size = properties.windowRect;
    Log.info(TAG, `display screen windowRect: ${JSON.stringify(size)}`);
    this.winWidth = px2vp(size.width);
    this.winHeight = px2vp(size.height);
    Log.info(TAG, `display screen windowRect px2vp: ${this.winWidth} ${this.winHeight}`);
    if (this.winWidth < ScreenWidth.WIDTH_MEDIUM) {
      this.columns = ColumnSize.COLUMN_FOUR;
    } else if (this.winWidth >= ScreenWidth.WIDTH_MEDIUM && this.winWidth < ScreenWidth.WIDTH_LARGE) {
      this.columns = ColumnSize.COLUMN_EIGHT;
    } else {
      this.columns = ColumnSize.COLUMN_TWELVE;
    }
  }

  /**
   * 获取窗口宽度
   * unit: vp.
   */
  getWinWidth(): number {
    return this.winWidth;
  }

  /**
   * 获取窗口高度
   * unit: vp.
   */
  getWinHeight(): number {
    return this.winHeight;
  }

  /**
   * 初始化模式
   */
  initWindowMode(): void {
    Log.debug(TAG, `start to initialize photos application window mode: ${this.windowMode}`);
    this.checkWindowMode();
    this.setMainWindow();
  }

  /**
   * 判断是否为分屏模式
   * @returns
   */
  isSplitMode(): boolean {
    return (WindowStatusTypeCustom.SPLIT_SCREEN === this.windowMode);
  }

  /**
   * 检查屏幕模式
   */
  async checkWindowMode(): Promise<void> {
    let before = this.windowMode;
    let mode = ImageEditManager.getInstance().windowStatusType;
    Log.info(TAG, `photos application before/current window mode: ${before}/${mode}`);

    if (before.toString() == mode.toString()) {
      return;
    }
    if (mode) {
      this.windowMode = mode;
    }
    if (WindowStatusTypeCustom.FULLSCREEN == this.windowMode) {
      this.setFullScreen();
    } else {
      this.setSplitScreen();
    }
  }

  /**
   * 设置主窗口
   */
  setMainWindow(): void {
    Log.debug(TAG, 'setMainWindow');
    ImageEditManager.getInstance().windowClass?.on('windowSizeChange', (data) => {
      Log.debug(TAG, `windowSizeChange ${JSON.stringify(data)}`);
      this.onWinSizeChanged(data);
    })
    let properties = ImageEditManager.getInstance().windowClass?.getWindowProperties();
    Log.info(TAG, `Window prop: ${JSON.stringify(properties)}`);
    this.onWinSizeChanged(properties.windowRect);
  }

  /**
   * 设置全屏
   */
  setFullScreen(): void {
    Log.debug(TAG, 'getTopWindow start');
    try {
      ImageEditManager.getInstance().windowClass.setWindowLayoutFullScreen(true);
      this.hideStatusBar();
    } catch (err) {
      Log.error(TAG, `setFullScreen err: ${err}`);
    }
  }

  /**
   * 设置分屏
   */
  setSplitScreen(): void {
    try {
      ImageEditManager.getInstance().statusBarHeight = 0;
      ImageEditManager.getInstance().naviBarHeight = 0;
    } catch (err) {
      Log.error(TAG, `setSplitScreen err: ${err}`);
    }
  }

  /**
   * 隐藏状态栏
   */
  hideStatusBar(): void {
    Log.debug(TAG, 'hideStatusBar start');
    Log.debug(TAG, 'getTopWindow start');
    let names = new Array<SystemBarKeys>('navigation');
    Log.debug(TAG, `getTopWindow names: ${names} end`);
    try {
      ImageEditManager.getInstance().windowClass.setWindowSystemBarEnable(names);
      Log.debug(TAG, 'hideStatusBar Succeeded');
      let barColor = '#00000000';
      if (!barColor) {
        barColor = '#00000000';
      }
      ImageEditManager.getInstance().windowClass.setWindowSystemBarProperties({ navigationBarColor: barColor });
      Log.info(TAG, 'setStatusBarColor done');
    } catch (err) {
      Log.error(TAG, `hideStatusBar err: ${err}`);
    }
  }

  /**
   * 侦听窗口大小更改
   */
  private onWinSizeChanged(size: window.Size): void {
    Log.info(TAG, `onWinSizeChanged ${JSON.stringify(size)}`);
    if (size == null || size == undefined) {
      return;
    }
    let isSplitModeBefore = this.isSplitMode();
    this.checkWindowMode();
    this.winWidth = px2vp(size.width);
    this.winHeight = px2vp(size.height);
    Log.info(TAG, `onWinSizeChanged px2vp: ${this.winWidth} ${this.winHeight}`);
    if (this.winWidth < ScreenWidth.WIDTH_MEDIUM) {
      this.columns = ColumnSize.COLUMN_FOUR;
    } else if (this.winWidth >= ScreenWidth.WIDTH_MEDIUM && this.winWidth < ScreenWidth.WIDTH_LARGE) {
      this.columns = ColumnSize.COLUMN_EIGHT;
    } else {
      this.columns = ColumnSize.COLUMN_TWELVE;
    }
    let isSplitModeNow = this.isSplitMode();
    if (isSplitModeBefore != isSplitModeNow) {
      Log.info(TAG, `splitMode changed: ${isSplitModeBefore} -> ${isSplitModeNow}`);
    }
  }
}
