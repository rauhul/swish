#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import SwishCore


let core = SwishCore()

signal(SIGINT) { _ in core.handleSIGINT() }

print("Hello, Swish!")
do {
    try core.run()
} catch {
    print("error")
}
print("Goodbye, Swish!")
