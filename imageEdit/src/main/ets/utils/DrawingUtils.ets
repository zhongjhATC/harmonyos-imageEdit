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

import { RectF } from '../entity/Rect';
import { MathUtils } from './MathUtils';
import { CommonConstants } from '../common/CommonConstants';

/**
 * 绘制工具类，只要服务于裁剪框
 */
export abstract class DrawingUtils {
  /**
   * 绘制蒙版 - Offscreen版
   * @param ctx
   * @param outer
   * @param inner
   * @param isShow
   */
  static drawMask(ctx: OffscreenCanvasRenderingContext2D, outer: RectF, inner: RectF, isShow: boolean) {
    if (isShow) {
      ctx.fillStyle = CommonConstants.DEFAULT_MASK_STYLE;
    } else {
      ctx.fillStyle = CommonConstants.DEFAULT_MASK_STYLE_100;
    }
    // 顶部的蒙版
    ctx.fillRect(outer.left, outer.top, outer.getWidth(), inner.top - outer.top);
    // 左侧的蒙版
    ctx.fillRect(outer.left, inner.top, inner.left - outer.left, inner.getHeight());
    // 右侧的蒙版
    ctx.fillRect(inner.right, inner.top, outer.right - inner.right, inner.getHeight());
    // 底部的蒙版
    ctx.fillRect(outer.left, inner.bottom, outer.getWidth(), outer.bottom);
  }

  /**
   * 绘制裁剪框的角
   * 两条线组成一个角,两条线分别padding后使之交叉
   * @param ctx
   * @param crop
   */
  static drawCropButton(ctx: OffscreenCanvasRenderingContext2D, crop: RectF) {
    let vp3 = CommonConstants.DEFAULT_BUTTON_WIDTH;
    let padding = CommonConstants.DEFAULT_BUTTON_PADDING;
    ctx.lineWidth = vp3;
    ctx.strokeStyle = CommonConstants.DEFAULT_BUTTON_COLOR;
    let cornerLength = CommonConstants.DEFAULT_BUTTON_LENGTH;
    DrawingUtils.drawCornerButton(ctx, crop, vp3, padding, cornerLength);
    DrawingUtils.drawLineButton(ctx, crop, vp3, padding, cornerLength);
  }

  /**
   * 绘制裁剪区域
   * @param ctx
   * @param crop
   */
  static drawRect(ctx: OffscreenCanvasRenderingContext2D, crop: RectF, strokeStyle: string) {
    ctx.lineWidth = CommonConstants.DEFAULT_LINE_RECT_WIDTH;
    ctx.strokeStyle = strokeStyle;
    let points = MathUtils.rectToPoints(crop);
    for (let i = 0; i < points.length; i++) {
      let j = (i + 1) % points.length;
      DrawingUtils.drawLine(ctx, points[i].x, points[i].y, points[j].x, points[j].y);
    }
  }

  /**
   * 绘制分割线(横线)
   * @param ctx OffscreenCanvasRenderingContext2D
   * @param crop 裁剪区域
   */
  static drawSplitLine(ctx: OffscreenCanvasRenderingContext2D, crop: RectF) {
    ctx.lineWidth = CommonConstants.DEFAULT_LINE_WIDTH;
    ctx.strokeStyle = CommonConstants.DEFAULT_LINE_COLOR;
    let w = Math.ceil(crop.getWidth() / CommonConstants.DEFAULT_SPLIT_FRACTION);
    let h = Math.ceil(crop.getHeight() / CommonConstants.DEFAULT_SPLIT_FRACTION);
    for (let i = 1; i < CommonConstants.DEFAULT_SPLIT_FRACTION; i++) {
      let x = crop.left + w * i;
      let y = crop.top + h * i;
      DrawingUtils.drawLine(ctx, x, crop.top, x, crop.bottom);
      DrawingUtils.drawLine(ctx, crop.left, y, crop.right, y);
    }
  }

  /**
   * Draw line.
   * @param ctx
   * @param srcX
   * @param srcY
   * @param dstX
   * @param dstY
   */
  static drawLine(ctx: OffscreenCanvasRenderingContext2D, srcX: number, srcY: number, dstX: number, dstY: number) {
    ctx.beginPath();
    ctx.moveTo(srcX, srcY);
    ctx.lineTo(dstX, dstY);
    ctx.stroke();
  }

  /**
   * 绘制裁剪角
   * @param ctx
   * @param crop
   * @param vp3
   * @param padding
   * @param cornerLength
   */
  private static drawCornerButton(ctx: OffscreenCanvasRenderingContext2D, crop: RectF,
    vp3: number, padding: number, cornerLength: number) {
    // left top conner button
    vp3 = vp3 / 2;
    let startX = crop.left - vp3 - padding;
    let startY = crop.top - vp3;
    let stopX = startX + cornerLength;
    let stopY = startY;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);
    startX = crop.left - vp3;
    startY = crop.top - vp3 - padding;
    stopX = startX;
    stopY = startY + cornerLength;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);

    // right top conner button
    startX = crop.right + vp3 + padding;
    startY = crop.top - vp3;
    stopX = startX - cornerLength;
    stopY = startY;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);
    startX = crop.right + vp3;
    startY = crop.top - vp3 - padding;
    stopX = startX;
    stopY = startY + cornerLength;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);

    // left bottom conner button
    startX = crop.left - vp3;
    startY = crop.bottom + vp3 + padding;
    stopX = startX;
    stopY = startY - cornerLength;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);
    startX = crop.left - vp3 - padding;
    startY = crop.bottom + vp3;
    stopX = startX + cornerLength;
    stopY = startY;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);

    // right bottom conner button
    startX = crop.right + vp3 + padding;
    startY = crop.bottom + vp3;
    stopX = startX - cornerLength;
    stopY = startY;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);
    startX = crop.right + vp3;
    startY = crop.bottom + vp3 + padding;
    stopX = startX;
    stopY = startY - cornerLength;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);
  }

  /**
   * Draw line.
   * @param ctx
   * @param crop
   * @param vp3
   * @param padding
   * @param cornerLength
   */
  private static drawLineButton(ctx: OffscreenCanvasRenderingContext2D, crop: RectF,
    vp3: number, padding: number, cornerLength: number) {
    vp3 = vp3 / 2;
    // top button
    let startX = crop.getCenterX() - cornerLength / 2;
    let startY = crop.top - vp3;
    let stopX = startX + cornerLength;
    let stopY = startY;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);

    // bottom button
    startX = crop.getCenterX() - cornerLength / 2;
    startY = crop.bottom + vp3;
    stopX = startX + cornerLength;
    stopY = startY;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);

    // left button
    startX = crop.left - vp3;
    startY = crop.getCenterY() - cornerLength / 2;
    stopX = startX;
    stopY = startY + cornerLength;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);

    // right button
    startX = crop.right + vp3;
    startY = crop.getCenterY() - cornerLength / 2;
    stopX = startX;
    stopY = startY + cornerLength;
    DrawingUtils.drawLine(ctx, startX, startY, stopX, stopY);
  }
}