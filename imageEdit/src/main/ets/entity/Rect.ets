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
 * 区域,支持浮点数
 */
export class RectF {
  constructor() {
    this.left = 0;
    this.top = 0;
    this.right = 0;
    this.bottom = 0;
  }

  /**
   * 矩形左边点的值
   */
  left: number;
  /**
   * 矩形顶部点的值
   */
  top: number;
  /**
   * 矩形右边点的值
   */
  right: number;
  /**
   * 矩形底部点的值
   */
  bottom: number;

  /**
   * 赋值
   * @param left 矩形左边点的值
   * @param top 矩形顶部点的值
   * @param right 矩形右边点的值
   * @param bottom 矩形底部点的值
   */
  set(left: number, top: number, right: number, bottom: number): void {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  /**
   * @returns 返回矩形宽度
   */
  getWidth(): number {
    return (this.right - this.left);
  }

  /**
   * @returns 返回矩形高度
   */
  getHeight(): number {
    return (this.bottom - this.top);
  }

  /**
   * @returns 获取矩形对角线
   */
  getDiagonal(): number {
    return Math.hypot(this.getWidth(), this.getHeight());
  }

  /**
   * @returns 获取 x 的中心点
   */
  getCenterX(): number {
    return (this.left + this.getWidth() / 2);
  }

  /**
   * @returns 获取 y 的中心点
   */
  getCenterY(): number {
    return (this.top + this.getHeight() / 2);
  }

  /**
   * @param x x点
   * @param y y点
   * @returns 它是否在矩形内
   */
  isInRect(x: number, y: number): boolean {
    return (x >= this.left && x <= this.right && y >= this.top && y <= this.bottom);
  }

  /**
   * 根据缩放系数设置值
   * @param scale 缩放系数
   */
  scale(scale: number): void {
    this.left *= scale;
    this.right *= scale;
    this.top *= scale;
    this.bottom *= scale;
  }

  /**
   * 按当前偏移值移动
   * @param offsetX x移动值
   * @param offsetY y移动值
   */
  move(offsetX: number, offsetY: number): void {
    this.left += offsetX;
    this.right += offsetX;
    this.top += offsetY;
    this.bottom += offsetY;
  }

  /**
   * @returns 返回string
   */
  toString(): string {
    return `left: ${this.left} right: ${this.right} top: ${this.top} bottom: ${this.bottom}`
  }
}