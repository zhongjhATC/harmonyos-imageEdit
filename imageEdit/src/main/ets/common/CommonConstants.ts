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

/**
 * 公共常量
 */
export class CommonConstants {
  /**
   * 全屏布局
   */
  static readonly LAYOUT_FULL_SCREEN: string = '100%';

  /**
   * Tab底部菜单宽度
   */
  static readonly TAB_MENU_WIDTH: number = 18;

  /**
   * image type.
   */
  static readonly IMAGE_TYPE: string = 'image/png';

  /**
   * Free ratio.
   */
  static readonly DEFAULT_RATIO: number = -1;

  /**
   * 编辑图片组件的高度占比
   */
  static readonly EDIT_SCREEN_USAGE: number = 0.84;

  /**
   * 屏幕管理key.
   */
  static readonly APP_KEY_SCREEN_MANAGER: string = 'app_key_screen_manager';

  /**
   * 手势操作的间隔.
   */
  static readonly TIMEOUT: number = 50;

  /**
   * 裁剪框的横线宽度
   */
  static readonly DEFAULT_LINE_WIDTH: number = 0.4;

  /**
   * 裁剪框的外框宽度
   */
  static readonly DEFAULT_LINE_RECT_WIDTH: number = 0.8;

  /**
   * 裁剪框的角参数
   * 两条线组成一个角,线的宽度
   */
  static readonly DEFAULT_BUTTON_WIDTH: number = 2.3;
  /**
   * 裁剪框的角参数
   * 两条线组成一个角,两条线分别padding后使之交叉
   */
  static readonly DEFAULT_BUTTON_PADDING: number = 1;

  /**
   * 裁剪框的角参数
   * 两条线组成一个角,线的长度
   */
  static readonly DEFAULT_BUTTON_LENGTH: number = 20;

  /**
   * 裁剪框的横线颜色
   */
  static readonly DEFAULT_LINE_COLOR: string = '#80FFFFFF';

  /**
   * 裁剪框的外框 线颜色
   */
  static readonly DEFAULT_RECT_LINE_COLOR: string = '#FFFFFFFF';

  /**
   * 裁剪框的角参数
   * 颜色
   */
  static readonly DEFAULT_BUTTON_COLOR: string = '#FFFFFFFF';

  /**
   * 遮罩层样式-70%透明度.
   */
  static readonly DEFAULT_MASK_STYLE: string = 'rgba(0, 0, 0, 0.3)';

  /**
   * 遮罩层样式-0%透明度.
   */
  static readonly DEFAULT_MASK_STYLE_100: string = 'rgba(0, 0, 0, 1)';

  /**
   * 平等阈值
   */
  static readonly EQUALITY_THRESHOLD = 0.0001;

  /**
   * 裁剪框的最小边长
   */
  static readonly DEFAULT_MIN_SIDE_LENGTH: number = 90;

  /**
   * 裁剪框的触摸移动识别范围
   */
  static readonly DEFAULT_TOUCH_BOUND: number = 20;

  /**
   * 基础图像缩放值
   */
  static readonly BASE_SCALE_VALUE: number = 1.0;

  /**
   * 默认图像比例
   */
  static readonly DEFAULT_IMAGE_RATIO: number = 1.0;

  /**
   * 编辑矩形最小边长
   */
  static readonly DEFAULT_MIN_SIDE_LENGTH_EDIT: number = 32;

  /**
   * 间距长度
   */
  static readonly DEFAULT_MARGIN_LENGTH: number = 20;

  /**
   * 延迟刷新的时间
   */
  static readonly DEFAULT_TIMEOUT_MILLISECOND_300: number = 0;

  /**
   * 裁剪框的平均分割块数
   */
  static readonly DEFAULT_SPLIT_FRACTION: number = 3;

  /**
   * 涂鸦的线条宽度.
   */
  static readonly CTX_DOODLE_LINE_WIDTH: number = 4;

  /**
   * 马赛克的线条宽度.
   */
  static readonly CTX_MOSAIC_LINE_WIDTH: number = 10;
}