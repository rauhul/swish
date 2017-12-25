import SwishCore

print("Hello, Swish!")

let core = Core()

do {
    try core.run()
} catch {
    print("error")
}
