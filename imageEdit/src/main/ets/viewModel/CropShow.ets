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

import { LineSegment } from '../entity/Line';
import { Point } from '../entity/Point';
import { RectF } from '../entity/Rect';
import { Ratio } from '../entity/Ratio';
import { CropMoveType, ImageAngle } from '../common/ImageEditType';
import { MathUtils } from '../utils/MathUtils';
import Log from '../utils/LoggerUtil';
import { CommonConstants } from '../common/CommonConstants';
import { BackupRectF } from './BackupRectF';
import { StepObject } from '../entity/StepObject';
import Logger from '../utils/LoggerUtil';
import { ApiModel } from '../entity/ApiModel';

const TAG: string = 'editor_CropShow';

/**
 * 管理所有区域
 */
export class CropShow {
  private apiModel: ApiModel;
  private backupRectF: BackupRectF;
  /**
   * 限制区域
   */
  private limitRect: RectF;
  /**
   * 蒙层区域 - 图片跟裁剪区域交叉的区域,不能跟着移动
   */
  private cropRect: RectF;
  /**
   * 蒙层区域 - 图片跟裁剪区域交叉的区域,允许跟着移动
   */
  private cropMoveRect: RectF;
  /**
   * 图片区域
   */
  private imageRect: RectF;
  private ratio: Ratio;
  private minSideLength: number = CommonConstants.DEFAULT_MIN_SIDE_LENGTH;
  private touchBound: number = CommonConstants.DEFAULT_TOUCH_BOUND;
  private rotationAngle: number = 0;
  private horizontalAngle: number = 0;
  private maxScaleFactorW: number = CommonConstants.BASE_SCALE_VALUE;
  private maxScaleFactorH: number = CommonConstants.BASE_SCALE_VALUE;
  private isLeft: boolean = false;
  private isRight: boolean = false;
  private isTop: boolean = false;
  private isBottom: boolean = false;
  private isHorizontalSide: boolean = false;
  private isVerticalSide: boolean = false;

  constructor(apiModel: ApiModel) {
    this.apiModel = apiModel;
    this.backupRectF = new BackupRectF();
    this.limitRect = new RectF();
    this.imageRect = new RectF();
    this.cropRect = new RectF();
    this.cropMoveRect = new RectF();
    this.ratio = new Ratio(CommonConstants.DEFAULT_RATIO, CommonConstants.DEFAULT_RATIO);
  }

  /**
   * 初始化
   * @param limit 限制区域
   * @param imageRatio 图像比例
   */
  init(limit: RectF, imageRatio: number) {
    this.limitRect.set(limit.left, limit.top, limit.right, limit.bottom);
    MathUtils.computeMaxRectWithinLimit(this.imageRect, limit, imageRatio);
    this.cropRect.set(this.imageRect.left, this.imageRect.top, this.imageRect.right, this.imageRect.bottom);
    this.cropMoveRect.set(this.imageRect.left, this.imageRect.top, this.imageRect.right, this.imageRect.bottom);
    this.ratio.set(CommonConstants.DEFAULT_RATIO, CommonConstants.DEFAULT_RATIO);
    this.rotationAngle = 0;
    this.horizontalAngle = 0;
  }

  /**
   * 备份当前主要区域
   */
  syncBackupRectF() {
    this.backupRectF.imageRect = this.deepCopyImageRect();
    this.backupRectF.limitRect = this.deepCopyLimitRect();
    this.backupRectF.cropRect = this.deepCopyCropRect();
  }

  /**
   * 恢复备份的区域
   */
  restoreBackupRectF() {
    this.setImageRect(this.backupRectF.imageRect);
    this.setLimitRect(this.backupRectF.limitRect);
    this.setCropRect(this.backupRectF.cropRect, true);
  }

  /**
   * 是否裁剪 rect 更改、同步限制 rect 大小
   * @param limit 限制区域
   */
  syncLimitRect(limit: RectF) {
    this.limitRect.set(limit.left, limit.top, limit.right, limit.bottom);
    this.enlargeCropArea(true);
  }

  /**
   * 设置限制限制区域
   */
  setLimitRect(limit: RectF) {
    this.limitRect.set(limit.left, limit.top, limit.right, limit.bottom);
  }

  /**
   * 限制区域 - 深度拷贝
   * @returns 限制区域
   */
  deepCopyLimitRect(): RectF {
    let limit = new RectF();
    limit.set(this.limitRect.left, this.limitRect.top, this.limitRect.right, this.limitRect.bottom);
    return limit;
  }

  /**
   * 获取裁剪区域
   * @returns 裁剪区域
   */
  getCropRect(): RectF {
    return this.cropRect;
  }

  /**
   * 设置裁剪区域的范围
   */
  setCropRect(crop: RectF, isCrop: boolean) {
    this.cropRect.set(crop.left, crop.top, crop.right, crop.bottom);
    // 是否同步设置可移动的裁剪区域
    if (isCrop) {
      this.setCropMoveRectByCropRect();
    }
  }

  /**
   * 获取裁剪区域 - 深度拷贝
   * @returns 裁剪区域
   */
  deepCopyCropRect(): RectF {
    let crop = new RectF();
    crop.set(this.cropRect.left, this.cropRect.top, this.cropRect.right, this.cropRect.bottom);
    return crop;
  }

  /**
   * 获取可移动的裁剪区域
   * @returns 可移动的裁剪区域
   */
  getCropMoveRect(): RectF {
    return this.cropMoveRect;
  }

  /**
   * 设置可移动的裁剪区域的范围
   */
  setCropMoveRect(cropMove: RectF) {
    this.cropMoveRect.set(cropMove.left, cropMove.top, cropMove.right, cropMove.bottom);
  }

  /**
   * 根据[当前裁剪区域]重新设置[可移动的裁剪区域]
   */
  setCropMoveRectByCropRect() {
    this.cropMoveRect.set(this.cropRect.left, this.cropRect.top, this.cropRect.right,
      this.cropRect.bottom);
  }

  /**
   * 获取可移动的裁剪区域 - 深度拷贝
   * @returns 可移动的裁剪区域
   */
  deepCopyCropMoveRect(): RectF {
    let cropMoveRect = new RectF();
    cropMoveRect.set(this.cropMoveRect.left, this.cropMoveRect.top, this.cropMoveRect.right, this.cropMoveRect.bottom);
    return cropMoveRect;
  }

  /**
   * 获取包住图片区域的限制区域,用于描绘线条测试
   */
  getLimitRect(): RectF {
    return this.limitRect;
  }

  /**
   * 获取图片区域
   * @returns 图片区域
   */
  getImageRect(): RectF {
    return this.imageRect;
  }

  /**
   * 设置图片区域的范围
   * @param image 图片区域
   */
  setImageRect(image: RectF) {
    this.imageRect.set(image.left, image.top, image.right, image.bottom);
  }

  /**
   * 获取图片区域 - 深度拷贝
   * @returns 图片区域
   */
  deepCopyImageRect(): RectF {
    let image = new RectF();
    image.set(this.imageRect.left, this.imageRect.top, this.imageRect.right, this.imageRect.bottom);
    return image;
  }

  /**
   * 添加裁剪步骤
   */
  addCropStep(stepObject: StepObject) {
    stepObject.cropRect = this.deepCopyCropRect();
    stepObject.limitRect = this.deepCopyLimitRect();
    stepObject.imageRect = this.deepCopyImageRect();
  }

  /**
   * 设置区域
   */
  setRect(stepObject: StepObject) {
    this.setCropRect(stepObject.cropRect, false);
    this.setImageRect(stepObject.imageRect);
    this.syncLimitRect(stepObject.limitRect);
  }

  /**
   * 设置最大缩放系数
   * @param factorW 缩放系数-宽
   * @param factorH 缩放系数-高
   */
  setMaxScaleFactor(factorW: number, factorH: number) {
    this.maxScaleFactorW = factorW;
    this.maxScaleFactorH = factorH;
  }

  /**
   * 图像是否可以放大
   * @returns 图像是否可以放大
   */
  couldEnlargeImage(): boolean {
    return (this.couldEnlargeImageW() && this.couldEnlargeImageH());
  }

  /**
   * 进行裁剪
   */
  enlargeCropArea(isCrop: boolean) {
    let newCrop = new RectF();
    let cropRect = this.cropRect;

    let cropRatio = cropRect.getWidth() / cropRect.getHeight();
    MathUtils.computeMaxRectWithinLimit(newCrop, this.limitRect, cropRatio);
    let scale = newCrop.getWidth() / cropRect.getWidth();

    let preCenterX = cropRect.getCenterX();
    let preCenterY = cropRect.getCenterY();
    let preCenter = new Point(preCenterX, preCenterY);
    let angle = this.rotationAngle + this.horizontalAngle;

    MathUtils.scaleRectBasedOnPoint(this.imageRect, preCenter, scale);

    let offsetX = newCrop.getCenterX() - preCenter.x;
    let offsetY = newCrop.getCenterY() - preCenter.y;
    let alpha = MathUtils.formulaAngle(angle);
    let x = Math.cos(alpha) * offsetX + Math.sin(alpha) * offsetY;
    let y = -Math.sin(alpha) * offsetX + Math.cos(alpha) * offsetY;
    this.imageRect.move(x, y);

    this.setCropRect(newCrop, isCrop);
  }

  /**
   * 判断是否在裁剪线触摸范围内
   * @param x 触摸x坐标
   * @param y 触摸y坐标
   * @returns 是否在裁剪线触摸范围内
   */
  isCropRectTouch(x: number, y: number): boolean {
    let w = this.touchBound;
    let h = this.touchBound;
    let crop = this.cropRect;
    let outer = new RectF();
    outer.set(crop.left - w, crop.top - h, crop.right + w, crop.bottom + h);
    let inner = new RectF();
    inner.set(crop.left + w, crop.top + h, crop.right - w, crop.bottom - h);
    if (outer.isInRect(x, y) && !inner.isInRect(x, y)) {
      if (x <= inner.left) {
        this.isLeft = true;
      } else if (x >= inner.right) {
        this.isRight = true;
      }

      if (y <= inner.top) {
        this.isTop = true;
      } else if (y >= inner.bottom) {
        this.isBottom = true;
      }

      // 当固定裁剪比率时,将 Side 转换为 Conner
      if (this.ratio.isValid()) {
        this.fixSideToConner(x, y);
      }
      Log.debug(TAG, `isCropTouch: l[${this.isLeft}] r[${this.isRight}] t[${this.isTop}] b[${this.isBottom}]`);
    }
    return this.isLeft || this.isRight || this.isTop || this.isBottom;
  }

  /**
   * 移动裁剪区域
   * @param offsetX 移动x轴
   * @param offsetY 移动y轴
   */
  moveCropRect(offsetX: number, offsetY: number) {
    if (this.ratio.isValid()) {
      this.moveInFixedMode(offsetX, offsetY);
    } else {
      this.moveInFreeMode(offsetX, offsetY);
    }
  }

  /**
   * 结束裁剪框移动
   */
  endCropRectMove() {
    this.isLeft = false;
    this.isRight = false;
    this.isTop = false;
    this.isBottom = false;
    this.isHorizontalSide = false;
    this.isVerticalSide = false;
  }

  /**
   * 是否可以放大图像宽度
   * @returns 是否可以放大图像宽度
   */
  private couldEnlargeImageW(): boolean {
    let scaleFactorW = this.imageRect.getWidth() / this.cropRect.getWidth();
    return (scaleFactorW >= this.maxScaleFactorW ? false : true);
  }

  /**
   * 是否可以放大图像高度
   * @returns 是否可以放大图像高度
   */
  private couldEnlargeImageH(): boolean {
    let scaleFactorH = this.imageRect.getHeight() / this.cropRect.getHeight();
    return (scaleFactorH >= this.maxScaleFactorH ? false : true);
  }

  /**
   * Side 转换为 Conner
   * @param x x轴
   * @param y y轴
   */
  private fixSideToConner(x: number, y: number) {
    if ((this.isLeft || this.isRight) && !this.isTop && !this.isBottom) {
      if (y < this.cropRect.getCenterY()) {
        this.isTop = true;
      } else {
        this.isBottom = true;
      }
      this.isVerticalSide = true;
    } else if ((this.isTop || this.isBottom) && !this.isLeft && !this.isRight) {
      if (x < this.cropRect.getCenterX()) {
        this.isLeft = true;
      } else {
        this.isRight = true;
      }
      this.isHorizontalSide = true;
    }
  }

  /**
   * @returns 获取旋转图像
   */
  private getCurrentRotatedImage(): RectF {
    let flipImage = this.deepCopyImageRect();
    let points = MathUtils.rectToPoints(flipImage);
    let i = Math.abs(this.rotationAngle / ImageAngle.ONE_QUARTER_CIRCLE_ANGLE);
    let j = (i + 2) % points.length;
    let image = new RectF();
    image.set(points[i].x, points[i].y, points[j].x, points[j].y);
    return image;
  }

  /**
   * @returns 获取图像线
   */
  private getCurrentImageLines(): Array<LineSegment> {
    let flipImage = this.deepCopyImageRect();
    let imagePoints = MathUtils.rectToPoints(flipImage);

    let imageLines: LineSegment[] = [];
    for (let i = 0; i < imagePoints.length; i++) {
      let j = (i + 1) % imagePoints.length;
      imageLines.push(
        new LineSegment(new Point(imagePoints[i].x, imagePoints[i].y), new Point(imagePoints[j].x, imagePoints[j].y)));
    }
    return imageLines;
  }

  /**
   * 在固定比例模式下移动
   * @param offsetX 移动x点
   * @param offsetY 移动y点
   */
  private moveInFixedMode(offsetX: number, offsetY: number) {
    Logger.debug('moveInFixedMode')
    let x = offsetX;
    let y = offsetY;
    if (this.isHorizontalSide) {
      x = 0;
    } else if (this.isVerticalSide) {
      y = 0;
    }
    let offsetHypot = Math.hypot(x, y);

    if (this.isLeft && this.isTop) {
      // left top conner move
      let isEnlarge = offsetX < 0 || offsetY < 0;
      if (isEnlarge || this.couldEnlargeImage()) {
        this.fixLeftTopInFixedMode(offsetHypot, isEnlarge);
      }
    } else if (this.isLeft && this.isBottom) {
      // left bottom conner move
      let isEnlarge = offsetX < 0 || offsetY > 0;
      if (isEnlarge || this.couldEnlargeImage()) {
        this.fixLeftBottomInFixedMode(offsetHypot, isEnlarge);
      }
    } else if (this.isRight && this.isTop) {
      // right top conner move
      let isEnlarge = offsetX > 0 || offsetY < 0;
      if (isEnlarge || this.couldEnlargeImage()) {
        this.fixRightTopInFixedMode(offsetHypot, isEnlarge);
      }
    } else if (this.isRight && this.isBottom) {
      // right bottom conner move
      let isEnlarge = offsetX > 0 || offsetY > 0;
      if (isEnlarge || this.couldEnlargeImage()) {
        this.fixRightBottomInFixedMode(offsetHypot, isEnlarge);
      }
    }
  }

  /**
   * 在固定比例模式下，修复左上连接
   * @param offsetHypot
   * @param isEnlarge
   */
  private fixLeftTopInFixedMode(offsetHypot: number, isEnlarge: boolean) {
    let crop = this.deepCopyCropRect();
    let rate = this.ratio.getRate();
    let rect = new RectF();
    if (isEnlarge) {
      let limit = this.limitRect;
      let size = MathUtils.getMaxFixedRectSize(rate, crop.right - limit.left, crop.bottom - limit.top);
      rect.set(crop.right - size[0], crop.bottom - size[1], crop.right, crop.bottom);
      let imageLines = this.getCurrentImageLines();
      MathUtils.limitRectInRotatedBasedOnPoint(2, rect, imageLines);
    } else {
      let size = MathUtils.getMinFixedRectSize(rate, this.minSideLength);
      rect.set(crop.right - size[0], crop.bottom - size[1], crop.right, crop.bottom);
    }
    let rectHypot = Math.hypot(rect.getWidth(), rect.getHeight());
    let cropHypot = Math.hypot(crop.getWidth(), crop.getHeight());
    let limitHypot = (rectHypot - cropHypot) * (isEnlarge ? 1 : -1);
    let finalOffsetHypot = Math.min(offsetHypot, Math.max(limitHypot, 0));
    let tX = isEnlarge ? -1 : 1;
    let tY = isEnlarge ? -1 : 1;
    let ratioHypot = Math.hypot(this.ratio.getW(), this.ratio.getH());
    this.cropRect.left += finalOffsetHypot * tX * this.ratio.getW() / ratioHypot;
    this.cropRect.top += finalOffsetHypot * tY * this.ratio.getH() / ratioHypot;
  }

  /**
   * 在固定比例模式下，固定左下连接。
   * @param offsetHypot
   * @param isEnlarge
   */
  private fixLeftBottomInFixedMode(offsetHypot: number, isEnlarge: boolean) {
    let crop = this.deepCopyCropRect();
    let rate = this.ratio.getRate();
    let rect = new RectF();
    if (isEnlarge) {
      let limit = this.limitRect;
      let size = MathUtils.getMaxFixedRectSize(rate, crop.right - limit.left, limit.bottom - crop.top);
      rect.set(crop.right - size[0], crop.top, crop.right, crop.top + size[1]);
      let imageLines = this.getCurrentImageLines();
      MathUtils.limitRectInRotatedBasedOnPoint(1, rect, imageLines);
    } else {
      let size = MathUtils.getMinFixedRectSize(rate, this.minSideLength);
      rect.set(crop.right - size[0], crop.top, crop.right, crop.top + size[1]);
    }
    let rectHypot = Math.hypot(rect.getWidth(), rect.getHeight());
    let cropHypot = Math.hypot(crop.getWidth(), crop.getHeight());
    let limitHypot = (rectHypot - cropHypot) * (isEnlarge ? 1 : -1);
    let finalOffsetHypot = Math.min(offsetHypot, Math.max(limitHypot, 0));
    let tX = isEnlarge ? -1 : 1;
    let tY = isEnlarge ? 1 : -1;
    let ratioHypot = Math.hypot(this.ratio.getW(), this.ratio.getH());
    this.cropRect.left += finalOffsetHypot * tX * this.ratio.getW() / ratioHypot;
    this.cropRect.bottom += finalOffsetHypot * tY * this.ratio.getH() / ratioHypot;
  }

  /**
   * 在固定比例模式下，固定右上连接。
   * @param offsetHypot
   * @param isEnlarge
   */
  private fixRightTopInFixedMode(offsetHypot: number, isEnlarge: boolean) {
    let crop = this.deepCopyCropRect();
    let rate = this.ratio.getRate();
    let rect = new RectF();
    if (isEnlarge) {
      let limit = this.limitRect;
      let size = MathUtils.getMaxFixedRectSize(rate, limit.right - crop.left, crop.bottom - limit.top);
      rect.set(crop.left, crop.bottom - size[1], crop.left + size[0], crop.bottom);
      let imageLines = this.getCurrentImageLines();
      MathUtils.limitRectInRotatedBasedOnPoint(3, rect, imageLines);
    } else {
      let size = MathUtils.getMinFixedRectSize(rate, this.minSideLength);
      rect.set(crop.left, crop.bottom - size[1], crop.left + size[0], crop.bottom);
    }
    let rectHypot = Math.hypot(rect.getWidth(), rect.getHeight());
    let cropHypot = Math.hypot(crop.getWidth(), crop.getHeight());
    let limitHypot = (rectHypot - cropHypot) * (isEnlarge ? 1 : -1);
    let finalOffsetHypot = Math.min(offsetHypot, Math.max(limitHypot, 0));
    let tX = isEnlarge ? 1 : -1;
    let tY = isEnlarge ? -1 : 1;
    let ratioHypot = Math.hypot(this.ratio.getW(), this.ratio.getH());
    this.cropRect.right += finalOffsetHypot * tX * this.ratio.getW() / ratioHypot;
    this.cropRect.top += finalOffsetHypot * tY * this.ratio.getH() / ratioHypot;
  }

  /**
   * 在固定比例模式下，固定右下连接。
   * @param offsetHypot
   * @param isEnlarge
   */
  private fixRightBottomInFixedMode(offsetHypot: number, isEnlarge: boolean) {
    let crop = this.deepCopyCropRect();
    let rate = this.ratio.getRate();
    let rect = new RectF();
    if (isEnlarge) {
      let limit = this.limitRect;
      let size = MathUtils.getMaxFixedRectSize(rate, limit.right - crop.left, limit.bottom - crop.top);
      rect.set(crop.left, crop.top, crop.left + size[0], crop.top + size[1]);
      let imageLines = this.getCurrentImageLines();
      MathUtils.limitRectInRotatedBasedOnPoint(0, rect, imageLines);
    } else {
      let size = MathUtils.getMinFixedRectSize(rate, this.minSideLength);
      rect.set(crop.left, crop.top, crop.left + size[0], crop.top + size[1]);
    }
    let rectHypot = Math.hypot(rect.getWidth(), rect.getHeight());
    let cropHypot = Math.hypot(crop.getWidth(), crop.getHeight());
    let limitHypot = (rectHypot - cropHypot) * (isEnlarge ? 1 : -1);
    let finalOffsetHypot = Math.min(offsetHypot, Math.max(limitHypot, 0));
    let tX = isEnlarge ? 1 : -1;
    let tY = isEnlarge ? 1 : -1;
    let ratioHypot = Math.hypot(this.ratio.getW(), this.ratio.getH());
    this.cropRect.right += finalOffsetHypot * tX * this.ratio.getW() / ratioHypot;
    this.cropRect.bottom += finalOffsetHypot * tY * this.ratio.getH() / ratioHypot;
  }

  /**
   * 在自由比例模式下移动
   * @param offsetX
   * @param offsetY
   */
  private moveInFreeMode(offsetX: number, offsetY: number) {
    Logger.debug('moveInFreeMode')
    let crop = this.deepCopyCropRect();
    let limit = this.limitRect;
    let image = this.getCurrentRotatedImage();
    let minLength = this.minSideLength;
    let imageLines = this.getCurrentImageLines();
    if (this.apiModel.cropMoveType == CropMoveType.All ||
      this.apiModel.cropMoveType == CropMoveType.HORIZONTAL) {
      if (this.isLeft) {
        if (offsetX < 0 || this.couldEnlargeImageW()) {
          let left = Math.min(crop.left + offsetX, crop.right - minLength);
          left = Math.max(left, image.left, limit.left);
          this.cropRect.left = this.fixLeftInFreeMode(left, crop, imageLines);
          crop.left = this.cropRect.left;
        }
      } else if (this.isRight) {
        if (offsetX > 0 || this.couldEnlargeImageW()) {
          let right = Math.max(crop.right + offsetX, crop.left + minLength);
          right = Math.min(right, image.right, limit.right);
          this.cropRect.right = this.fixRightInFreeMode(right, crop, imageLines);
          crop.right = this.cropRect.right;
        }
      }
    }

    if (this.apiModel.cropMoveType == CropMoveType.All ||
      this.apiModel.cropMoveType == CropMoveType.Vertical) {
      if (this.isTop) {
        if (offsetY < 0 || this.couldEnlargeImageH()) {
          let top = Math.min(crop.top + offsetY, crop.bottom - minLength);
          top = Math.max(top, image.top, limit.top);
          this.cropRect.top = this.fixTopInFreeMode(top, crop, imageLines);
        }
      } else if (this.isBottom) {
        if (offsetY > 0 || this.couldEnlargeImageH()) {
          let bottom = Math.max(crop.bottom + offsetY, crop.top + minLength);
          bottom = Math.min(bottom, image.bottom, limit.bottom);
          this.cropRect.bottom = this.fixBottomInFreeMode(bottom, crop, imageLines);
        }
      }
    }
  }

  /**
   * 在自由比例模式下修复左边缘
   * @param left
   * @param crop
   * @param imageLines
   * @returns fixedLeft.
   */
  private fixLeftInFreeMode(left: number, crop: RectF, imageLines: Array<LineSegment>): number {
    let leftLine = new LineSegment(new Point(left, crop.top), new Point(left, crop.bottom));
    let adjacentLines: LineSegment[] = [];
    adjacentLines.push(new LineSegment(new Point(left, crop.top), new Point(crop.right, crop.top)));
    adjacentLines.push(new LineSegment(new Point(left, crop.bottom), new Point(crop.right, crop.bottom)));
    let fixedLeft = left;
    for (let imageLine of imageLines) {
      if (MathUtils.hasIntersection(imageLine, leftLine)) {
        let result = this.tryToFindFixedSide(adjacentLines, imageLine, left, true, true);
        fixedLeft = Math.max(fixedLeft, result);
      }
    }
    return fixedLeft;
  }

  /**
   * 在自由比例模式下固定右边缘
   * @param left
   * @param crop
   * @param imageLines
   * @returns fixedRight.
   */
  private fixRightInFreeMode(right: number, crop: RectF, imageLines: Array<LineSegment>): number {
    let rightLine = new LineSegment(new Point(right, crop.top), new Point(right, crop.bottom));
    let adjacentLines: LineSegment[] = [];
    adjacentLines.push(new LineSegment(new Point(crop.left, crop.top), new Point(right, crop.top)));
    adjacentLines.push(new LineSegment(new Point(crop.left, crop.bottom), new Point(right, crop.bottom)));
    let fixedRight = right;
    for (let imageLine of imageLines) {
      if (MathUtils.hasIntersection(imageLine, rightLine)) {
        let result = this.tryToFindFixedSide(adjacentLines, imageLine, right, true, false);
        fixedRight = Math.min(fixedRight, result);
      }
    }
    return fixedRight;
  }

  /**
   * 在自由比例模式下固定顶部边缘
   * @param left
   * @param crop
   * @param imageLines
   * @returns fixedTop.
   */
  private fixTopInFreeMode(top: number, crop: RectF, imageLines: Array<LineSegment>): number {
    let topLine = new LineSegment(new Point(crop.left, top), new Point(crop.right, top));
    let adjacentLines: LineSegment[] = [];
    adjacentLines.push(new LineSegment(new Point(crop.left, top), new Point(crop.left, crop.bottom)));
    adjacentLines.push(new LineSegment(new Point(crop.right, top), new Point(crop.right, crop.bottom)));
    let fixedTop = top;
    for (let imageLine of imageLines) {
      if (MathUtils.hasIntersection(imageLine, topLine)) {
        let result = this.tryToFindFixedSide(adjacentLines, imageLine, top, false, true);
        fixedTop = Math.max(fixedTop, result);
      }
    }
    return fixedTop;
  }

  /**
   * 在自由比例模式下固定底部边缘
   * @param left
   * @param crop
   * @param imageLines
   * @returns fixedBottom.
   */
  private fixBottomInFreeMode(bottom: number, crop: RectF, imageLines: Array<LineSegment>): number {
    let bottomLine = new LineSegment(new Point(crop.left, bottom), new Point(crop.right, bottom));
    let adjacentLines: LineSegment[] = [];
    adjacentLines.push(new LineSegment(new Point(crop.left, crop.top), new Point(crop.left, bottom)));
    adjacentLines.push(new LineSegment(new Point(crop.right, crop.top), new Point(crop.right, bottom)));
    let fixedBottom = bottom;
    for (let imageLine of imageLines) {
      if (MathUtils.hasIntersection(imageLine, bottomLine)) {
        let result = this.tryToFindFixedSide(adjacentLines, imageLine, bottom, false, false);
        fixedBottom = Math.min(fixedBottom, result);
      }
    }
    return fixedBottom;
  }

  /**
   * 查找固定边
   * @param adjacentLines
   * @param imageLine
   * @param side
   * @param isCompareX
   * @param isCompareMax
   * @returns
   */
  private tryToFindFixedSide(adjacentLines: Array<LineSegment>, imageLine: LineSegment,
    side: number, isCompareX: boolean, isCompareMax: boolean): number {
    let fixedSide = side;
    let compareFunc = isCompareMax ? Math.max : Math.min;
    for (let adjacentLine of adjacentLines) {
      if (MathUtils.hasIntersection(imageLine, adjacentLine)) {
        let intersection = MathUtils.getIntersection(imageLine, adjacentLine);
        if (intersection == undefined) {
          continue;
        }
        let compare = isCompareX ? intersection.x : intersection.y;
        fixedSide = compareFunc(side, compare);
      }
    }
    return fixedSide;
  }
}