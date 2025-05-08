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

import { Point } from '../entity/Point';
import { RectF } from '../entity/Rect';
import { ImageEditState } from '../common/ImageEditType';
import { CropShow } from './CropShow';
import { MathUtils } from '../utils/MathUtils';
import { DrawingUtils } from '../utils/DrawingUtils';
import { PixelMapWrapper } from '../entity/PixelMapWrapper';
import { CommonConstants } from '../common/CommonConstants';
import { Path2DObject } from '../entity/Path2DObject';
import { StepObject } from '../entity/StepObject';
import fs from '@ohos.file.fs';
import { image } from '@kit.ImageKit';
import { ApiModel } from '../entity/ApiModel';

/**
 * 图片编辑类,支持以下功能：
 * 1. 裁剪
 * 2. 缩放
 * 3. 涂鸦
 * 4. 马赛克
 * 5. 撤销、重做
 */
export class ImageEdit {
  /**
   * 图片数据源封装
   */
  private pixelMapWrapper: PixelMapWrapper | undefined = undefined;
  /**
   * 裁剪UI类
   */
  public cropShow: CropShow;
  /**
   * 是否已初始化裁剪显示
   */
  private isCropShowInitialized: boolean = false;
  /**
   * 绘制组件
   */
  private contextImage: CanvasRenderingContext2D = null!;
  /**
   * 涂鸦组件
   */
  private contextDoodle: CanvasRenderingContext2D = null!;
  /**
   * 离线绘制组件,可以在单独的线程中运行一些任务，从而避免影响应用程序主线程性能
   */
  private offscreenCanvas: OffscreenCanvasRenderingContext2D = null!;
  /**
   * 马赛克的图片
   */
  private pattern: CanvasPattern | null = null;
  /**
   * 每次更新步骤时触发回调事件
   */
  private callbackByUpdateStep: (stepCount: number, stepCurrent: number) => void = null!;
  /**
   * 该图片控件(包含边距)的宽高
   */
  private viewWidth: number = 0;
  private viewHeight: number = 0;
  /**
   * 左右间距
   */
  private marginW: number = CommonConstants.DEFAULT_MARGIN_LENGTH;
  /**
   * 上下间距
   */
  private marginH: number = CommonConstants.DEFAULT_MARGIN_LENGTH;
  /**
   * 图片比例
   */
  private imageRatio: number = CommonConstants.DEFAULT_IMAGE_RATIO;
  /**
   * 图片缩放,这是当前操作跟上一个图片的比例
   */
  private scale: number = CommonConstants.BASE_SCALE_VALUE;
  /**
   * 当前的缩放,这是当前操作跟初始化时图片的比例
   */
  scaleCurrent: number = CommonConstants.BASE_SCALE_VALUE;
  /**
   * 延迟刷新的id
   */
  private timeoutId: number = 0;
  /**
   * 是否正在等待刷新
   */
  private isWaitingRefresh: boolean = false;
  /**
   * 单手指触摸事件的手势
   */
  private touchPoint: Point;
  /**
   * 多手指触摸事件的手势
   */
  private pinchPoint: Point;
  /**
   * 当前编辑图片类型,用于根据当前类型做相应的操作
   */
  private state: ImageEditState = ImageEditState.NONE;
  /**
   * 自身是否已经准备好
   */
  private canvasReady: boolean = false;
  /**
   * 是否显示遮罩层挡住的ui
   */
  private isMaskShow: boolean = false;
  /**
   * 是否启动裁剪
   */
  private isCrop: boolean = false;
  /**
   * 是否启动涂鸦
   */
  private isDoodle: boolean = false;
  /**
   * 是否启动马赛克
   */
  private isMosaic: boolean = false;
  /**
   * 涂鸦画笔总集合
   */
  private path2DArray: Array<Path2DObject> = new Array<Path2DObject>();
  /**
   * 涂鸦显示
   */
  private path2D: Path2D = new Path2D();
  /**
   * 涂鸦缓存,用于配合path2DArray
   */
  private path2DCache: Path2D = new Path2D();
  /**
   * 裁剪图片区域和本身控件的顶部间距
   */
  private marginTop: number = 0;
  /**
   * 步骤列表，用于结合撤销重做功能
   */
  private stepObjectArray: Array<StepObject> = new Array<StepObject>();
  /**
   * 用于记录多个步骤的当前步骤索引,总索引
   * 辅助撤销重做功能
   * 默认值-1是因为初始化会算一个
   */
  private stepCurrentIndex = -1;
  /**
   * 用于记录涂鸦的当前步骤索引 只针对涂鸦
   * 辅助撤销重做功能
   */
  private stepCurrentPathIndex = -1;
  /**
   * 是否所有手势都在画布外操作
   * 如果是的话，不会加入撤销重做集合里面
   */
  private isAllTouchLeave = true;

  constructor(apiModel: ApiModel) {
    this.cropShow = new CropShow(apiModel);
    this.touchPoint = new Point(0, 0);
    this.pinchPoint = new Point(0, 0);
  }

  /**
   * 启动/关闭裁剪
   */
  enableCrop(isCrop: boolean, isCancelCrop: boolean) {
    if (this.isCrop != isCrop) {
      this.isCrop = isCrop;
      if (isCrop) {
        // 开启裁剪则重置缩放率
        this.recover();
        // 记录当前裁剪区域数据
        this.cropShow.syncBackupRectF();
      } else if (!isCrop && !isCancelCrop) {
        // 关闭裁剪模式,存储当前裁剪数据
        this.stepAdd(ImageEditState.CROP_MOVE);
      }
    }
    this.refresh();
  }

  /**
   * 取消裁剪模式
   */
  cancelCrop() {
    this.cropShow.restoreBackupRectF();
  }

  /**
   * 启动/关闭涂鸦
   */
  enableDoodle(isDoodle: boolean) {
    this.isDoodle = isDoodle;
    this.state = ImageEditState.NONE;
  }

  /**
   * 启动/关闭马赛克
   */
  enableMosaic(isMosaic: boolean) {
    this.isMosaic = isMosaic;
    this.state = ImageEditState.NONE;
  }

  /**
   * 图像编辑初始化
   * @param pixelMap 图片数据
   */
  entry(pixelMap: PixelMapWrapper): void {
    this.pixelMapWrapper = pixelMap;
    this.initialize();
    if (this.isCropShowInitialized) {
      let limit = this.calcNewLimit();
      this.cropShow.init(limit, this.imageRatio);
    }
    this.refresh();
  }

  /**
   * 设置所有相关的CanvasRenderingContext2D
   * @param context 绘制图片、蒙版工具
   */
  async setCanvasContext(context: CanvasRenderingContext2D, contextDoodle: CanvasRenderingContext2D,
    offscreenCanvasDoodle: OffscreenCanvasRenderingContext2D): Promise<void> {
    this.contextImage = context;
    this.contextDoodle = contextDoodle;

    this.contextDoodle.lineWidth = CommonConstants.CTX_DOODLE_LINE_WIDTH;
    this.contextDoodle.lineCap = 'round';
    this.contextDoodle.strokeStyle = Color.Red;

    this.offscreenCanvas = offscreenCanvasDoodle;
    this.offscreenCanvas.lineCap = 'round';
    this.offscreenCanvas.lineWidth = CommonConstants.CTX_DOODLE_LINE_WIDTH;
    this.offscreenCanvas.strokeStyle = Color.Red;

    let imageBitmap = new ImageBitmap(await this.getMosaicPixelMap());
    this.pattern = this.contextDoodle.createPattern(imageBitmap, 'repeat');

    this.refresh();
  }

  /**
   * 设置Canvas为是否准备就绪
   * @param isReady 是否准备就绪
   */
  setCanvasReady(isReady: boolean): void {
    this.canvasReady = isReady;
  }

  /**
   * 设置Canvas显示
   * @param width 宽
   * @param height 高
   */
  setCanvasSize(width: number, height: number): void {
    this.viewWidth = width;
    this.viewHeight = height;
    let limit = this.calcNewLimit();
    if (this.isCropShowInitialized) {
      this.cropShow.syncLimitRect(limit);
      this.determineMaxScaleFactor();
    } else {
      this.cropShow.init(limit, this.imageRatio);
      this.isCropShowInitialized = true;
      this.stepAdd(ImageEditState.CROP_MOVE);
    }
    // 设置图片跟View顶部间距
    this.marginTop = this.cropShow.deepCopyLimitRect().top - this.cropShow.getCropRect().top;
    this.refresh();
  }

  /**
   * 设置更新步骤回调事件
   * @param callbackByUpdateStep 更新步骤回调事件
   */
  setCallbackByUpdateStep(callbackByUpdateStep: (stepCount: number, stepCurrent: number) => void): void {
    this.callbackByUpdateStep = callbackByUpdateStep;
  }

  setDisplaySize(): void {

  }

  /**
   * 检查手势操作是否继续
   */
  checkTouch(x: number, y: number) {
    if (!this.isAllTouchLeave) {
      return;
    }
    if (x < this.cropShow.getCropMoveRect().left || x > this.cropShow.getCropMoveRect().right ||
      y < this.cropShow.getCropMoveRect().top || y > this.cropShow.getCropMoveRect().bottom) {
      this.isAllTouchLeave = true;
    } else {
      this.isAllTouchLeave = false;
    }
  }

  /**
   * 触摸开始
   * @param x x坐标
   * @param y y坐标
   */
  onTouchStart(x: number, y: number): void {
    if (this.isDoodle) {
      this.checkTouch(x, y);
      this.state = ImageEditState.DOODLE_DRAG;
      this.path2D.moveTo(x, y);
      this.path2DCache.moveTo(this.getScaleX(x), this.getScaleY(y));
      return;
    }

    if (this.isMosaic) {
      this.checkTouch(x, y);
      this.state = ImageEditState.MOSAIC_DRAG;
      this.path2D.moveTo(x, y);
      this.path2DCache.moveTo(this.getScaleX(x), this.getScaleY(y));
      return;
    }

    if (this.state !== ImageEditState.NONE) {
      return;
    }

    if (this.isWaitingRefresh) {
      this.clearDelayRefresh();
    }

    if (this.cropShow.isCropRectTouch(x, y) && this.isCrop) {
      this.state = ImageEditState.CROP_MOVE;
    } else {
      this.state = ImageEditState.IMAGE_DRAG;
    }
    this.isMaskShow = true;
    this.touchPoint.set(x, y);
  }

  /**
   * 触摸移动
   * @param x x坐标
   * @param y y坐标
   */
  onTouchMove(x: number, y: number): void {
    let offsetX = x - this.touchPoint.x;
    let offsetY = y - this.touchPoint.y;
    if (this.state === ImageEditState.DOODLE_DRAG) {
      this.offscreenCanvas.lineWidth = CommonConstants.CTX_DOODLE_LINE_WIDTH;
      this.offscreenCanvas.strokeStyle = Color.Red;
      this.checkTouch(x, y);
      this.onDoodleDrag(x, y);
      return;
    }
    if (this.state === ImageEditState.MOSAIC_DRAG) {
      if (this.pattern) {
        this.offscreenCanvas.lineWidth = CommonConstants.CTX_MOSAIC_LINE_WIDTH;
        this.offscreenCanvas.strokeStyle = this.pattern;
      }
      this.checkTouch(x, y);
      this.onDoodleDrag(x, y);
      return;
    }
    if (this.state === ImageEditState.CROP_MOVE) {
      this.cropShow.moveCropRect(offsetX, offsetY);
    } else if (this.state === ImageEditState.IMAGE_DRAG) {
      this.onImageDrag(offsetX, offsetY);
    } else {
      return;
    }
    this.refresh();
    this.touchPoint.set(x, y);
  }

  /**
   * 触摸结束
   */
  onTouchEnd(): void {
    if (this.state === ImageEditState.DOODLE_DRAG) {
      if (!this.isAllTouchLeave) {
        this.stepAdd(ImageEditState.DOODLE_DRAG);
      }
      // 重置相关参数
      this.isAllTouchLeave = true;
      this.path2D = new Path2D();
      this.path2DCache = new Path2D();
      return;
    }
    if (this.state === ImageEditState.MOSAIC_DRAG) {
      if (!this.isAllTouchLeave) {
        this.stepAdd(ImageEditState.MOSAIC_DRAG);
      }
      // 重置相关参数
      this.isAllTouchLeave = true;
      this.path2D = new Path2D();
      this.path2DCache = new Path2D();
      return;
    }
    if (this.state === ImageEditState.CROP_MOVE) {
      this.cropShow.endCropRectMove();
    } else if (this.state === ImageEditState.IMAGE_DRAG) {
      this.endImageDrag();
      this.refresh();
    } else {
      return;
    }
    this.state = ImageEditState.NONE;
    // 如果正在刷新则中断当前,重新延迟刷新
    if (this.isWaitingRefresh) {
      this.clearDelayRefresh();
    }
    this.delayRefresh(CommonConstants.DEFAULT_TIMEOUT_MILLISECOND_300);
  }

  /**
   * 撤销操作
   */
  onUndo() {
    if (this.stepCurrentIndex == 0) {
      return;
    }

    if (this.stepObjectArray[this.stepCurrentIndex]) {
      switch (this.stepObjectArray[this.stepCurrentIndex].state) {
        case ImageEditState.CROP_MOVE:
          this.stepCurrentIndex--;
          this.callbackByUpdateStep(this.stepObjectArray.length, this.stepCurrentIndex);
          this.cropShow.setRect(this.stepObjectArray[this.stepCurrentIndex]);
          this.onRefresh();
          break;
        case ImageEditState.DOODLE_DRAG:
        case ImageEditState.MOSAIC_DRAG:
          this.stepCurrentIndex--;
          this.callbackByUpdateStep(this.stepObjectArray.length, this.stepCurrentIndex);
          this.stepCurrentPathIndex--;
          this.onRefresh();
          break;
        default:
          break;
      }
    }
  }

  /**
   * 重做操作
   */
  onRedo() {
    let stepIndex = this.stepCurrentIndex + 1;
    if (stepIndex >= this.stepObjectArray.length) {
      return;
    }
    if (this.stepObjectArray[stepIndex]) {
      switch (this.stepObjectArray[stepIndex].state) {
        case ImageEditState.CROP_MOVE:
          this.stepCurrentIndex++;
          this.callbackByUpdateStep(this.stepObjectArray.length, this.stepCurrentIndex);
          this.cropShow.setRect(this.stepObjectArray[stepIndex]);
          this.onRefresh();
          break;
        case ImageEditState.DOODLE_DRAG:
        case ImageEditState.MOSAIC_DRAG:
          this.stepCurrentIndex++;
          this.callbackByUpdateStep(this.stepObjectArray.length, this.stepCurrentIndex);
          this.stepCurrentPathIndex++;
          this.onRefresh();
          break;
        default:
          break;
      }
    }
  }

  /**
   * 计算当前区域延迟刷新
   */
  onRefresh() {
    this.cropShow.endCropRectMove();
    this.state = ImageEditState.NONE;
    // 如果正在刷新则中断当前,重新延迟刷新
    if (this.isWaitingRefresh) {
      this.clearDelayRefresh();
    }
    this.delayRefresh(CommonConstants.DEFAULT_TIMEOUT_MILLISECOND_300);
  }

  /**
   * 多手指手势开始
   * @param x x坐标
   * @param y y坐标
   * @param scale 缩放比例
   */
  onPinchStart(x: number, y: number, scale: number): void {
    this.isMaskShow = true;
    this.state = ImageEditState.IMAGE_SCALE;
    this.pinchPoint.set(x, y);
    this.scale = scale;
  }

  /**
   * 多手指手势更新
   * @param scale 缩放比例
   */
  onPinchUpdate(scale: number): void {
    if (this.state === ImageEditState.IMAGE_SCALE) {
      // 获取缩放倍数
      let factor = scale / this.scale;
      if (!this.cropShow.couldEnlargeImage()) {
        factor = factor > CommonConstants.BASE_SCALE_VALUE ? CommonConstants.BASE_SCALE_VALUE : factor;
      }
      let image = this.cropShow.deepCopyImageRect();
      // 按照手势点缩放相关矩形
      MathUtils.scaleRectBasedOnPoint(image, this.pinchPoint, factor);
      this.cropShow.setImageRect(image);
      if (!this.isCrop) {
        let cropMove = this.cropShow.deepCopyCropMoveRect();
        MathUtils.scaleRectBasedOnPoint(cropMove, this.pinchPoint, factor);
        this.cropShow.setCropMoveRect(cropMove);
      }
      // 刷新
      this.refresh();
      // 更新最新比例
      this.scale *= factor;
    }
  }

  /**
   * 多手指手势更新结束
   */
  onPinchEnd(): void {
    // 不能越过的区域范围
    let crop = this.cropShow.deepCopyCropRect();
    let points = MathUtils.rectToPoints(crop); // 获取裁剪区域

    // 获取比较的区域
    let flipRectF: RectF;
    if (this.isCrop) {
      flipRectF = this.cropShow.deepCopyImageRect();
    } else {
      flipRectF = this.cropShow.deepCopyCropMoveRect();
    }
    let origin = new Point(crop.getCenterX(), crop.getCenterY());
    let centerOffsetX = origin.x - flipRectF.getCenterX();
    let centerOffsetY = origin.y - flipRectF.getCenterY();
    flipRectF.move(centerOffsetX, centerOffsetY);
    // 缩放还是根据图片来
    let scale = MathUtils.findSuitableScale(points, flipRectF, origin);
    flipRectF.move(-centerOffsetX, -centerOffsetY);

    MathUtils.scaleRectBasedOnPoint(flipRectF, origin, scale);
    let offsets = MathUtils.fixImageMove(points, flipRectF);

    let image = this.cropShow.deepCopyImageRect();
    MathUtils.scaleRectBasedOnPoint(image, origin, scale);
    image.move(offsets[0], offsets[1]);
    this.cropShow.setImageRect(image);

    if (!this.isCrop) {
      let cropMove = this.cropShow.deepCopyCropMoveRect();
      MathUtils.scaleRectBasedOnPoint(cropMove, origin, scale);
      cropMove.move(offsets[0], offsets[1]);
      this.cropShow.setCropMoveRect(cropMove);
    }

    this.refresh();
    this.state = ImageEditState.NONE;
    this.delayRefresh(CommonConstants.DEFAULT_TIMEOUT_MILLISECOND_300);
    this.scale = CommonConstants.BASE_SCALE_VALUE;
  }

  /**
   * Current image whether can reset.
   * @returns true means can reset, false means not.
   */
  couldReset(): boolean {
    let crop = this.cropShow.deepCopyCropRect();
    MathUtils.roundOutRect(crop);
    let image = this.cropShow.deepCopyImageRect();
    MathUtils.roundOutRect(image);
    if (!MathUtils.areRectsSame(crop, image)) {
      return true;
    }
    return false;
  }

  /**
   * Reset.
   */
  reset(): void {
    let limit = this.calcNewLimit();
    this.cropShow.init(limit, this.imageRatio);
    this.initialize();
    this.refresh();
  }

  /**
   * Init and clear old content.
   */
  private initialize(): void {
    if (this.pixelMapWrapper !== undefined) {
      this.imageRatio = this.pixelMapWrapper.width / this.pixelMapWrapper.height;
    }
    this.determineMaxScaleFactor();
  }

  /**
   * 更改图像时，再次计算限制大小
   * @returns 限制区域
   */
  private calcNewLimit(): RectF {
    let limit = new RectF();
    limit.set(this.marginW, this.marginH, this.viewWidth - this.marginW, this.viewHeight - this.marginH * 2);
    return limit;
  }

  /**
   * 计算最大比例因子
   */
  private determineMaxScaleFactor(): void {
    if (this.pixelMapWrapper == undefined) {
      return;
    }
    let scaleFactorW = this.pixelMapWrapper.width / px2vp(CommonConstants.DEFAULT_MIN_SIDE_LENGTH_EDIT);
    let scaleFactorH = this.pixelMapWrapper.height / px2vp(CommonConstants.DEFAULT_MIN_SIDE_LENGTH_EDIT);
    this.cropShow.setMaxScaleFactor(scaleFactorW, scaleFactorH);
  }

  /**
   * 获取涂鸦\马赛克的pixelMap
   */
  getDoodlePixelMap(): PixelMap {
    // 先清空
    this.offscreenCanvas.clearRect(0, 0, this.contextDoodle.width, this.contextDoodle.height);
    this.drawDoodle();
    return this.offscreenCanvas.getPixelMap(this.cropShow.getCropRect().left,
      this.cropShow.getCropRect().top, this.cropShow.getCropRect().getWidth(),
      this.cropShow.getCropRect().getHeight())
  }

  /**
   * 刷新
   */
  private refresh(): void {
    if (this.canvasReady) {
      // 先清空
      this.contextImage.clearRect(0, 0, this.viewWidth, this.viewHeight);
      this.contextDoodle.clearRect(0, 0, this.contextDoodle.width, this.contextDoodle.height);
      this.offscreenCanvas.clearRect(0, 0, this.contextDoodle.width, this.contextDoodle.height);
      // 这个先留着
      // this.ctx.translate(0, 0);
      this.drawImage();
      this.drawDoodle();
      this.drawCrop();
      // 离线绘制
      let imageData = this.offscreenCanvas.transferToImageBitmap();
      this.contextDoodle.transferFromImageBitmap(imageData);
    }
  }

  /**
   * 延迟刷新
   * @param delay
   */
  private delayRefresh(delay: number): void {
    this.isWaitingRefresh = true;
    this.timeoutId = setTimeout(() => {
      this.cropShow.enlargeCropArea(this.isCrop);
      this.isMaskShow = false;
      this.refresh();
      this.isWaitingRefresh = false;
    }, delay);
  }

  /**
   * 清除延迟刷新。
   */
  private clearDelayRefresh(): void {
    clearTimeout(this.timeoutId);
    this.isWaitingRefresh = false;
  }

  /**
   * 绘制图片
   */
  private drawImage(): void {
    this.contextImage.save();
    let imageRect = this.cropShow.deepCopyImageRect();
    MathUtils.roundOutRect(imageRect);
    if (this.pixelMapWrapper !== undefined) {
      this.contextImage.drawImage(this.pixelMapWrapper.pixelMap, imageRect.left, imageRect.top,
        imageRect.getWidth(),
        imageRect.getHeight());
    }
    this.contextImage.restore();
  }

  /**
   * 绘制裁剪区域
   */
  private drawCrop(): void {
    let display = new RectF();
    display.set(0, 0, this.viewWidth, this.viewHeight);
    // DrawingUtils.drawRect(this.offscreenCanvas, this.cropShow.getCropRect(), "#dd5562");
    // DrawingUtils.drawRect(this.offscreenCanvas, this.cropShow.getImageRect(), "#FFFFFF");
    // DrawingUtils.drawRect(this.offscreenCanvas, this.cropShow.getLimitRect(), "#dd5562");
    // DrawingUtils.drawRect(this.offscreenCanvas, this.cropShow.getCropMoveRect(), "#a66545");
    // DrawingUtils.drawRect(this.offscreenCanvas, display, "#a66545");
    // 绘制透明蒙层,先决定是否显示蒙层还是纯黑色
    this.offscreenCanvas.save();
    if (this.isCrop) {
      let crop = this.cropShow.deepCopyCropRect();
      let image = this.cropShow.deepCopyImageRect();
      MathUtils.roundOutRect(crop);
      MathUtils.roundOutRect(image);
      DrawingUtils.drawMask(this.offscreenCanvas, display, crop, this.isMaskShow);

      // 绘制裁剪区域
      DrawingUtils.drawRect(this.offscreenCanvas, crop, CommonConstants.DEFAULT_RECT_LINE_COLOR);
      DrawingUtils.drawCropButton(this.offscreenCanvas, crop);
      if (this.isMaskShow) {
        DrawingUtils.drawSplitLine(this.offscreenCanvas, crop);
      }
    } else {
      let cropMove = this.cropShow.deepCopyCropMoveRect();
      MathUtils.roundOutRect(cropMove);
      DrawingUtils.drawMask(this.offscreenCanvas, display, cropMove, false);
    }
    this.offscreenCanvas.restore();
  }

  /**
   * 绘制涂鸦方面的遮罩层
   */
  private drawDoodleMask(): void {
    let display = new RectF();
    display.set(0, 0, this.viewWidth, this.viewHeight);
    let cropMove = this.cropShow.deepCopyCropMoveRect();
    MathUtils.roundOutRect(cropMove);
    DrawingUtils.drawMask(this.offscreenCanvas, display, cropMove, false);
  }

  /**
   * 绘制图片.
   * @param offsetX
   * @param offsetY
   */
  private onImageDrag(offsetX: number, offsetY: number): void {
    let image = this.cropShow.deepCopyImageRect();
    let cropMove = this.cropShow.deepCopyCropMoveRect();
    // 相关区域随着手势移动
    image.move(offsetX, offsetY);
    cropMove.move(offsetX, offsetY);
    this.cropShow.setImageRect(image);
    this.cropShow.setCropMoveRect(cropMove);
  }

  /**
   * 移动图片后结束,恢复图片位置
   */
  private endImageDrag(): void {
    // 不能越过的区域范围
    let crop = this.cropShow.deepCopyCropRect();
    let points = MathUtils.rectToPoints(crop);

    // 获取比较的区域
    let flipImage: RectF;
    if (this.isCrop) {
      flipImage = this.cropShow.getImageRect();
    } else {
      flipImage = this.cropShow.getCropMoveRect();
    }
    let offsets = MathUtils.fixImageMove(points, flipImage);
    let image = this.cropShow.deepCopyImageRect();
    let cropMove = this.cropShow.deepCopyCropMoveRect();
    // 图片越过限制位置时,将它恢复
    image.move(offsets[0], offsets[1]);
    cropMove.move(offsets[0], offsets[1]);
    this.cropShow.setImageRect(image);
    this.cropShow.setCropMoveRect(cropMove);
  }

  /**
   * 绘制涂鸦
   */
  private drawDoodle(): void {
    // 存储当前的设置,因为中途会改变位置translate
    this.offscreenCanvas.save();
    // 裁剪模式和非裁剪模式计算缩放的方式不一样
    let scale = 1;
    if (this.isCrop) {
      scale = this.cropShow.getImageRect().getWidth() / this.cropShow.deepCopyLimitRect().getWidth();
    } else {
      scale = this.cropShow.getImageRect().getWidth() / this.cropShow.deepCopyLimitRect().getWidth();
    }
    let marginLeft = CommonConstants.DEFAULT_MARGIN_LENGTH * scale;
    let marginTop = this.marginTop * scale;
    this.offscreenCanvas.translate(this.cropShow.getImageRect().left - marginLeft,
      this.cropShow.getImageRect().top + marginTop - marginLeft);
    this.offscreenCanvas.scale(scale, scale);
    this.scaleCurrent = scale;
    for (let index = 0; index <= this.stepCurrentPathIndex; index++) {
      if (this.path2DArray[index].type == ImageEditState.DOODLE_DRAG) {
        this.offscreenCanvas.strokeStyle = Color.Red;
        this.offscreenCanvas.lineWidth = CommonConstants.CTX_DOODLE_LINE_WIDTH / this.path2DArray[index].scale;
      } else {
        if (this.pattern) {
          this.offscreenCanvas.strokeStyle = this.pattern;
          this.offscreenCanvas.lineWidth = CommonConstants.CTX_MOSAIC_LINE_WIDTH / this.path2DArray[index].scale;
        }
      }
      this.offscreenCanvas.stroke(this.path2DArray[index].path2D);
    }
    this.offscreenCanvas.restore();
  }

  /**
   * 进行涂鸦
   */
  private onDoodleDrag(offsetX: number, offsetY: number) {
    this.path2D.lineTo(offsetX, offsetY);
    this.offscreenCanvas.stroke(this.path2D);
    this.path2DCache.lineTo(this.getScaleX(offsetX), this.getScaleY(offsetY));
    this.drawDoodleMask();
    // 将离线绘制的数据反馈到ui界面
    let imageData = this.offscreenCanvas.transferToImageBitmap()
    this.contextDoodle.transferFromImageBitmap(imageData)
  }

  /**
   * 步骤添加
   *
   * @param stepState 步骤类型
   */
  private stepAdd(stepState: ImageEditState) {
    if (stepState === ImageEditState.DOODLE_DRAG || stepState === ImageEditState.MOSAIC_DRAG) {
      // 针对涂鸦添加的步骤
      let path2DObject = new Path2DObject();
      path2DObject.path2D = this.path2DCache;
      path2DObject.scale = this.scaleCurrent;
      path2DObject.type = stepState;
      // 判断中途是否撤销重做功能
      if (this.stepCurrentPathIndex < this.path2DArray.length - 1) {
        let index = this.stepCurrentPathIndex + 1;
        // splice(起始位置, 删除数量)
        this.path2DArray.splice(index, this.path2DArray.length - index);
      }
      this.path2DArray.push(path2DObject);
      this.stepCurrentPathIndex++;
    }
    let stepObject = new StepObject();
    stepObject.state = stepState;
    this.cropShow.addCropStep(stepObject);
    // 判断中途是否撤销重做功能
    if (this.stepCurrentIndex < this.stepObjectArray.length - 1) {
      let index = this.stepCurrentIndex + 1;
      // splice(起始位置, 删除数量)
      this.stepObjectArray.splice(index, this.stepObjectArray.length - index);
    }
    this.stepObjectArray.push(stepObject);
    this.stepCurrentIndex++;
    this.callbackByUpdateStep(this.stepObjectArray.length, this.stepCurrentIndex);
  }

  /**
   * 从非裁剪模式切换裁剪模式
   */
  recover(): void {
    // 不能越过的区域范围
    let crop = this.cropShow.deepCopyCropRect();
    let points = MathUtils.rectToPoints(crop);

    // 获取比较的区域
    let flipRectF: RectF;
    flipRectF = this.cropShow.deepCopyCropMoveRect();
    let origin = new Point(crop.getCenterX(), crop.getCenterY());
    let centerOffsetX = origin.x - flipRectF.getCenterX();
    let centerOffsetY = origin.y - flipRectF.getCenterY();
    flipRectF.move(centerOffsetX, centerOffsetY);
    // 缩放还是根据图片来
    let scale = crop.getWidth() / flipRectF.getWidth();
    flipRectF.move(-centerOffsetX, -centerOffsetY);

    MathUtils.scaleRectBasedOnPoint(flipRectF, origin, scale);
    let offsets = MathUtils.fixImageMove(points, flipRectF);

    let image = this.cropShow.deepCopyImageRect();
    MathUtils.scaleRectBasedOnPoint(image, origin, scale);
    image.move(offsets[0], offsets[1]);
    this.cropShow.setImageRect(image);

    let cropMove = this.cropShow.deepCopyCropMoveRect();
    MathUtils.scaleRectBasedOnPoint(cropMove, origin, scale);
    cropMove.move(offsets[0], offsets[1]);
    this.cropShow.setCropMoveRect(cropMove);

    this.state = ImageEditState.NONE;
    this.delayRefresh(CommonConstants.DEFAULT_TIMEOUT_MILLISECOND_300);
    this.scale = CommonConstants.BASE_SCALE_VALUE;
  }

  /**
   * 按照比例针对x进行改变
   * @returns
   */
  getScaleX(x: number) {
    // 计算放大后，等比例对应的位置
    return x / this.scaleCurrent - this.cropShow.getImageRect().left / this.scaleCurrent +
    CommonConstants.DEFAULT_MARGIN_LENGTH
  }

  /**
   * 按照比例针对y进行改变
   * @returns
   */
  getScaleY(y: number) {
    return y / this.scaleCurrent - this.cropShow.getImageRect().top / this.scaleCurrent + Math.abs(this.marginTop) +
    CommonConstants.DEFAULT_MARGIN_LENGTH
  }

  /**
   * 异步获取马赛克图片
   */
  async getMosaicPixelMap() {
    const resourceMgr = getContext(this).resourceManager;
    const context = getContext(this);
    let imageBuffer = await resourceMgr.getMediaContent($r('app.media.mosaic'))
    let filePath = context.cacheDir + '/mosaic.jpg';
    let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.writeSync(file.fd, imageBuffer.buffer);
    const imageSourceApi = image.createImageSource(file.fd);
    const pixelMap = imageSourceApi.createPixelMapSync({
      editable: true
    });
    return pixelMap;
  }
}