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

export class ConstantsID {
  /**
   * 相对容器布局时父容器默认id
   */
  static readonly CONTAINER_ID: string = '__container__';
  /**
   * 页面顶部按钮容器id
   */
  static readonly TOP_BUTTON_LINE_ID: string = 'topButtonLine';
  /**
   * 页面底部涂鸦组件id
   */
  static readonly BOTTOM_PEN_SHAPE_ID: string = 'bottomPenShape';
  static readonly TEXT_CANCEL: string = 'tvCancel';
  static readonly IMAGE_UNDO: string = 'imgUndo';
  static readonly IMAGE_REDO: string = 'imgRedo';
  static readonly IMAGE_CROP_CLOSE: string = 'imgCropClose';
  static readonly IMAGE_CROP_SUBMIT: string = 'imgCropSubmit';
  static readonly TABS_MENU: string = 'tabsMenu';
  static readonly BTN_COMPLETE: string = 'btnComplete';
}