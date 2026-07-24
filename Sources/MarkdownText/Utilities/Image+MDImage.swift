//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

import SwiftUI

extension Image {
  /// Creates a SwiftUI `Image` from a cross-platform `MDImage`.
  init(mdImage: MDImage) {
    #if canImport(UIKit)
    self.init(uiImage: mdImage)
    #elseif canImport(AppKit)
    self.init(nsImage: mdImage)
    #endif
  }
}
