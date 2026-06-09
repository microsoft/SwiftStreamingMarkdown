//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License. See LICENSE in the project root for license information.
//

// swiftlint:disable type_name

import SwiftUI

extension Color {
  enum Theme {
    enum Accent {
      static let Accent600 = Color("Colors/Copilot/Theme/Accent/600", bundle: .module)
    }

    enum Background {
      enum Page {
        enum Chat {
          static let Flat = Color("Colors/Copilot/Theme/Background/Page/Chat/flat", bundle: .module)
        }
      }
    }

    enum Component {
      enum Button {
        enum Foreground {
          static let Pressed = Color("Colors/Copilot/Theme/Component/Button/Foreground/pressed", bundle: .module)
          static let Rest = Color("Colors/Copilot/Theme/Component/Button/Foreground/rest", bundle: .module)
        }
      }

      enum CodeBlock {
        enum Background {
          static let Background750 = Color("Colors/Copilot/Theme/Component/CodeBlock/Background/750", bundle: .module)
        }

        enum Foreground {
          static let FunctionParameter = Color("Colors/Copilot/Theme/Component/CodeBlock/Foreground/functionparameter", bundle: .module)
          static let Header = Color("Colors/Copilot/Theme/Component/CodeBlock/Foreground/header", bundle: .module)
        }
      }

      enum Table {
        enum Background {
          static let Header = Color("Colors/Copilot/Theme/Component/Table/Background/header", bundle: .module)
        }
      }
    }

    enum Foreground {
      enum Primary {
        static let Primary450 = Color("Colors/Copilot/Theme/Foreground/Primary/450", bundle: .module)
        static let Primary550 = Color("Colors/Copilot/Theme/Foreground/Primary/550", bundle: .module)
        static let Primary650 = Color("Colors/Copilot/Theme/Foreground/Primary/650", bundle: .module)
        static let Primary750 = Color("Colors/Copilot/Theme/Foreground/Primary/750", bundle: .module)
        static let Primary800 = Color("Colors/Copilot/Theme/Foreground/Primary/800", bundle: .module)
      }
    }

    enum Overlay {
      enum Black {
        static let Black5 = Color("Colors/Copilot/Theme/Overlay/Black/5", bundle: .module)
      }
    }

    enum Stroke {
      enum Default {
        static let Default250 = Color("Colors/Copilot/Theme/Stroke/Default/250", bundle: .module)
        static let Default300 = Color("Colors/Copilot/Theme/Stroke/Default/300", bundle: .module)
      }

      enum Muted {
        static let Muted300 = Color("Colors/Copilot/Theme/Stroke/Muted/300", bundle: .module)
      }
    }
  }
}
