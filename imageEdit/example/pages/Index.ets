import { image } from '@kit.ImageKit';
import fs from '@ohos.file.fs';

/**
 * 入口page,用来打开编辑图片界面
 */
@Entry
@Component
struct Index {
  navPathStack: NavPathStack = new NavPathStack();
  @State message: string = 'Hello World';
  @State newPath: string = '';

  build() {
    Navigation(this.navPathStack) {
      RelativeContainer() {
        Image(this.newPath)
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
              this.navPathStack.pushPathByName('ImageEditPage', pixelMap, (popInfo: PopInfo) => {
                let pageResult = popInfo.result as string
                this.newPath = pageResult;
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