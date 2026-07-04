//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

#if canImport(UIKit)
import UIKit
/// Cross-platform paragraph view type. Resolves to `ParagraphUIView` on UIKit and `ParagraphNSView` on AppKit.
typealias MDParagraphView = ParagraphUIView
#elseif canImport(AppKit)
import AppKit
/// Cross-platform paragraph view type. Resolves to `ParagraphUIView` on UIKit and `ParagraphNSView` on AppKit.
typealias MDParagraphView = ParagraphNSView
#endif
