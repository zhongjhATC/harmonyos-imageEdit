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
 * 比例
 */
export class Ratio {
  constructor(w: number, h: number) {
    this.w = w;
    this.h = h;
  }

  /**
   * 区域宽度
   */
  private w: number;
  /**
   * 区域高度
   */
  private h: number;

  /**
   * 赋值
   * @param w 宽度
   * @param h 高度
   */
  set(w: number, h: number): void {
    this.w = w;
    this.h = h;
  }

  /**
   * @returns 返回宽度
   */
  getW(): number {
    return this.w;
  }

  /**
   * @returns 返回高度
   */
  getH(): number {
    return this.h;
  }

  /**
   * @returns 返回比例
   */
  getRate(): number {
    return (this.w / this.h);
  }

  /**
   * @returns 判断是否固定比率
   */
  isValid(): boolean {
    return (this.w > 0 && this.h > 0);
  }
}