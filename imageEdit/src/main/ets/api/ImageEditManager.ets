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
import { ScreenManager } from './ScreenManager';

/**
 * 初始化相关参数
 */
export class ImageEditManager {
  windowClass: window.Window = null!
  windowStatusType: WindowStatusType = null!
  /**
   * 获取状态栏高度
   */
  statusBarHeight: number = 0
  /**
   * 导航栏高度
   */
  naviBarHeight: number = 0
  private static instance: ImageEditManager;

  public static getInstance(): ImageEditManager {
    if (!ImageEditManager.instance) {
      ImageEditManager.instance = new ImageEditManager();
    }
    return ImageEditManager.instance;
  }

  init(windowClass: window.Window, windowStatusType: WindowStatusType, statusBarHeight: number, naviBarHeight: number) {
    // 缓存windowClass
    this.windowClass = windowClass;
    this.windowStatusType = windowStatusType;
    this.statusBarHeight = statusBarHeight
    this.naviBarHeight = naviBarHeight
    ScreenManager.getInstance().initializationSize();
  }
}