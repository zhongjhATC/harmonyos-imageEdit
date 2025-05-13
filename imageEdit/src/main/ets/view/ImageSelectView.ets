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

import display from '@ohos.display';
import image from '@ohos.multimedia.image';
import { ImageEdit } from '../viewModel/ImageEdit';
import { ImageSizeItem } from '../entity/ImageSizeItem';
import { CommonConstants } from '../common/CommonConstants';
import { PixelMapWrapper } from '../entity/PixelMapWrapper';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MathUtils } from '../utils/MathUtils';
import { ApiModel } from '../entity/ApiModel';

const TAG = 'ImageSelect';

/**
 * 图片组件,包含以下功能点(不实现，由viewModel.ImageEdit实现)：
 * 涂鸦、裁剪、马赛克、撤销、重做、保存
 */
@Component
export struct ImageSelect {
  /**
   * 图片编辑类
   */
  @State imageEdit: ImageEdit | undefined = undefined;
  @State isVerticalScreen: boolean = true;
  /**
   * 图片数据源
   */
  @Consume imageInfo: image.ImageInfo;
  /**
   * 图片数据源
   */
  @Consume pixelMap: image.PixelMap | undefined;
  /**
   * 保存后新的pixelMap 图片数据源
   */
  @Consume mergedPixelMap: image.PixelMap;
  /**
   * 支持调用者在外部修改的参数
   */
  @Consume apiModel: ApiModel;
  /**
   * 初始化图片后才设置true
   */
  @Consume showCanvas: boolean;
  /**
   * 图片的宽高
   */
  @Consume imageSize: ImageSizeItem;
  /**
   * 监控是否执行保存操作
   */
  @Consume @Watch('listenSave') isSave: boolean;
  /**
   * 是否可进行撤销
   */
  @Consume isUndo: boolean;
  /**
   * 监控撤销操作
   */
  @Consume @Watch('listenUndo') onUndo: boolean;
  /**
   * 是否可进行重做
   */
  @Consume isRedo: boolean;
  /**
   * 监控重做操作
   */
  @Consume @Watch('listenRedo') onRedo: boolean;
  /**
   * 监控是否启动/关闭裁剪
   */
  @Consume @Watch('listenCrop') isCrop: boolean;
  /**
   * 监控是否取消裁剪
   */
  @Consume @Watch('listenCancelCrop') isCancelCrop: boolean;
  /**
   * 监控是否启动/关闭涂鸦
   */
  @Consume @Watch('listenDoodle') isDoodle: boolean;
  /**
   * 监控是否启动/关闭马赛克
   */
  @Consume @Watch('listenMosaic') isMosaic: boolean;
  /**
   * 避让区域(顶部状态栏+底部导航栏)的高度
   */
  @Consume avoidHeight: number;
  /**
   * 用于判断手势每间隔时间触发事件
   */
  private prePinch: number = 0;
  /**
   * 图片+蒙版绘制控件
   */
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private contextDoodle: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  /**
   * 显示参数
   */
  private defaultDisplay: display.Display = {} as display.Display;

  /**
   * 监控保存
   */
  listenSave() {
    if (this.isSave && this.imageEdit !== undefined && this.pixelMap !== undefined) {
      let doodlePixelMap = this.imageEdit.getDoodlePixelMap();

      // 先绘制原图,为什么要重新绘制不直接offContext.toDataURL?因为原本的画架context多次保存后左边角会有黑影,所以要重新绘制
      let size = this.pixelMap.getImageInfoSync().size;
      // 获取百分比,因为裁剪区域的大小不是真实大小,要跟真实图片计算比例才行
      let widthPercentage =
        this.imageEdit.cropShow.getCropRect().getWidth() / this.imageEdit.cropShow.getImageRect().getWidth()
      let heightPercentage =
        this.imageEdit.cropShow.getCropRect().getHeight() / this.imageEdit.cropShow.getImageRect().getHeight()
      let newWidth = size.width * widthPercentage;
      let newHeight = size.height * heightPercentage;

      let crop = this.imageEdit.cropShow.getCropRect();
      let image = this.imageEdit.cropShow.getImageRect();
      crop.move(-image.left, -image.top);
      MathUtils.normalizeRect(crop, image.getWidth(), image.getHeight());
      let left = size.width * crop.left;
      let top = size.height * crop.top;

      // 创建一个新的画布来放置选定的图像数据,以裁剪区域的宽高、位置决定
      let offscreenCanvas: OffscreenCanvas = new OffscreenCanvas(px2vp(newWidth), px2vp(newHeight));
      let offContext = offscreenCanvas.getContext('2d');
      offContext.imageSmoothingQuality = 'high'

      this.pixelMap.cropSync({
        size: { width: newWidth, height: newHeight },
        x: left, y: top,
      })
      offContext.drawImage(this.pixelMap, 0, 0, offscreenCanvas.width, offscreenCanvas.height);
      offContext.drawImage(doodlePixelMap, 0, 0, offscreenCanvas.width, offscreenCanvas.height);
      // 获取合并后的PixelMap
      this.mergedPixelMap = offContext.getPixelMap(0, 0, offscreenCanvas.width, offscreenCanvas.height);
      // 释放
      doodlePixelMap.release();
      this.pixelMap.release();
    }
  }

  /**
   * 初始化
   */
  aboutToAppear() {
    this.initImageSize();
  }

  build() {
    Stack() {
      Canvas(this.context)
        .width(CommonConstants.LAYOUT_FULL_SCREEN)
        .height(CommonConstants.LAYOUT_FULL_SCREEN)
        .onReady(() => {
          if (this.imageEdit !== undefined) {
            this.imageEdit.setCanvasReady(true);
            let offscreenCanvas: OffscreenCanvas =
              new OffscreenCanvas(Math.ceil(this.context.width), Math.ceil(this.context.height) + 1);
            let offContext = offscreenCanvas.getContext('2d', this.settings);

            this.imageEdit.setCanvasContext(this.context, this.contextDoodle, offContext);
          }
        })
      Canvas(this.contextDoodle)
        .width(CommonConstants.LAYOUT_FULL_SCREEN)
        .height(CommonConstants.LAYOUT_FULL_SCREEN)
    }
    .width(CommonConstants.LAYOUT_FULL_SCREEN)
    .height(CommonConstants.LAYOUT_FULL_SCREEN)
    // 双手势事件
    .gesture(PinchGesture()
      .onActionStart(this.apiModel.isScale ? (event: GestureEvent) => {
        this.onPinchGestureStart(event);
      } : undefined)
      .onActionUpdate(this.apiModel.isScale ? (event: GestureEvent) => {
        this.onPinchGestureUpdate(event);
      } : undefined)
      .onActionEnd(this.apiModel.isScale ? () => {
        this.onPinchGestureEnd();
      } : undefined))
    .onTouch((event) => {
      // 触摸事件,包括裁剪移动
      this.onTouchStart(event);
    })
  }

  /**
   * 初始化
   */
  initImageSize() {
    try {
      this.defaultDisplay = display.getDefaultDisplaySync();
      let screenWidth = px2vp(this.defaultDisplay.width);
      // 算法：(整个屏幕 - 避让区域 - 上下间距 - 裁剪角高度) * 百分比
      let screenHeight =
        px2vp((this.defaultDisplay.height - this.avoidHeight - CommonConstants.DEFAULT_MARGIN_LENGTH * 2) *
        CommonConstants.EDIT_SCREEN_USAGE) -
          (CommonConstants.DEFAULT_BUTTON_WIDTH + CommonConstants.DEFAULT_BUTTON_PADDING) * 2;
      this.imageEdit = new ImageEdit(this.apiModel);
      if (this.pixelMap !== undefined) {
        this.imageEdit.entry(new PixelMapWrapper(this.pixelMap, this.imageSize.width, this.imageSize.height));
      }
      // 这个必须在setCanvasSize的前面
      this.imageEdit.setCallbackByUpdateStep((stepCount: number, stepCurrent: number) => {
        if (stepCurrent >= stepCount - 1) {
          this.isRedo = false;
        } else {
          this.isRedo = true;
        }
        if (stepCurrent == 0) {
          this.isUndo = false;
        } else {
          this.isUndo = true;
        }
      })
      this.imageEdit.setCanvasSize(screenWidth, screenHeight);

    } catch (exception) {
      hilog.error(0x0000, TAG,
        (`Failed to obtain the default display object. Code:  ${JSON.stringify(this.defaultDisplay)}`));
    }
  }

  /**
   * 触摸事件
   * @param event 手势
   */
  onTouchStart(event: TouchEvent): void {
    if (this.imageEdit !== undefined) {
      let x = event.touches[0].x;
      let y = event.touches[0].y;
      if (event.type === TouchType.Down) {
        this.imageEdit.onTouchStart(x, y);
      } else if (event.type === TouchType.Move) {
        this.imageEdit.onTouchMove(x, y);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.imageEdit.onTouchEnd();
      }
    }
  }

  /**
   * 多手指手势开始
   * @param event 手势
   */
  onPinchGestureStart(event: GestureEvent): void {
    this.prePinch = new Date().getTime();
    if (this.imageEdit !== undefined) {
      this.imageEdit.onPinchStart(event.pinchCenterX, event.pinchCenterY, event.scale);
    }
  }

  /**
   * 多手指手势更新
   * @param event 手势
   */
  onPinchGestureUpdate(event: GestureEvent): void {
    let now = new Date().getTime();
    if (now - this.prePinch >= CommonConstants.TIMEOUT) {
      this.prePinch = now;
      if (this.imageEdit !== undefined) {
        this.imageEdit.onPinchUpdate(event.scale);
      }
    }
  }

  /**
   * 多手指手势更新结束
   * @param event 手势
   */
  onPinchGestureEnd(): void {
    if (this.imageEdit !== undefined) {
      this.imageEdit.onPinchEnd();
    }
  }

  /**
   * 撤销
   */
  listenUndo() {
    this.imageEdit?.onUndo();
  }

  /**
   * 重做
   */
  listenRedo() {
    this.imageEdit?.onRedo();
  }

  /**
   * 启动/关闭裁剪
   */
  listenCrop() {
    this.imageEdit?.enableCrop(this.isCrop, this.isCancelCrop);
  }

  /**
   * 取消裁剪
   */
  listenCancelCrop() {
    if (this.isCancelCrop) {
      this.imageEdit?.cancelCrop();
    }
  }

  /**
   * 启动/关闭涂鸦
   */
  listenDoodle() {
    this.imageEdit?.enableDoodle(this.isDoodle);
  }

  /**
   * 启动/关闭马赛克
   */
  listenMosaic() {
    this.imageEdit?.enableMosaic(this.isMosaic);
  }
}