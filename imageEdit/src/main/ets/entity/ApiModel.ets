import { CropMoveType } from "../common/ImageEditType";

/**
 * 支持调用者在外部修改的参数
 */
export class ApiModel {
  /**
   * 裁剪框移动类型
   */
  cropMoveType: CropMoveType = CropMoveType.All
  /**
   * 是否支持缩放
   */
  isScale: boolean = true
}