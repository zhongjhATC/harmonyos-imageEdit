import fs from '@ohos.file.fs';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import StatusUtils from '../utils/StatusUtils';
import { image } from '@kit.ImageKit';

/**
 * 入口page,用来打开编辑图片界面
 */
@Entry
@Component
struct Index {
  navPathStack: NavPathStack = new NavPathStack();
  @State message: string = 'Hello World';
  @State newPixelMap?: PixelMap = undefined;

  build() {
    Navigation(this.navPathStack) {
      RelativeContainer() {
        Image(this.newPixelMap)
          .objectFit(ImageFit.Contain)
        Text(this.message)
          .id('HelloWorld')
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .onClick(async () => {
            try {
              const fd = await this.getResourceFd();
              const imageSourceApi = image.createImageSource(fd);
              const pixelMap = await imageSourceApi.createPixelMap({
                editable: true
              });
              // 准备就绪，替换Main
              this.navPathStack.pushPathByName('ImageEditPage', pixelMap, async (popInfo: PopInfo) => {
                if (!popInfo.result['isCancel']) {
                  let pageResult = popInfo.result as image.PixelMap
                  this.newPixelMap = pageResult;
                }
                window.getLastWindow(getContext() as common.UIAbilityContext, (_err: BusinessError, data) => {
                  // 恢复状态栏
                  StatusUtils.getInstance().initStatusBarAndNavigationBar(data);
                });
              });
            } catch (e) {
              let a = 5;
            }
          })
      }
    }
    .height('100%')
    .width('100%')
  }

  /**
   * 异步获取图片流
   */
  async getResourceFd() {
    const resourceMgr = getContext(this).resourceManager;
    const context = getContext(this);
    let imageBuffer = await resourceMgr.getMediaContent($r('app.media.mosaic'))
    let filePath = context.cacheDir + '/image.jpg';
    let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    fs.writeSync(file.fd, imageBuffer.buffer);
    return file.fd;
  }
}