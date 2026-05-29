//
//  Copyright © 2025 Microsoft. All rights reserved.
//

// swiftlint:disable type_name

import SwiftUI

extension Color {
  public enum Theme {
    public enum Accent {
      public static let Accent600 = Color("Colors/Copilot/Theme/Accent/600", bundle: .module)
    }

    public enum Background {
      public enum Page {
        public enum Chat {
          public static let Flat = Color("Colors/Copilot/Theme/Background/Page/Chat/flat", bundle: .module)
        }
      }
    }

    public enum Component {
      public enum Button {
        public enum Foreground {
          public static let Pressed = Color("Colors/Copilot/Theme/Component/Button/Foreground/pressed", bundle: .module)
          public static let Rest = Color("Colors/Copilot/Theme/Component/Button/Foreground/rest", bundle: .module)
        }
      }

      public enum CodeBlock {
        public enum Background {
          public static let Background750 = Color("Colors/Copilot/Theme/Component/CodeBlock/Background/750", bundle: .module)
        }

        public enum Foreground {
          public static let FunctionParameter = Color("Colors/Copilot/Theme/Component/CodeBlock/Foreground/functionparameter", bundle: .module)
          public static let Header = Color("Colors/Copilot/Theme/Component/CodeBlock/Foreground/header", bundle: .module)
        }
      }

      public enum Table {
        public enum Background {
          public static let Header = Color("Colors/Copilot/Theme/Component/Table/Background/header", bundle: .module)
        }
      }
    }

    public enum Foreground {
      public enum Primary {
        public static let Primary450 = Color("Colors/Copilot/Theme/Foreground/Primary/450", bundle: .module)
        public static let Primary550 = Color("Colors/Copilot/Theme/Foreground/Primary/550", bundle: .module)
        public static let Primary650 = Color("Colors/Copilot/Theme/Foreground/Primary/650", bundle: .module)
        public static let Primary750 = Color("Colors/Copilot/Theme/Foreground/Primary/750", bundle: .module)
        public static let Primary800 = Color("Colors/Copilot/Theme/Foreground/Primary/800", bundle: .module)
      }
    }

    public enum Overlay {
      public enum Black {
        public static let Black5 = Color("Colors/Copilot/Theme/Overlay/Black/5", bundle: .module)
      }
    }

    public enum Stroke {
      public enum Default {
        public static let Default250 = Color("Colors/Copilot/Theme/Stroke/Default/250", bundle: .module)
        public static let Default300 = Color("Colors/Copilot/Theme/Stroke/Default/300", bundle: .module)
      }

      public enum Muted {
        public static let Muted300 = Color("Colors/Copilot/Theme/Stroke/Muted/300", bundle: .module)
      }
    }
  }
}
