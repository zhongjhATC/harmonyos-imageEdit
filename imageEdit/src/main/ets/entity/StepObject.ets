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

import { ImageEditState } from '../common/ImageEditType';
import { RectF } from './Rect';

/**
 * 步骤类
 * 辅助撤销重做功能
 */
export class StepObject {
  /**
   * 步骤类型
   */
  state: ImageEditState = ImageEditState.NONE;
  /**
   * 限制区域
   */
  limitRect: RectF = new RectF();
  /**
   * 蒙层区域 - 图片跟裁剪区域交叉的区域,不能跟着移动
   */
  cropRect: RectF = new RectF();
  /**
   * 图片区域
   */
  imageRect: RectF = new RectF();
}