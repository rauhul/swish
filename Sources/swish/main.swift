import SwishCore

print("Hello, Swish!")

let core = SwishCore()

do {
    try core.run()
} catch {
    print("error")
}
