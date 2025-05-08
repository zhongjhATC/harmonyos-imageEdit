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

import image from '@ohos.multimedia.image';
import { menuIconList } from '../entity/IconListViewModel';
import { CommonConstants } from '../common/CommonConstants';
import { ImageSelect } from './ImageSelectView';
import { ImageSizeItem } from '../entity/ImageSizeItem';
import { ImageEditManager } from '../api/ImageEditManager';
import { promptAction } from '@kit.ArkUI';
import { ConstantsID } from '../common/ConstantsID';
import { MainTabId } from '../common/ImageEditType';
import { ApiModel } from '../entity/ApiModel';
import Logger from '../utils/LoggerUtil';

/**
 * 编辑页面组件,方便随便扩展page
 * 主要提供相关功能UI
 */
@Component
export struct ImageEdit {
  /**
   * 功能模块索引
   */
  @State @Watch('listenCurrentIndex') currentIndex: number = -1;
  /**
   * 记录裁剪前的功能索引,用于取消时,进入该索引
   */
  backupCurrentIndex: number = 0;
  /**
   * 图片数据源
   */
  @Provide pixelMap: image.PixelMap | undefined = undefined;
  /**
   * 图片的其他参数
   */
  @Provide imageInfo: image.ImageInfo | undefined = undefined;
  /**
   * 初始化图片后才设置true
   */
  @Provide showCanvas: boolean = false;
  /**
   * 屏幕高度
   */
  @Provide screenHeight: number = 0;
  /**
   * 图片的宽高
   */
  @Provide imageSize: ImageSizeItem = { width: 0, height: 0 };
  /**
   * 底部菜单
   */
  private menuIconChangeList = menuIconList;
  /**
   * 避让区域(顶部状态栏+底部导航栏)的高度
   */
  @Provide avoidHeight: number = 0;
  /**
   * 保存操作
   */
  @Provide isSave: boolean = false;
  /**
   * 是否可进行撤销
   */
  @Provide isUndo: boolean = false;
  /**
   * 撤销操作
   */
  @Provide onUndo: boolean = false;
  /**
   * 是否可进行重做
   */
  @Provide isRedo: boolean = false;
  /**
   * 重做操作
   */
  @Provide onRedo: boolean = false;
  /**
   * 启动/关闭裁剪
   */
  @Provide isCrop: boolean = this.currentIndex === 1;
  /**
   * 启动/关闭马赛克
   */
  @Provide isMosaic: boolean = this.currentIndex === 2;
  /**
   * 裁剪界面-进行取消
   */
  @Provide isCancelCrop: boolean = false;
  /**
   * 启动/关闭涂鸦
   */
  @Provide isDoodle: boolean = this.currentIndex === 0;
  /**
   * 支持调用者在外部修改的参数
   */
  @Provide apiModel: ApiModel = new ApiModel();
  /**
   * 提供给父组件设置取消事件
   */
  onCancel?: () => void;

  async aboutToAppear() {
    this.avoidHeight = ImageEditManager.getInstance().statusBarHeight + ImageEditManager.getInstance().naviBarHeight;
    await this.pixelInit();
  }

  build() {
    RelativeContainer() {
      // 标题控件
      this.TitleBuilder()

      // 图片控件
      this.ImageBuilder()

      if (!this.isCrop) {
        // 底部菜单控件
        this.MenuBuilder()
      }

      if (this.isCrop) {
        // 裁剪底部菜单控件
        this.MenuCropBuilder()
      }
    }
    .width(CommonConstants.LAYOUT_FULL_SCREEN)
    .height(CommonConstants.LAYOUT_FULL_SCREEN)
    .padding({
      bottom: ImageEditManager.getInstance().naviBarHeight,
      top: ImageEditManager.getInstance().statusBarHeight
    })
    .backgroundColor(Color.Black)
  }

  @Builder
  TitleBuilder() {
    // 取消文本
    Text($r('app.string.cancel'))
      .fontColor(Color.White)
      .fontSize($r('app.float.title_font_size'))
      .id(ConstantsID.TEXT_CANCEL)
      .alignRules({
        top: { anchor: ConstantsID.CONTAINER_ID, align: VerticalAlign.Top },
        left: { anchor: ConstantsID.CONTAINER_ID, align: HorizontalAlign.Start }
      })
      .onClick(() => {
        this.onCancel?.();
      })
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 10
      })
      .visibility(this.isCrop ? Visibility.Hidden : Visibility.Visible)

    // 重做按钮
    Image($r('app.media.ic_redo'))
      .width(48)
      .height(44)
      .fillColor(this.isRedo ? Color.White : $r('app.color.eraser_top_button_disabled_color'))
      .enabled(this.isRedo)
      .id(ConstantsID.IMAGE_REDO)
      .alignRules({
        top: { anchor: ConstantsID.CONTAINER_ID, align: VerticalAlign.Top },
        right: { anchor: ConstantsID.CONTAINER_ID, align: HorizontalAlign.End }
      })
      .onClick(() => {
        this.onRedo = !this.onRedo
      })
      .padding({
        left: 8,
        right: 16,
        top: 10,
        bottom: 10
      })
      .visibility(this.isCrop ? Visibility.Hidden : Visibility.Visible)

    // 撤销按钮
    Image($r('app.media.ic_undo'))
      .width(48)
      .height(44)
      .fillColor(this.isUndo ? Color.White : $r('app.color.eraser_top_button_disabled_color'))
      .enabled(this.isUndo)
      .id(ConstantsID.IMAGE_UNDO)
      .alignRules({
        top: { anchor: ConstantsID.CONTAINER_ID, align: VerticalAlign.Top },
        right: { anchor: ConstantsID.IMAGE_REDO, align: HorizontalAlign.Start }
      })
      .onClick(() => {
        this.onUndo = !this.onUndo
      })
      .padding({
        left: 16,
        right: 8,
        top: 10,
        bottom: 10
      })
      .visibility(this.isCrop ? Visibility.Hidden : Visibility.Visible)
  }

  @Builder
  ImageBuilder() {
    Column() {
      if (this.showCanvas) {
        ImageSelect()
      }
    }
    .clip(false)
    .width(CommonConstants.LAYOUT_FULL_SCREEN)
    .height((CommonConstants.EDIT_SCREEN_USAGE * 100) + '%')
    .alignRules({
      top: { anchor: ConstantsID.TEXT_CANCEL, align: VerticalAlign.Bottom },
    })
  }

  @Builder
  MenuBuilder() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
      }
      .tabBar(this.TabBuilderMenu(MainTabId.DOODLE, $r('app.string.doodle')))

      TabContent() {
      }
      .tabBar(this.TabBuilderMenu(MainTabId.CROP, $r('app.string.crop')))

      TabContent() {
      }
      .tabBar(this.TabBuilderMenu(MainTabId.MOSAIC, $r('app.string.mosaic')))
    }
    .id(ConstantsID.TABS_MENU)
    .scrollable(false)
    .onTabBarClick((index: number) => {
      if (index === this.currentIndex) {
        // 取消当前模式
        index = -1;
      }
      // 设置当前模式
      this.backupCurrentIndex = this.currentIndex;
      this.currentIndex = index;
    })
    .width('60%')
    .height('auto')
    .backgroundColor(Color.Black)
    .margin({ bottom: 7.5 })
    .alignRules({
      bottom: { anchor: ConstantsID.CONTAINER_ID, align: VerticalAlign.Bottom },
      left: { anchor: ConstantsID.CONTAINER_ID, align: HorizontalAlign.Start }
    })

    Button('完成', { type: ButtonType.Normal })
      .id(ConstantsID.BTN_COMPLETE)
      .height(33)
      .width(65)
      .backgroundColor('#ff00B849')
      .fontColor(Color.White)
      .borderRadius(8)
      .margin({ right: 16 })
      .alignRules({
        right: { anchor: ConstantsID.CONTAINER_ID, align: HorizontalAlign.End },
        bottom: { anchor: ConstantsID.TABS_MENU, align: VerticalAlign.Bottom },
        top: { anchor: ConstantsID.TABS_MENU, align: VerticalAlign.Top }
      })
      .onClick(() => {
        this.isSave = true;
      })
  }

  @Builder
  MenuCropBuilder() {
    // 取消裁剪按钮
    Image($r('app.media.ic_close'))
      .id(ConstantsID.IMAGE_CROP_CLOSE)
      .width($r('app.float.title_image_width'))
      .height($r('app.float.title_image_height'))
      .alignRules({
        bottom: { anchor: ConstantsID.CONTAINER_ID, align: VerticalAlign.Bottom },
        left: { anchor: ConstantsID.CONTAINER_ID, align: HorizontalAlign.Start }
      })
      .onClick(() => {
        // 取消裁剪
        this.isCancelCrop = true;
        this.currentIndex = this.backupCurrentIndex;
      })
      .margin({
        left: 30,
        bottom: 10
      })

    // 提交裁剪按钮
    Image($r('app.media.ic_submit'))
      .id(ConstantsID.IMAGE_CROP_SUBMIT)
      .width($r('app.float.title_image_width'))
      .height($r('app.float.title_image_height'))
      .alignRules({
        bottom: { anchor: ConstantsID.CONTAINER_ID, align: VerticalAlign.Bottom },
        right: { anchor: ConstantsID.CONTAINER_ID, align: HorizontalAlign.End }
      })
      .onClick(() => {
        // 确认裁剪
        this.currentIndex = this.backupCurrentIndex;
      })
      .margin({
        right: 30,
        bottom: 10
      })
  }

  @Builder
  TabBuilderMenu(index: number, name: string | Resource) {
    Column() {
      Image(this.menuIconChangeList[index]?.src)
        .fillColor(this.currentIndex === index ? Color.Green : Color.White)
        .width(CommonConstants.TAB_MENU_WIDTH)
        .height(CommonConstants.TAB_MENU_WIDTH)

      Text(name)
        .fontColor(this.currentIndex === index ? Color.Green : Color.White)
        .fontSize($r('app.float.category_font_size'))
        .margin({ top: $r('app.float.category_margin_top') })
    }
    .width(CommonConstants.LAYOUT_FULL_SCREEN)
  }

  /**
   * 更新imageInfo数据
   */
  async updateImageInfo() {
    Logger.debug('ImageEditView', 'updateImageInfo 开始');
    if (this.pixelMap !== undefined) {
      let imageInfo = await this.pixelMap.getImageInfo()
      this.imageInfo = imageInfo;
      this.imageSize = {
        width: px2vp(this.imageInfo.size.width),
        height: px2vp(this.imageInfo.size.height)
      }
      this.showCanvas = true;
    }
    Logger.debug('ImageEditView', 'updateImageInfo 结束');
  }

  /**
   * 图片初始化
   */
  async pixelInit() {
    Logger.debug('ImageEditView', 'pixelInit 开始');
    this.showCanvas = false;
    if (this.pixelMap == undefined) {
      promptAction.showToast({
        message: 'pixelMap参数不能为空',
        duration: 2000, // 显示持续时间，单位为毫秒
        showMode: promptAction.ToastShowMode.DEFAULT, // 显示模式，可以是DEFAULT或TOP_MOST
        bottom: 80 // 与软键盘的距离，仅当软键盘遮挡了Toast时有效
      })
    }
    this.updateImageInfo();
    Logger.debug('ImageEditView', 'pixelInit 结束');
  }

  /**
   * 监控底部按钮功能变化
   */
  listenCurrentIndex() {
    // 是否启动涂鸦
    this.isDoodle = this.currentIndex === 0;
    // 是否启动裁剪
    this.isCrop = this.currentIndex === 1;
    // 是否启动马赛克
    this.isMosaic = this.currentIndex === 2;
    if (this.isCrop) {
      this.isCancelCrop = false;
    }
  }

  /**
   * 异步创建像素图
   *
   * @return pixelMap.
   */
  async getPixelMap() {
    if (this.pixelMap) {
      // 使用新创建的PixelMap对象替换旧的对象引用。这样，返回到上一个页面给pixelMap赋值的时候,上一个页面的image组件才能感知到数据的变化，并更新显示的图像
      const imageInfo = this.pixelMap.getImageInfoSync();
      const buffer = new ArrayBuffer(this.pixelMap.getPixelBytesNumber());
      this.pixelMap.readPixelsToBufferSync(buffer);
      let options: image.InitializationOptions = {
        srcPixelFormat: imageInfo.pixelFormat,
        pixelFormat: imageInfo.pixelFormat,
        size: imageInfo.size
      };
      // 替换对象
      let newPixelMap = image.createPixelMapSync(buffer, options);
      this.pixelMap = newPixelMap;
      return this.pixelMap;
    }
    return undefined;
  }
}