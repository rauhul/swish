print("Hello, world!")

import SwishCore

let core = Core()

do {
    try core.run()
} catch {
    print("error")
}