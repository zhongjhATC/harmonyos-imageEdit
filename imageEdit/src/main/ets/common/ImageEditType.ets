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
 * 当前编辑图片类型,用于根据当前类型做相应的操作
 */
export enum ImageEditState {
  /**
   * 默认状态
   */
  NONE,

  /**
   * 裁剪-移动
   */
  CROP_MOVE,

  /**
   * 图片-移动
   */
  IMAGE_DRAG,

  /**
   * 图片-缩放
   */
  IMAGE_SCALE,

  /**
   * 涂鸦
   */
  DOODLE_DRAG,

  /**
   * 马赛克
   */
  MOSAIC_DRAG
}

/**
 * 图片角度
 */
export enum ImageAngle {
  /**
   * 裁剪角度 90
   */
  ONE_QUARTER_CIRCLE_ANGLE = 90,

  /**
   * 裁剪角度 180
   */
  HALF_CIRCLE_ANGLE = 180,

  /**
   * 裁剪角度 270
   */
  THREE_QUARTER_CIRCLE_ANGLE = 270,

  /**
   * 裁剪角度 360
   */
  CIRCLE_ANGLE = 360
}

/**
 * 主页选项卡类型
 */
export enum MainTabId {
  DOODLE,
  CROP,
  MOSAIC
}

/**
 * 裁剪框移动类型
 */
export enum CropMoveType {

  /**
   * 全部,支持横向移动和竖向移动
   */
  All,
  /**
   * 只支持横向移动
   */
  HORIZONTAL,
  /**
   * 只支持竖向移动
   */
  Vertical

}

