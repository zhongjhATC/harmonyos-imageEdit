import { image } from "@kit.ImageKit";
import { ImageEdit, CropMoveType } from "@zhongjh/image_edit";

@Builder
export function RegisterBuilder() {
  ImageEditPage()
}

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
          ImageEdit({
            pixelMap: this.pixelMap,
            onCancel: () => {
              this.navPathStack?.pop();
            },
            apiModel: {
              cropMoveType: CropMoveType.All,
              isScale: false
            }
          })
        }
      }
    }
    .onReady((context: NavDestinationContext) => {
      this.navPathStack = context.pathStack;
      this.pixelMap = this.navPathStack.getParamByName('ImageEditPage')[0] as image.PixelMap;
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