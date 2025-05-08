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


import hilog from '@ohos.hilog';

/**
 * 日志封装类
 */
export default class Logger {
  private static readonly domain: number = 0xFF00
  private static readonly prefix: string = '[ImageEdit]'
  private static readonly format: string = '%{public}s, %{public}s';

  static debug(...args: any[]) {
    hilog.debug(this.domain, this.prefix, this.format, args);
  }

  static info(...args: any[]) {
    hilog.info(this.domain, this.prefix, this.format, args);
  }

  static warn(...args: any[]) {
    hilog.warn(this.domain, this.prefix, this.format, args);
  }

  static error(...args: any[]) {
    hilog.error(this.domain, this.prefix, this.format, args);
  }
}