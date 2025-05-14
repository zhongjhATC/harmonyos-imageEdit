import { image } from "@kit.ImageKit";
import { ImageEditView, CropMoveType } from "@zhongjh/image_edit";

@Builder
export function RegisterBuilder() {
  ImageEditPage()
}

/**
 * 编辑图片界面,具体如何使用根据自身场景调用
 */
@Entry
@Component
struct ImageEditPage {
  navPathStack: NavPathStack = new NavPathStack();
  /**
   * 图片数据源
   */
  pixelMap: image.PixelMap = undefined!;
  /**
   * 监控保存后,返回一个新的图片数据源
   */
  @Provide @Watch('listenNewBase64') mergedPixelMap: image.PixelMap | undefined = undefined;

  build() {
    NavDestination() {
      Row() {
        if (this.pixelMap) {
          ImageEditView({
            pixelMap: this.pixelMap,
            onCancel: () => {
              this.navPathStack?.pop({ isCancel: true }, true);
            },
            apiModel: {
              cropMoveType: CropMoveType.All,
              isScale: true
            }
          })
        }
      }
    }
    .onReady((context: NavDestinationContext) => {
      this.navPathStack = context.pathStack;
      this.pixelMap = this.navPathStack.getParamByName('ImageEditPage')[0] as image.PixelMap;
    })
    .onBackPressed(() => {
      this.navPathStack?.pop({ isCancel: true }, true);
      return true;
    })
    .hideTitleBar(true)
  }

  /**
   * 监控保存后,返回一个新的Base64数据
   */
  async listenNewBase64() {
    if (this.mergedPixelMap) {
      this.navPathStack?.pop(this.mergedPixelMap);
    }
  }
}